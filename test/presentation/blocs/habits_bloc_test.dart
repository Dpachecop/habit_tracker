import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_entry.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';
import 'package:habit_tracker/domain/failures/failure.dart';
import 'package:habit_tracker/domain/services/habit_completion_policy.dart';
import 'package:habit_tracker/infrastructure/repositories/entries_repository_impl.dart';
import 'package:habit_tracker/infrastructure/repositories/habits_repository_impl.dart';
import 'package:habit_tracker/presentation/blocs/habits/habits_bloc.dart';
import 'package:habit_tracker/presentation/blocs/habits/habits_event.dart';
import 'package:habit_tracker/presentation/blocs/habits/habits_state.dart';

import '../../domain/fixtures.dart';
import '../../support/in_memory_datasources.dart';

void main() {
  /// Fixed "today": a Thursday, so weekday cases are unambiguous.
  final DateOnly today = d(2026, 8, 6);

  late InMemoryHabitsDatasource habitsStore;
  late InMemoryEntriesDatasource entriesStore;

  setUp(() {
    habitsStore = InMemoryHabitsDatasource();
    entriesStore = InMemoryEntriesDatasource();
  });

  tearDown(() async {
    await habitsStore.dispose();
    await entriesStore.dispose();
  });

  /// The bloc under test, over the real repositories.
  HabitsBloc buildBloc() => HabitsBloc(
    habitsRepository: HabitsRepositoryImpl(habitsStore),
    entriesRepository: EntriesRepositoryImpl(entriesStore),
    today: () => today,
  );

  /// Seeds storage and pushes it into both streams.
  ///
  /// The push is explicit because the fakes are broadcast controllers with no
  /// replay: a subscriber has to be listening before anything is emitted, which
  /// is exactly the ordering a real snapshot stream has too.
  Future<void> seed({
    List<Habit> habits = const <Habit>[],
    List<HabitEntry> entries = const <HabitEntry>[],
  }) async {
    for (final Habit habit in habits) {
      habitsStore.habits[habit.id] = habit;
    }
    for (final HabitEntry entry in entries) {
      entriesStore.entries['${entry.habitId}_${entry.date.toIso8601()}'] =
          entry;
    }
    await Future<void>.delayed(Duration.zero);
    habitsStore.emit();
    entriesStore.emit();
  }

  group('loading', () {
    blocTest<HabitsBloc, HabitsState>(
      'goes to loading and then to ready with the list',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        bloc.add(const HabitsSubscriptionRequested());
        await seed(habits: <Habit>[weekdayHabit(start: d(2026, 8, 1))]);
      },
      skip: 1,
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        expect(bloc.state.status, HabitsStatus.ready);
        expect(bloc.state.summaries, hasLength(1));
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'an empty list is ready, not still loading',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        bloc.add(const HabitsSubscriptionRequested());
        await seed();
      },
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        // The difference is what lets the empty state appear instead of a
        // spinner that never stops.
        expect(bloc.state.status, HabitsStatus.ready);
        expect(bloc.state.isEmpty, isTrue);
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'waits for both streams before computing a streak',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        bloc.add(const HabitsSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        // Habits only. With no entries yet every streak would read zero, which
        // is a wrong answer rather than an incomplete one.
        habitsStore.habits['habit-1'] = weekdayHabit(start: d(2026, 8, 1));
        habitsStore.emit();
      },
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        expect(bloc.state.status, HabitsStatus.loading);
        expect(bloc.state.summaries, isEmpty);
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'surfaces a load failure without blanking what is on screen',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        bloc.add(const HabitsSubscriptionRequested());
        await seed(habits: <Habit>[weekdayHabit(start: d(2026, 8, 1))]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        habitsStore.failWith = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
        bloc.add(const HabitsListUpdated(failure: NetworkFailure()));
      },
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        expect(bloc.state.loadFailure, isA<NetworkFailure>());
        // Still showing the last thing storage said. Wiping the list over a
        // transient error would be a worse lie than showing it with a warning.
        expect(bloc.state.summaries, hasLength(1));
        expect(bloc.state.status, HabitsStatus.ready);
      },
    );
  });

  group('the derived figures', () {
    blocTest<HabitsBloc, HabitsState>(
      'computes the streak from history, not just today',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        bloc.add(const HabitsSubscriptionRequested());
        await seed(
          habits: <Habit>[weekdayHabit(start: d(2026, 8, 1))],
          entries: entriesOn(datesFrom(d(2026, 8, 4), d(2026, 8, 6))),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        expect(bloc.state.summaries.single.streak.current, 3);
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'marks a habit not due today as not actionable',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        bloc.add(const HabitsSubscriptionRequested());
        await seed(
          habits: <Habit>[
            weekdayHabit(days: <Weekday>{Weekday.monday}, start: d(2026, 8, 1)),
          ],
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        final HabitSummary summary = bloc.state.summaries.single;
        expect(summary.isActionable, isFalse);
        expect(summary.availability.reason, CompletionBlockReason.notScheduled);
        // And it must not be counted as "left to complete today".
        expect(bloc.state.pendingToday, 0);
        expect(bloc.state.anythingDueToday, isFalse);
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'reports the quota counters for a times-per-period habit',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        bloc.add(const HabitsSubscriptionRequested());
        await seed(
          habits: <Habit>[timesHabit(times: 3, start: d(2026, 8, 3))],
          entries: entriesOn(<DateOnly>[d(2026, 8, 3)]),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        final HabitSummary summary = bloc.state.summaries.single;
        expect(summary.availability.completedInPeriod, 1);
        expect(summary.availability.periodTarget, 3);
        expect(summary.availability.period, isNotNull);
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'counts only what is still pending today',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        bloc.add(const HabitsSubscriptionRequested());
        await seed(
          habits: <Habit>[
            weekdayHabit(id: 'a', start: d(2026, 8, 1)),
            weekdayHabit(id: 'b', start: d(2026, 8, 1)),
            weekdayHabit(id: 'c', start: d(2026, 8, 1)),
          ],
          entries: entriesOn(<DateOnly>[d(2026, 8, 6)], habitId: 'a'),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        expect(bloc.state.pendingToday, 2);
        expect(bloc.state.completedToday, 1);
      },
    );
  });

  group('the optimistic toggle', () {
    blocTest<HabitsBloc, HabitsState>(
      'flips the card before the write lands, and the streak with it',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        final Habit habit = weekdayHabit(start: d(2026, 8, 1));
        bloc.add(const HabitsSubscriptionRequested());
        await seed(
          habits: <Habit>[habit],
          entries: entriesOn(datesFrom(d(2026, 8, 4), d(2026, 8, 5))),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(HabitCheckToggled(habit));
      },
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        final HabitSummary summary = bloc.state.summaries.single;
        expect(summary.isCompletedToday, isTrue);
        // Two days before, plus today.
        expect(summary.streak.current, 3);
        expect(entriesStore.entries, hasLength(3));
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'unchecks a day that was already done',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        final Habit habit = weekdayHabit(start: d(2026, 8, 1));
        bloc.add(const HabitsSubscriptionRequested());
        await seed(
          habits: <Habit>[habit],
          entries: entriesOn(<DateOnly>[d(2026, 8, 6)]),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(HabitCheckToggled(habit));
      },
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        expect(bloc.state.summaries.single.isCompletedToday, isFalse);
        expect(entriesStore.entries, isEmpty);
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'reverts and reports the reason when the domain refuses',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        // Quota already full: the repository will refuse, and the card must go
        // back to how it was rather than keep a check the database never took.
        final Habit habit = timesHabit(times: 3, start: d(2026, 8, 3));
        bloc.add(const HabitsSubscriptionRequested());
        await seed(
          habits: <Habit>[habit],
          entries: entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 5))),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(HabitCheckToggled(habit));
      },
      wait: const Duration(milliseconds: 50),
      verify: (HabitsBloc bloc) {
        expect(bloc.state.summaries.single.isCompletedToday, isFalse);
        expect(
          bloc.state.actionFailure,
          const ValidationFailure(code: FailureCodes.completionQuotaReached),
        );
        expect(bloc.state.actionSeq, greaterThan(0));
        // Nothing was written.
        expect(entriesStore.entries, hasLength(3));
      },
    );

    blocTest<HabitsBloc, HabitsState>(
      'bumps the sequence on every refusal so a repeat still reaches the UI',
      build: buildBloc,
      act: (HabitsBloc bloc) async {
        final Habit habit = timesHabit(times: 1, start: d(2026, 8, 3));
        bloc.add(const HabitsSubscriptionRequested());
        await seed(
          habits: <Habit>[habit],
          entries: entriesOn(<DateOnly>[d(2026, 8, 3)]),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(HabitCheckToggled(habit));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(HabitCheckToggled(habit));
      },
      wait: const Duration(milliseconds: 60),
      verify: (HabitsBloc bloc) {
        // Without the counter the second identical refusal would produce an
        // equal state and the user would tap and see nothing.
        expect(bloc.state.actionSeq, 2);
      },
    );
  });

  test('subscribing twice does not open a second pair of streams', () async {
    final HabitsBloc bloc = buildBloc();
    bloc
      ..add(const HabitsSubscriptionRequested())
      ..add(const HabitsSubscriptionRequested());
    await Future<void>.delayed(Duration.zero);
    await seed(habits: <Habit>[weekdayHabit(start: d(2026, 8, 1))]);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // One habit seeded, one card — a duplicated subscription would double it.
    expect(bloc.state.summaries, hasLength(1));
    await bloc.close();
  });
}
