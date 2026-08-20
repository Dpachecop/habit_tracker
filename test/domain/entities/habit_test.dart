import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/date_period.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/schedule_version.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';

import '../fixtures.dart';

void main() {
  group('Habit validation', () {
    test('refuses an empty schedule history', () {
      expect(
        () =>
            versionedHabit(versions: <ScheduleVersion>[], start: d(2026, 8, 3)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refuses a history that is not strictly ascending', () {
      // Out-of-order versions would make scheduleOn answer with the wrong
      // rules, which is a corrupted streak rather than a visible error.
      expect(
        () => versionedHabit(
          start: d(2026, 8, 3),
          versions: <ScheduleVersion>[
            ScheduleVersion(
              schedule: SpecificWeekdays.daily(),
              effectiveFrom: d(2026, 8, 10),
            ),
            ScheduleVersion(
              schedule: SpecificWeekdays.daily(),
              effectiveFrom: d(2026, 8, 3),
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refuses a blank name', () {
      expect(
        () => weekdayHabit().copyWith(name: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('keeps its schedule history unmodifiable', () {
      final Habit habit = weekdayHabit();
      expect(
        () => habit.scheduleHistory.add(
          ScheduleVersion(
            schedule: SpecificWeekdays.daily(),
            effectiveFrom: d(2026, 9, 1),
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('scheduleOn', () {
    final Habit habit = versionedHabit(
      start: d(2026, 8, 3),
      versions: <ScheduleVersion>[
        ScheduleVersion(
          schedule: SpecificWeekdays(<Weekday>{Weekday.monday}),
          effectiveFrom: d(2026, 8, 3),
        ),
        ScheduleVersion(
          schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
          effectiveFrom: d(2026, 8, 10),
        ),
      ],
    );

    test('returns the version in force, inclusive of its first day', () {
      expect(habit.scheduleOn(d(2026, 8, 9)), isA<SpecificWeekdays>());
      expect(habit.scheduleOn(d(2026, 8, 10)), isA<TimesPerPeriod>());
      expect(habit.scheduleOn(d(2026, 8, 11)), isA<TimesPerPeriod>());
    });

    test('falls back to the oldest version for earlier dates', () {
      // Only reachable if the range start was moved back after the fact.
      // Answering with the oldest known rules beats throwing mid-calculation.
      expect(habit.scheduleOn(d(2026, 1, 1)), isA<SpecificWeekdays>());
    });

    test('currentSchedule is the newest version', () {
      expect(habit.currentSchedule, isA<TimesPerPeriod>());
    });
  });

  group('targetForPeriod — §3.4', () {
    /// The habit of the §3.4 table: 3 a week, raised to 5 on Wednesday.
    Habit raisedMidWeek() => versionedHabit(
      start: d(2026, 8, 3),
      versions: <ScheduleVersion>[
        ScheduleVersion(
          schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
          effectiveFrom: d(2026, 8, 3),
        ),
        ScheduleVersion(
          schedule: TimesPerPeriod(times: 5, period: SchedulePeriod.week),
          effectiveFrom: d(2026, 8, 5),
        ),
      ],
    );

    test('takes the highest target in force during the period', () {
      final DatePeriod week = DatePeriod.containing(
        d(2026, 8, 6),
        SchedulePeriod.week,
      );
      expect(raisedMidWeek().targetForPeriod(week), 5);
    });

    test('leaves a lowered target at the old value for the open period', () {
      // The important direction: dropping 5 to 3 mid-week must not make the
      // five entries already written retroactively illegal (§3.5).
      final Habit lowered = versionedHabit(
        start: d(2026, 8, 3),
        versions: <ScheduleVersion>[
          ScheduleVersion(
            schedule: TimesPerPeriod(times: 5, period: SchedulePeriod.week),
            effectiveFrom: d(2026, 8, 3),
          ),
          ScheduleVersion(
            schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
            effectiveFrom: d(2026, 8, 5),
          ),
        ],
      );
      final DatePeriod week = DatePeriod.containing(
        d(2026, 8, 6),
        SchedulePeriod.week,
      );
      expect(lowered.targetForPeriod(week), 5);
      // The next week is under the new version alone, so it does drop to 3.
      expect(
        lowered.targetForPeriod(
          DatePeriod.containing(d(2026, 8, 12), SchedulePeriod.week),
        ),
        3,
      );
    });

    test('later periods are judged by the newer target alone', () {
      final DatePeriod weekAfter = DatePeriod.containing(
        d(2026, 8, 12),
        SchedulePeriod.week,
      );
      expect(raisedMidWeek().targetForPeriod(weekAfter), 5);
    });

    test('is zero when no matching period target was ever in force', () {
      final Habit weekly = timesHabit(period: SchedulePeriod.week);
      expect(
        weekly.targetForPeriod(
          DatePeriod.containing(d(2026, 8, 6), SchedulePeriod.month),
        ),
        0,
      );
      expect(
        weekdayHabit().targetForPeriod(
          DatePeriod.containing(d(2026, 8, 6), SchedulePeriod.week),
        ),
        0,
      );
    });
  });

  group('appendScheduleVersion', () {
    test('adds a version instead of overwriting the previous one', () {
      final Habit habit = weekdayHabit(start: d(2026, 8, 3));
      final Habit changed = habit.appendScheduleVersion(
        ScheduleVersion(
          schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
          effectiveFrom: d(2026, 8, 10),
        ),
        updatedAt: testClock,
      );

      expect(changed.scheduleHistory.length, 2);
      // The whole point of §3.4: yesterday is still judged by yesterday's rules.
      expect(changed.scheduleOn(d(2026, 8, 9)), isA<SpecificWeekdays>());
      expect(changed.currentSchedule, isA<TimesPerPeriod>());
    });

    test('replaces the newest version when edited on the same day', () {
      final Habit habit = weekdayHabit(start: d(2026, 8, 3));
      final Habit changed = habit.appendScheduleVersion(
        ScheduleVersion(
          schedule: TimesPerPeriod(times: 4, period: SchedulePeriod.week),
          effectiveFrom: d(2026, 8, 3),
        ),
        updatedAt: testClock,
      );

      expect(changed.scheduleHistory.length, 1);
      expect(changed.currentSchedule, isA<TimesPerPeriod>());
    });

    test('refuses to back-date a change', () {
      // Back-dating would re-judge days that have already been scored.
      final Habit habit = weekdayHabit(start: d(2026, 8, 3));
      expect(
        () => habit.appendScheduleVersion(
          ScheduleVersion(
            schedule: SpecificWeekdays.daily(),
            effectiveFrom: d(2026, 8, 1),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('isActiveOn', () {
    test('is false outside the range and for archived habits', () {
      final Habit bounded = weekdayHabit(
        start: d(2026, 8, 3),
        end: d(2026, 8, 9),
      );
      expect(bounded.isActiveOn(d(2026, 8, 6)), isTrue);
      expect(bounded.isActiveOn(d(2026, 8, 2)), isFalse);
      expect(bounded.isActiveOn(d(2026, 8, 10)), isFalse);
      expect(
        bounded.copyWith(isArchived: true).isActiveOn(d(2026, 8, 6)),
        isFalse,
      );
    });
  });

  group('copyWith', () {
    test('clears the time window only when asked explicitly', () {
      final Habit allDay = weekdayHabit();
      expect(allDay.timeWindow, isNull);
      // Passing null cannot be told from omitting it, hence the flag.
      expect(allDay.copyWith(clearTimeWindow: true).timeWindow, isNull);
    });

    test('keeps id and createdAt', () {
      final Habit habit = weekdayHabit();
      final Habit renamed = habit.copyWith(name: 'Renamed');
      expect(renamed.id, habit.id);
      expect(renamed.createdAt, habit.createdAt);
      expect(renamed.name, 'Renamed');
    });
  });
}
