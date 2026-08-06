import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/schedule_version.dart';
import 'package:habit_tracker/domain/failures/failure.dart';
import 'package:habit_tracker/infrastructure/errors/failure_mapper.dart';
import 'package:habit_tracker/infrastructure/repositories/habits_repository_impl.dart';

import '../../domain/fixtures.dart';
import '../../support/in_memory_datasources.dart';

void main() {
  late InMemoryHabitsDatasource datasource;
  late HabitsRepositoryImpl repository;

  setUp(() {
    datasource = InMemoryHabitsDatasource();
    repository = HabitsRepositoryImpl(datasource);
  });

  tearDown(() => datasource.dispose());

  /// The failure code of a Left, or null when the result is a Right.
  String? codeOf(Either<Failure, Object?> result) =>
      result.fold((Failure failure) => failure.code, (_) => null);

  group('reads', () {
    test('returns a stored habit', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 3));
      await repository.saveHabit(habit);

      final Either<Failure, Habit> result = await repository.getHabit(habit.id);
      expect(result.getRight().toNullable(), habit);
    });

    test('a missing habit is NotFoundFailure, not an exception', () async {
      expect(codeOf(await repository.getHabit('nope')), FailureCodes.notFound);
    });

    test('being signed out surfaces as PermissionFailure', () async {
      datasource.failWith = const NotAuthenticatedException();
      expect(
        codeOf(await repository.getHabit('anything')),
        FailureCodes.permission,
      );
    });

    test('a Firestore error is translated, never rethrown', () async {
      datasource.failWith = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      expect(codeOf(await repository.getHabit('x')), FailureCodes.network);
    });

    test('a stream error arrives as a Left', () async {
      datasource.failWith = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );

      expect(
        codeOf(await repository.watchHabits().first),
        FailureCodes.permission,
      );
    });
  });

  group('changeSchedule — 3.4', () {
    test('appends a version instead of overwriting the previous one', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 3));
      await repository.saveHabit(habit);

      final Either<Failure, Unit> result = await repository.changeSchedule(
        habit.id,
        ScheduleVersion(
          schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
          effectiveFrom: d(2026, 8, 10),
        ),
      );

      expect(result.isRight(), isTrue);
      final Habit stored = datasource.habits[habit.id]!;
      expect(stored.scheduleHistory, hasLength(2));
      // The point of the whole mechanism: the past keeps its own rules.
      expect(stored.scheduleOn(d(2026, 8, 9)), isA<SpecificWeekdays>());
      expect(stored.currentSchedule, isA<TimesPerPeriod>());
    });

    test(
      'refuses to back-date a change, leaving the habit untouched',
      () async {
        // The rule lives on `Habit`; the repository just must not swallow it.
        final Habit habit = weekdayHabit(start: d(2026, 8, 3));
        await repository.saveHabit(habit);

        final Either<Failure, Unit> result = await repository.changeSchedule(
          habit.id,
          ScheduleVersion(
            schedule: SpecificWeekdays.daily(),
            effectiveFrom: d(2026, 8, 1),
          ),
        );

        expect(result.isLeft(), isTrue);
        expect(datasource.habits[habit.id]!.scheduleHistory, hasLength(1));
      },
    );

    test('a habit that is not there is NotFoundFailure', () async {
      final Either<Failure, Unit> result = await repository.changeSchedule(
        'nope',
        ScheduleVersion(
          schedule: SpecificWeekdays.daily(),
          effectiveFrom: d(2026, 8, 10),
        ),
      );

      expect(codeOf(result), FailureCodes.notFound);
    });
  });

  group('archiving', () {
    test('archives instead of deleting, so the history survives', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 3));
      await repository.saveHabit(habit);

      await repository.archiveHabit(habit.id);

      expect(datasource.habits[habit.id]!.isArchived, isTrue);
      expect(datasource.habits, hasLength(1));
    });

    test('restores an archived habit', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 3));
      await repository.saveHabit(habit);
      await repository.archiveHabit(habit.id);

      await repository.restoreHabit(habit.id);

      expect(datasource.habits[habit.id]!.isArchived, isFalse);
    });
  });
}
