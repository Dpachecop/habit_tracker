import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../domain/entities/date_only.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_entry.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/repositories/entries_repository.dart';
import '../../../domain/repositories/habits_repository.dart';
import '../../../domain/services/streak_calculator.dart';
import 'habit_detail_state.dart';

/// Drives the habit detail screen.
///
/// Reads one habit and *all* of its check-ins, then keeps them live. The home
/// screen deliberately bounds its read to 400 days because it loads every habit
/// on every launch; this one is a single habit the user asked to look at, and
/// the month arrows can walk back to any month — so bounding it here would make
/// the calendar go blank past an invisible edge.
///
/// The streak is recomputed from that full history, which means the number
/// shown here is the true one rather than the home screen's window-truncated
/// version.
class HabitDetailCubit extends Cubit<HabitDetailState> {
  /// [today] is injectable so tests are not at the mercy of the clock.
  HabitDetailCubit({
    required HabitsRepository habitsRepository,
    required EntriesRepository entriesRepository,
    required this.habitId,
    DateOnly Function()? today,
  }) : _habits = habitsRepository,
       _entries = entriesRepository,
       _todayOf = today ?? DateOnly.today,
       super(HabitDetailState.loading((today ?? DateOnly.today)()));

  /// Which habit is on screen.
  final String habitId;

  final HabitsRepository _habits;
  final EntriesRepository _entries;
  final DateOnly Function() _todayOf;

  StreamSubscription<Either<Failure, List<HabitEntry>>>? _entriesSub;

  @override
  Future<void> close() async {
    await _entriesSub?.cancel();
    return super.close();
  }

  /// Loads the habit and subscribes to its entries.
  Future<void> load() async {
    final Either<Failure, Habit> result = await _habits.getHabit(habitId);

    final Habit? habit = result.getRight().toNullable();
    if (habit == null) {
      emit(
        state.copyWith(
          status: HabitDetailStatus.failure,
          failure: result.getLeft().toNullable(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: HabitDetailStatus.ready,
        habit: habit,
        clearFailure: true,
      ),
    );

    // Live rather than a one-shot read: checking a habit off on the home screen
    // and coming back here should show the new day, not a stale grid.
    _entriesSub ??= _entries.watchEntriesForHabit(habitId).listen((
      Either<Failure, List<HabitEntry>> result,
    ) {
      result.match(
        (Failure failure) => emit(state.copyWith(failure: failure)),
        _onEntries,
      );
    });
  }

  /// Moves the calendar one month back.
  ///
  /// No lower bound: the habit's own history is the natural floor, and a month
  /// before it simply shows an empty grid.
  void previousMonth() => emit(
    state.copyWith(
      visibleMonth: DateOnly(
        state.visibleMonth.year,
        state.visibleMonth.month - 1,
        1,
      ),
    ),
  );

  /// Moves the calendar one month forward, stopping at the current month.
  void nextMonth() {
    if (!state.canGoForward) return;
    emit(
      state.copyWith(
        visibleMonth: DateOnly(
          state.visibleMonth.year,
          state.visibleMonth.month + 1,
          1,
        ),
      ),
    );
  }

  /// Stores new entries and recomputes the streak.
  void _onEntries(List<HabitEntry> entries) {
    final Habit? habit = state.habit;
    if (habit == null) return;

    emit(
      state.copyWith(
        entries: entries,
        streak: StreakCalculator.calculate(
          habit: habit,
          entries: entries,
          today: _todayOf(),
        ),
        clearFailure: true,
      ),
    );
  }
}
