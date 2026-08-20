import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../domain/entities/date_only.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_entry.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/repositories/entries_repository.dart';
import '../../../domain/repositories/habits_repository.dart';
import '../../../domain/services/habit_completion_policy.dart';
import '../../../domain/services/habit_day_status.dart';
import '../../../domain/services/streak_calculator.dart';
import 'habits_event.dart';
import 'habits_state.dart';

/// Drives the home screen: the habit list, each streak, and the daily check.
///
/// Two subscriptions, not one. Habits and entries live in separate collections
/// and either can change without the other, so the bloc holds the latest of each
/// and recomputes the cards from both. Combining them in a stream operator would
/// need a dependency this project does not have, for no gain.
///
/// **Why entries at all:** a card shows a streak, and a streak is derived from
/// history — today's entries are nowhere near enough. One windowed subscription
/// over every habit's entries beats one per habit.
class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  /// [today] exists so tests can fix the date; production reads the clock.
  HabitsBloc({
    required HabitsRepository habitsRepository,
    required EntriesRepository entriesRepository,
    DateOnly Function()? today,
  }) : _habits = habitsRepository,
       _entries = entriesRepository,
       _todayOf = today ?? DateOnly.today,
       super(HabitsState.initial(today?.call() ?? DateOnly.today())) {
    on<HabitsSubscriptionRequested>(_onSubscriptionRequested);
    on<HabitsListUpdated>(_onListUpdated);
    on<HabitsEntriesUpdated>(_onEntriesUpdated);
    on<HabitCheckToggled>(_onCheckToggled);
  }

  /// How far back the entry window reaches.
  ///
  /// Bounded on purpose — an unbounded read grows for the life of the account.
  /// 400 days covers a year of heatmap plus slack.
  ///
  /// **The trade-off:** a current streak longer than this reads as truncated at
  /// the window. Rare enough to accept, and the alternative is downloading a
  /// user's entire history to draw one number. It also means `Streak.longest`
  /// out of this bloc is only the longest *within the window* — the reports
  /// phase needs its own, wider read and must not reuse this one.
  static const int historyWindowDays = 400;

  /// How many days of statuses each card is handed for its heatmap.
  ///
  /// Comfortably more than a phone can show at four rows — the widest sensible
  /// layout is around 60 columns — so the card can take the tail that fits
  /// instead of the bloc guessing at screen width. Well inside
  /// [historyWindowDays], so every status is backed by real data rather than by
  /// the absence of it.
  static const int heatmapWindowDays = 240;

  final HabitsRepository _habits;
  final EntriesRepository _entries;
  final DateOnly Function() _todayOf;

  StreamSubscription<Either<Failure, List<Habit>>>? _habitsSub;
  StreamSubscription<Either<Failure, List<HabitEntry>>>? _entriesSub;

  /// Latest habit list, or null before the first emission.
  List<Habit>? _latestHabits;

  /// Latest entry window, or null before the first emission.
  List<HabitEntry>? _latestEntries;

  /// Optimistic overrides: habit id → whether today should *look* completed.
  ///
  /// The tap has to feel instant, so the card flips before the write lands.
  /// An entry is left in this map only while its write is in flight; when the
  /// stream delivers the stored truth the override is already gone, so the two
  /// can never fight.
  final Map<String, bool> _optimisticToday = <String, bool>{};

  @override
  Future<void> close() async {
    await _habitsSub?.cancel();
    await _entriesSub?.cancel();
    return super.close();
  }

  /// Opens both subscriptions and funnels them into internal events.
  Future<void> _onSubscriptionRequested(
    HabitsSubscriptionRequested event,
    Emitter<HabitsState> emit,
  ) async {
    if (_habitsSub != null) return;

    emit(state.copyWith(status: HabitsStatus.loading, clearLoadFailure: true));

    final DateOnly today = _todayOf();
    final DateOnly from = today.addDays(-historyWindowDays);

    _habitsSub = _habits.watchHabits().listen(
      (Either<Failure, List<Habit>> result) => add(
        result.fold(
          (Failure failure) => HabitsListUpdated(failure: failure),
          (List<Habit> habits) => HabitsListUpdated(habits: habits),
        ),
      ),
    );

    _entriesSub = _entries
        .watchEntries(from: from, to: today)
        .listen(
          (Either<Failure, List<HabitEntry>> result) => add(
            result.fold(
              (Failure failure) => HabitsEntriesUpdated(failure: failure),
              (List<HabitEntry> entries) =>
                  HabitsEntriesUpdated(entries: entries),
            ),
          ),
        );
  }

  /// Stores a new habit list and recomputes.
  void _onListUpdated(HabitsListUpdated event, Emitter<HabitsState> emit) {
    final Failure? failure = event.failure;
    if (failure != null) {
      emit(_withLoadFailure(failure));
      return;
    }
    _latestHabits = event.habits;
    emit(_recomputed());
  }

  /// Stores a new entry window and recomputes.
  void _onEntriesUpdated(
    HabitsEntriesUpdated event,
    Emitter<HabitsState> emit,
  ) {
    final Failure? failure = event.failure;
    if (failure != null) {
      emit(_withLoadFailure(failure));
      return;
    }
    _latestEntries = event.entries;
    emit(_recomputed());
  }

  /// Writes or removes today's entry, flipping the card first.
  ///
  /// The optimistic flip is reverted on refusal, and the refusal travels in the
  /// state so the screen can say *why* — the domain returns a `completion.*`
  /// code and presentation turns it into a sentence.
  Future<void> _onCheckToggled(
    HabitCheckToggled event,
    Emitter<HabitsState> emit,
  ) async {
    final DateOnly today = _todayOf();
    final Habit habit = event.habit;
    final bool wasCompleted = _isCompletedToday(habit.id, today);

    _optimisticToday[habit.id] = !wasCompleted;
    emit(_recomputed().copyWith(clearActionFailure: true));

    final Either<Failure, Object?> result =
        wasCompleted
            ? await _entries.uncomplete(habit: habit, date: today)
            : await _entries.complete(habit: habit, date: today, today: today);

    _optimisticToday.remove(habit.id);

    result.match(
      (Failure failure) => emit(
        _recomputed().copyWith(
          actionFailure: failure,
          actionSeq: state.actionSeq + 1,
        ),
      ),
      // On success the override is simply dropped: the stream is about to
      // deliver the same answer from storage, and re-emitting here would only
      // race it.
      (_) => emit(_recomputed()),
    );
  }

  /// Rebuilds every card from the latest habits, the latest entries and any
  /// override in flight.
  HabitsState _recomputed() {
    final List<Habit>? habits = _latestHabits;
    final List<HabitEntry>? entries = _latestEntries;
    // Both streams have to have spoken before a streak means anything: with
    // habits but no entries every streak would read zero, which is a wrong
    // answer rather than an incomplete one.
    if (habits == null || entries == null) return state;

    final DateOnly today = _todayOf();
    final List<HabitSummary> summaries = <HabitSummary>[];

    for (final Habit habit in habits) {
      final List<HabitEntry> own = _entriesFor(habit.id, entries, today);
      final bool completedToday = own.any(
        (HabitEntry entry) => entry.date == today,
      );

      summaries.add(
        HabitSummary(
          habit: habit,
          streak: StreakCalculator.calculate(
            habit: habit,
            entries: own,
            today: today,
          ),
          availability: HabitCompletionPolicy.check(
            habit: habit,
            entries: own,
            date: today,
            today: today,
          ),
          isCompletedToday: completedToday,
          recentDays: HabitDayStatuses.lastDays(
            habit: habit,
            entries: own,
            today: today,
            length: heatmapWindowDays,
          ),
        ),
      );
    }

    return state.copyWith(
      status: HabitsStatus.ready,
      summaries: summaries,
      today: today,
      clearLoadFailure: true,
    );
  }

  /// One habit's entries with the optimistic override applied.
  List<HabitEntry> _entriesFor(
    String habitId,
    List<HabitEntry> all,
    DateOnly today,
  ) {
    final List<HabitEntry> own =
        all.where((HabitEntry entry) => entry.habitId == habitId).toList();

    final bool? override = _optimisticToday[habitId];
    if (override == null) return own;

    own.removeWhere((HabitEntry entry) => entry.date == today);
    if (override) {
      own.add(HabitEntry.on(habitId, today));
    }
    return own;
  }

  /// Whether today currently counts as completed, overrides included.
  bool _isCompletedToday(String habitId, DateOnly today) {
    final List<HabitEntry> entries = _latestEntries ?? const <HabitEntry>[];
    return _entriesFor(
      habitId,
      entries,
      today,
    ).any((HabitEntry entry) => entry.date == today);
  }

  /// A state carrying a load failure, keeping any list already on screen.
  ///
  /// A transient error must not blank the list: the cards on screen are still
  /// the last thing storage said, and wiping them would be a worse lie than
  /// showing them beside a warning.
  HabitsState _withLoadFailure(Failure failure) => state.copyWith(
    status: state.summaries.isEmpty ? HabitsStatus.failure : state.status,
    loadFailure: failure,
  );
}
