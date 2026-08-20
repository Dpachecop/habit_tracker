import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_entry.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/schedule_version.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';
import 'package:habit_tracker/domain/failures/failure.dart';
import 'package:habit_tracker/infrastructure/repositories/entries_repository_impl.dart';

import '../../domain/fixtures.dart';
import '../../support/in_memory_datasources.dart';

void main() {
  late InMemoryEntriesDatasource datasource;
  late EntriesRepositoryImpl repository;

  setUp(() {
    datasource = InMemoryEntriesDatasource();
    repository = EntriesRepositoryImpl(
      datasource,
      clock: () => DateTime.utc(2026, 8, 6, 21),
    );
  });

  /// The failure code of a Left, or null when the result is a Right.
  String? codeOf(Either<Failure, Object?> result) =>
      result.fold((Failure failure) => failure.code, (_) => null);

  /// Seeds the datasource with check-ins for [dates].
  Future<void> seed(String habitId, List<DateOnly> dates) async {
    for (final DateOnly date in dates) {
      await datasource.putEntry(HabitEntry.on(habitId, date));
    }
    datasource.writeCount = 0;
  }

  group('complete — the enforcement point for 3.5', () {
    test('records the check-in when the domain allows it', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));

      final Either<Failure, HabitEntry> result = await repository.complete(
        habit: habit,
        date: d(2026, 8, 6),
        today: d(2026, 8, 6),
      );

      expect(result.isRight(), isTrue);
      expect(datasource.entries, hasLength(1));
      expect(
        datasource.entries.values.single.completedAt,
        DateTime.utc(2026, 8, 6, 21),
      );
    });

    test('refuses an unscheduled day and writes nothing', () async {
      // The button being disabled is a courtesy. This is the rule: a caller
      // that ignores the UI still cannot record a day the user did not earn.
      final Habit habit = weekdayHabit(
        days: <Weekday>{Weekday.monday},
        start: d(2026, 8, 1),
      );

      final Either<Failure, HabitEntry> result = await repository.complete(
        habit: habit,
        date: d(2026, 8, 6),
        today: d(2026, 8, 6),
      );

      expect(codeOf(result), FailureCodes.completionNotScheduled);
      expect(datasource.writeCount, 0);
      expect(datasource.entries, isEmpty);
    });

    test('refuses once the period quota is full, and writes nothing', () async {
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 3));
      await seed(habit.id, datesFrom(d(2026, 8, 3), d(2026, 8, 5)));

      final Either<Failure, HabitEntry> result = await repository.complete(
        habit: habit,
        date: d(2026, 8, 6),
        today: d(2026, 8, 6),
      );

      expect(codeOf(result), FailureCodes.completionQuotaReached);
      expect(datasource.writeCount, 0);
    });

    test('allows a fourth day once the target has been raised', () async {
      // 3.4 end to end: the week is judged by the highest target in force in
      // it, so raising the goal reopens the quota rather than being ignored
      // until Monday.
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 3));
      await seed(habit.id, datesFrom(d(2026, 8, 3), d(2026, 8, 5)));

      final Habit raised = habit.appendScheduleVersion(
        ScheduleVersion(
          schedule: TimesPerPeriod(times: 5, period: SchedulePeriod.week),
          effectiveFrom: d(2026, 8, 6),
        ),
        updatedAt: testClock,
      );

      final Either<Failure, HabitEntry> result = await repository.complete(
        habit: raised,
        date: d(2026, 8, 6),
        today: d(2026, 8, 6),
      );

      expect(result.isRight(), isTrue);
    });

    test('only reads the period it needs, not the whole history', () async {
      // A network round trip on every tap. Last week's entries must not fill
      // this week's quota, and must not be fetched either.
      final Habit habit = timesHabit(times: 3, start: d(2026, 7, 27));
      await seed(habit.id, datesFrom(d(2026, 7, 27), d(2026, 7, 29)));

      final Either<Failure, HabitEntry> result = await repository.complete(
        habit: habit,
        date: d(2026, 8, 6),
        today: d(2026, 8, 6),
      );

      expect(result.isRight(), isTrue);
    });

    test('refuses a future day', () async {
      final Either<Failure, HabitEntry> result = await repository.complete(
        habit: weekdayHabit(start: d(2026, 8, 1)),
        date: d(2026, 8, 7),
        today: d(2026, 8, 6),
      );

      expect(codeOf(result), FailureCodes.completionFutureDate);
    });

    test('refuses a day that is already checked', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      await seed(habit.id, <DateOnly>[d(2026, 8, 6)]);

      final Either<Failure, HabitEntry> result = await repository.complete(
        habit: habit,
        date: d(2026, 8, 6),
        today: d(2026, 8, 6),
      );

      expect(codeOf(result), FailureCodes.completionAlreadyRecorded);
    });

    test('translates a datasource error instead of throwing', () async {
      datasource.failWith = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );

      final Either<Failure, HabitEntry> result = await repository.complete(
        habit: weekdayHabit(start: d(2026, 8, 1)),
        date: d(2026, 8, 6),
        today: d(2026, 8, 6),
      );

      expect(codeOf(result), FailureCodes.network);
    });
  });

  group('uncomplete', () {
    test('removes a past check-in — correcting a mistap is allowed', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      await seed(habit.id, <DateOnly>[d(2026, 8, 2)]);

      final Either<Failure, Unit> result = await repository.uncomplete(
        habit: habit,
        date: d(2026, 8, 2),
      );

      expect(result.isRight(), isTrue);
      expect(datasource.entries, isEmpty);
    });

    test('refuses on an archived habit, whose history is frozen', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1), isArchived: true);
      await seed(habit.id, <DateOnly>[d(2026, 8, 2)]);

      final Either<Failure, Unit> result = await repository.uncomplete(
        habit: habit,
        date: d(2026, 8, 2),
      );

      expect(codeOf(result), FailureCodes.completionArchived);
      expect(datasource.entries, hasLength(1));
    });
  });

  group('reads', () {
    test(
      'a stream error arrives as a Left instead of killing the stream',
      () async {
        // The home screen subscribes for the life of the app; one transient
        // failure must not leave it permanently silent.
        datasource.failWith = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );

        final Either<Failure, List<HabitEntry>> first =
            await repository.watchEntriesOn(d(2026, 8, 6)).first;

        expect(codeOf(first), FailureCodes.permission);
      },
    );

    test('entriesForHabit returns what was stored', () async {
      await seed('habit-1', datesFrom(d(2026, 8, 3), d(2026, 8, 5)));

      final Either<Failure, List<HabitEntry>> result = await repository
          .entriesForHabit('habit-1');

      expect(result.getRight().toNullable(), hasLength(3));
    });
  });
}
