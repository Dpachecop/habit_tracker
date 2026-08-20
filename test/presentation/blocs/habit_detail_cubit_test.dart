import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/failures/failure.dart';
import 'package:habit_tracker/infrastructure/repositories/entries_repository_impl.dart';
import 'package:habit_tracker/infrastructure/repositories/habits_repository_impl.dart';
import 'package:habit_tracker/presentation/blocs/habit_detail/habit_detail_cubit.dart';
import 'package:habit_tracker/presentation/blocs/habit_detail/habit_detail_state.dart';

import '../../domain/fixtures.dart';
import '../../support/in_memory_datasources.dart';

void main() {
  /// A Thursday.
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

  /// A cubit over [habit], with the habit already in storage.
  HabitDetailCubit cubitFor(Habit habit) {
    habitsStore.habits[habit.id] = habit;
    return HabitDetailCubit(
      habitsRepository: HabitsRepositoryImpl(habitsStore),
      entriesRepository: EntriesRepositoryImpl(entriesStore),
      habitId: habit.id,
      today: () => today,
    );
  }

  /// Seeds check-ins and pushes them into the stream.
  Future<void> seedEntries(String habitId, List<DateOnly> dates) async {
    for (final DateOnly date in dates) {
      entriesStore.entries['${habitId}_${date.toIso8601()}'] =
          entriesOn(<DateOnly>[date], habitId: habitId).single;
    }
    await Future<void>.delayed(Duration.zero);
    entriesStore.emit();
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  group('loading', () {
    test('reads the habit and then its entries', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final HabitDetailCubit cubit = cubitFor(habit);

      await cubit.load();
      await seedEntries(habit.id, datesFrom(d(2026, 8, 4), d(2026, 8, 5)));

      expect(cubit.state.status, HabitDetailStatus.ready);
      expect(cubit.state.habit, habit);
      expect(cubit.state.entries, hasLength(2));
      await cubit.close();
    });

    test('a missing habit is a failure, not a blank screen', () async {
      final HabitDetailCubit cubit = HabitDetailCubit(
        habitsRepository: HabitsRepositoryImpl(habitsStore),
        entriesRepository: EntriesRepositoryImpl(entriesStore),
        habitId: 'nope',
        today: () => today,
      );

      await cubit.load();

      expect(cubit.state.status, HabitDetailStatus.failure);
      expect(cubit.state.failure, isA<NotFoundFailure>());
      await cubit.close();
    });

    test('starts on the current month', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final HabitDetailCubit cubit = cubitFor(habit);

      await cubit.load();

      expect(cubit.state.visibleMonth.year, today.year);
      expect(cubit.state.visibleMonth.month, today.month);
      await cubit.close();
    });
  });

  group('the streak shown here', () {
    test('is computed over the whole history, not a window', () async {
      // The home screen caps its read at 400 days, so its `longest` is only the
      // best run inside that window. This screen reads everything, which is why
      // it can show the real one.
      final Habit habit = weekdayHabit(start: d(2024, 1, 1));
      final HabitDetailCubit cubit = cubitFor(habit);

      await cubit.load();
      await seedEntries(habit.id, <DateOnly>[
        // A 20-day run well over a year ago, beyond the home screen's window.
        ...datesFrom(d(2024, 3, 1), d(2024, 3, 20)),
        // And a shorter recent one.
        ...datesFrom(d(2026, 8, 4), d(2026, 8, 6)),
      ]);

      expect(cubit.state.streak.current, 3);
      expect(cubit.state.streak.longest, 20);
      await cubit.close();
    });

    test('updates when an entry arrives', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final HabitDetailCubit cubit = cubitFor(habit);

      await cubit.load();
      await seedEntries(habit.id, <DateOnly>[d(2026, 8, 5)]);
      expect(cubit.state.streak.current, 1);

      // Checking a habit off elsewhere has to reach this screen too.
      await seedEntries(habit.id, <DateOnly>[d(2026, 8, 6)]);

      expect(cubit.state.streak.current, 2);
      await cubit.close();
    });
  });

  group('paging months', () {
    test('goes back without a floor', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final HabitDetailCubit cubit = cubitFor(habit);
      await cubit.load();

      cubit
        ..previousMonth()
        ..previousMonth();

      expect(cubit.state.visibleMonth.month, 6);
      expect(cubit.state.visibleMonth.year, 2026);
      await cubit.close();
    });

    test('crosses the turn of the year backwards', () async {
      final Habit habit = weekdayHabit(start: d(2025, 1, 1));
      final HabitDetailCubit cubit = cubitFor(habit);
      await cubit.load();

      for (int i = 0; i < 8; i++) {
        cubit.previousMonth();
      }

      expect(cubit.state.visibleMonth.year, 2025);
      expect(cubit.state.visibleMonth.month, 12);
      await cubit.close();
    });

    test('will not page into the future', () async {
      // Nothing to see there, and letting someone tap into 2031 one month at a
      // time is not navigation.
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final HabitDetailCubit cubit = cubitFor(habit);
      await cubit.load();

      expect(cubit.state.canGoForward, isFalse);
      cubit.nextMonth();

      expect(cubit.state.visibleMonth.month, today.month);
      await cubit.close();
    });

    test('can come forward again after going back', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final HabitDetailCubit cubit = cubitFor(habit);
      await cubit.load();

      cubit.previousMonth();
      expect(cubit.state.canGoForward, isTrue);

      cubit.nextMonth();

      expect(cubit.state.visibleMonth.month, today.month);
      expect(cubit.state.canGoForward, isFalse);
      await cubit.close();
    });
  });
}
