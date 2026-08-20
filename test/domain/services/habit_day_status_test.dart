import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_entry.dart';
import 'package:habit_tracker/domain/entities/schedule_version.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';
import 'package:habit_tracker/domain/services/habit_day_status.dart';

import '../fixtures.dart';

void main() {
  /// A Thursday.
  final DateOnly today = d(2026, 8, 6);

  /// The status of one day, with the given entries.
  DayStatus statusOf(
    Habit habit,
    DateOnly date, {
    List<HabitEntry> entries = const <HabitEntry>[],
  }) => HabitDayStatuses.on(
    habit: habit,
    completedDays: <DateOnly>{
      for (final HabitEntry entry in entries)
        if (entry.habitId == habit.id) entry.date,
    },
    date: date,
    today: today,
  );

  group('a day with an entry', () {
    test('is completed, whatever the schedule says now', () {
      // It was legitimately done under the rules of its time. A later schedule
      // change must not turn a completed day into a blank one.
      final Habit habit = versionedHabit(
        start: d(2026, 8, 1),
        versions: <ScheduleVersion>[
          ScheduleVersion(
            schedule: SpecificWeekdays.daily(),
            effectiveFrom: d(2026, 8, 1),
          ),
          ScheduleVersion(
            schedule: SpecificWeekdays(<Weekday>{Weekday.monday}),
            effectiveFrom: d(2026, 8, 5),
          ),
        ],
      );

      expect(
        statusOf(
          habit,
          d(2026, 8, 5),
          entries: entriesOn(<DateOnly>[d(2026, 8, 5)]),
        ),
        DayStatus.completed,
      );
    });
  });

  group('named weekdays', () {
    final Habit monWedSat = weekdayHabit(
      days: <Weekday>{Weekday.monday, Weekday.wednesday, Weekday.saturday},
      start: d(2026, 8, 1),
    );

    test('a due day with no entry is a miss', () {
      // Wednesday the 5th.
      expect(statusOf(monWedSat, d(2026, 8, 5)), DayStatus.missed);
    });

    test('a day the habit never asked for is not a miss', () {
      // Tuesday the 4th. This is the whole reason the enum has three values:
      // painting it like a failure would misrepresent the user's consistency.
      expect(statusOf(monWedSat, d(2026, 8, 4)), DayStatus.notDue);
    });

    test('uses the schedule in force on that day, not today\'s', () {
      final Habit habit = versionedHabit(
        start: d(2026, 8, 1),
        versions: <ScheduleVersion>[
          ScheduleVersion(
            schedule: SpecificWeekdays(<Weekday>{Weekday.tuesday}),
            effectiveFrom: d(2026, 8, 1),
          ),
          ScheduleVersion(
            schedule: SpecificWeekdays(<Weekday>{Weekday.monday}),
            effectiveFrom: d(2026, 8, 5),
          ),
        ],
      );

      // Tuesday the 4th was due under the old rules, and still reads as a miss
      // even though Tuesdays are no longer scheduled.
      expect(statusOf(habit, d(2026, 8, 4)), DayStatus.missed);
    });
  });

  group('a count per period', () {
    test('a day without an entry is not a miss', () {
      // In a three-a-week habit the four days you did not go are not four
      // failures. Falling short is a fact about the week, and the week is not
      // a cell.
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 3));
      expect(statusOf(habit, d(2026, 8, 4)), DayStatus.notDue);
    });

    test('a completed day still shows', () {
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 3));
      expect(
        statusOf(
          habit,
          d(2026, 8, 4),
          entries: entriesOn(<DateOnly>[d(2026, 8, 4)]),
        ),
        DayStatus.completed,
      );
    });
  });

  group('days that ask nothing', () {
    test('today is still open, so it is never a miss', () {
      expect(
        statusOf(weekdayHabit(start: d(2026, 8, 1)), today),
        DayStatus.notDue,
      );
    });

    test('the future is not a miss either', () {
      expect(
        statusOf(weekdayHabit(start: d(2026, 8, 1)), d(2026, 8, 20)),
        DayStatus.notDue,
      );
    });

    test('days before the habit existed are blank', () {
      expect(
        statusOf(weekdayHabit(start: d(2026, 8, 1)), d(2026, 7, 20)),
        DayStatus.notDue,
      );
    });

    test('days after a habit ended are blank', () {
      final Habit habit = weekdayHabit(
        start: d(2026, 7, 1),
        end: d(2026, 7, 31),
      );
      expect(statusOf(habit, d(2026, 8, 3)), DayStatus.notDue);
    });
  });

  group('lastDays', () {
    test('returns one status per day, oldest first', () {
      final List<DayStatus> statuses = HabitDayStatuses.lastDays(
        habit: weekdayHabit(start: d(2026, 8, 1)),
        entries: entriesOn(<DateOnly>[d(2026, 8, 4), d(2026, 8, 5)]),
        today: today,
        length: 5,
      );

      // Aug 2 .. Aug 6, and the last cell is today.
      expect(statuses, <DayStatus>[
        DayStatus.missed,
        DayStatus.missed,
        DayStatus.completed,
        DayStatus.completed,
        DayStatus.notDue,
      ]);
    });

    test('ignores other habits\' entries', () {
      final List<DayStatus> statuses = HabitDayStatuses.lastDays(
        habit: weekdayHabit(start: d(2026, 8, 1)),
        entries: entriesOn(<DateOnly>[d(2026, 8, 5)], habitId: 'someone-else'),
        today: today,
        length: 2,
      );

      expect(statuses.first, DayStatus.missed);
    });

    test('a window longer than the habit is mostly blank', () {
      final List<DayStatus> statuses = HabitDayStatuses.lastDays(
        habit: weekdayHabit(start: d(2026, 8, 5)),
        entries: const <HabitEntry>[],
        today: today,
        length: 30,
      );

      expect(statuses, hasLength(30));
      // Only the 5th was due and missed; everything before the habit existed is
      // blank, and today is still open.
      expect(
        statuses.where((DayStatus s) => s == DayStatus.missed),
        hasLength(1),
      );
    });
  });
}
