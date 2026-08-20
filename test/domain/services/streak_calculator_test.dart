import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_entry.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/schedule_version.dart';
import 'package:habit_tracker/domain/entities/streak.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';
import 'package:habit_tracker/domain/services/streak_calculator.dart';

import '../fixtures.dart';

void main() {
  /// Runs the calculator. Wrapping it keeps every case below to one line of
  /// setup and one of assertion.
  Streak streakOf(Habit habit, List<HabitEntry> entries, DateOnly today) =>
      StreakCalculator.calculate(habit: habit, entries: entries, today: today);

  group('mode A — specific weekdays', () {
    test('counts consecutive completed days', () {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final Streak streak = streakOf(
        habit,
        entriesOn(datesFrom(d(2026, 8, 4), d(2026, 8, 6))),
        d(2026, 8, 6),
      );

      expect(streak.current, 3);
      expect(streak.longest, 3);
      expect(streak.lastCompletedDate, d(2026, 8, 6));
    });

    test('today unchecked does not break the streak', () {
      // The day is open until midnight: pending, not failed.
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[d(2026, 8, 4), d(2026, 8, 5)]),
        d(2026, 8, 6),
      );

      expect(streak.current, 2);
    });

    test('a missed day that is not today breaks it', () {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[d(2026, 8, 4), d(2026, 8, 6)]),
        d(2026, 8, 6),
      );

      expect(streak.current, 1);
      expect(streak.longest, 1);
    });

    test("the architecture's own example: Mon and Tue done, Wed missed", () {
      // §4, mode A. Monday to Friday, today is Thursday and Wednesday was
      // skipped — Wednesday was a scheduled day, so the run is over.
      final Habit habit = weekdayHabit(
        days: <Weekday>{
          Weekday.monday,
          Weekday.tuesday,
          Weekday.wednesday,
          Weekday.thursday,
          Weekday.friday,
        },
        start: d(2026, 8, 3),
      );
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[d(2026, 8, 3), d(2026, 8, 4)]),
        d(2026, 8, 6),
      );

      expect(streak.current, 0);
      expect(streak.longest, 2);
    });

    test('unscheduled days are transparent, not misses', () {
      // Mon–Fri across two weeks: the weekends in between must not break it.
      final Habit habit = weekdayHabit(
        days: <Weekday>{
          Weekday.monday,
          Weekday.tuesday,
          Weekday.wednesday,
          Weekday.thursday,
          Weekday.friday,
        },
        start: d(2026, 7, 27),
      );
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[
          ...datesFrom(d(2026, 7, 27), d(2026, 7, 31)),
          ...datesFrom(d(2026, 8, 3), d(2026, 8, 6)),
        ]),
        d(2026, 8, 6),
      );

      expect(streak.current, 9);
    });

    test('survives the turn of the year', () {
      final Habit habit = weekdayHabit(start: d(2025, 12, 28));
      final Streak streak = streakOf(
        habit,
        entriesOn(datesFrom(d(2025, 12, 28), d(2026, 1, 2))),
        d(2026, 1, 2),
      );

      expect(streak.current, 6);
    });

    test('keeps the longest run separate from a broken current one', () {
      final Habit habit = weekdayHabit(start: d(2026, 7, 1));
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[
          ...datesFrom(d(2026, 7, 1), d(2026, 7, 10)),
          ...datesFrom(d(2026, 7, 20), d(2026, 7, 22)),
        ]),
        d(2026, 7, 25),
      );

      expect(streak.current, 0);
      expect(streak.longest, 10);
      expect(streak.lastCompletedDate, d(2026, 7, 22));
    });

    test('stops at the end of a closed range instead of piling up misses', () {
      // A habit that ran through July and finished. Its final streak stands;
      // August is not a run of missed days.
      final Habit habit = weekdayHabit(
        start: d(2026, 7, 1),
        end: d(2026, 7, 31),
      );
      final Streak streak = streakOf(
        habit,
        entriesOn(datesFrom(d(2026, 7, 1), d(2026, 7, 31))),
        d(2026, 8, 6),
      );

      expect(streak.current, 31);
      expect(streak.longest, 31);
    });

    test('is empty for a habit that has not started yet', () {
      final Habit habit = weekdayHabit(start: d(2026, 9, 1));
      final Streak streak = streakOf(habit, <HabitEntry>[], d(2026, 8, 6));

      expect(streak, const Streak(current: 0, longest: 0));
    });
  });

  group('mode B — times per period', () {
    test("the architecture's own example: 3 a week, three done", () {
      // §4, mode B. The streak is measured in completed days, not in periods.
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 3));
      final Streak streak = streakOf(
        habit,
        entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 5))),
        d(2026, 8, 6),
      );

      expect(streak.current, 3);
    });

    test('two met weeks in a row make six, not two', () {
      final Habit habit = timesHabit(times: 3, start: d(2026, 7, 27));
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[
          ...datesFrom(d(2026, 7, 27), d(2026, 7, 29)),
          ...datesFrom(d(2026, 8, 3), d(2026, 8, 5)),
        ]),
        d(2026, 8, 6),
      );

      expect(streak.current, 6);
      expect(streak.longest, 6);
    });

    test('a closed period below target breaks it', () {
      final Habit habit = timesHabit(times: 3, start: d(2026, 7, 27));
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[
          ...datesFrom(d(2026, 7, 27), d(2026, 7, 28)),
          ...datesFrom(d(2026, 8, 3), d(2026, 8, 5)),
        ]),
        d(2026, 8, 6),
      );

      expect(streak.current, 3);
      expect(streak.longest, 3);
    });

    test('the open period never breaks it, even at zero', () {
      // Monday morning of a new week: nothing done yet, and last week was met.
      // The run has to survive until the week can actually fail.
      final Habit habit = timesHabit(times: 3, start: d(2026, 7, 27));
      final Streak streak = streakOf(
        habit,
        entriesOn(datesFrom(d(2026, 7, 27), d(2026, 7, 29))),
        d(2026, 8, 3),
      );

      expect(streak.current, 3);
    });

    test('a first period only partly inside the range cannot fail', () {
      // The habit starts on a Sunday, so its first ISO week has one day in it.
      // Judging that against a target of 3 would break a streak before it had
      // a chance to exist.
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 9));
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[d(2026, 8, 9)]),
        d(2026, 8, 12),
      );

      expect(streak.current, 1);
    });

    test('counts an ISO week that straddles two months as one period', () {
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 31));
      final Streak streak = streakOf(
        habit,
        entriesOn(datesFrom(d(2026, 8, 31), d(2026, 9, 2))),
        d(2026, 9, 3),
      );

      expect(streak.current, 3);
    });

    test('handles monthly periods', () {
      final Habit habit = timesHabit(
        times: 2,
        period: SchedulePeriod.month,
        start: d(2026, 6, 1),
      );
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[
          d(2026, 6, 5),
          d(2026, 6, 20),
          d(2026, 7, 3),
          d(2026, 7, 30),
          d(2026, 8, 1),
        ]),
        d(2026, 8, 6),
      );

      // 1 so far in the open August + 2 in July + 2 in June.
      expect(streak.current, 5);
    });

    test('handles yearly periods across the turn of the year', () {
      final Habit habit = timesHabit(
        times: 2,
        period: SchedulePeriod.year,
        start: d(2025, 1, 1),
      );
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[d(2025, 3, 1), d(2025, 11, 4), d(2026, 1, 15)]),
        d(2026, 8, 6),
      );

      expect(streak.current, 3);
    });

    test('a missed month breaks it and the older run becomes the longest', () {
      final Habit habit = timesHabit(
        times: 2,
        period: SchedulePeriod.month,
        start: d(2026, 4, 1),
      );
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[
          d(2026, 4, 2),
          d(2026, 4, 20),
          d(2026, 5, 3),
          d(2026, 5, 19),
          // June only has one — the month closes below target.
          d(2026, 6, 8),
          d(2026, 7, 1),
          d(2026, 7, 14),
        ]),
        d(2026, 8, 6),
      );

      expect(streak.current, 2);
      expect(streak.longest, 4);
    });
  });

  group('schedule changes — §3.4', () {
    test(
      'raising the target mid-week judges the whole week by the new one',
      () {
        // The warned-about case: 3 to 5 on Wednesday makes the week ask for 5,
        // and three days are no longer enough once it closes.
        final Habit habit = versionedHabit(
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
        final List<HabitEntry> entries = entriesOn(
          datesFrom(d(2026, 8, 3), d(2026, 8, 5)),
        );

        // While the week is open the run stands.
        expect(streakOf(habit, entries, d(2026, 8, 6)).current, 3);
        // Once it closes at 3 of 5, it does not.
        expect(streakOf(habit, entries, d(2026, 8, 10)).current, 0);
      },
    );

    test('lowering the target keeps the days already earned valid', () {
      // 5 down to 3 on Wednesday. The week stays at 5, which is the only way
      // the five entries already written remain legal under §3.5.
      final Habit habit = versionedHabit(
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
      final Streak streak = streakOf(
        habit,
        entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 7))),
        d(2026, 8, 10),
      );

      expect(streak.current, 5);
    });

    test('a run survives a change from weekdays to times-per-period', () {
      // §4, mixed schedules. Two weeks of Mon–Fri, then 3 a week from the
      // following Monday. The days earned under the old rules still count.
      final Habit habit = versionedHabit(
        start: d(2026, 7, 27),
        versions: <ScheduleVersion>[
          ScheduleVersion(
            schedule: SpecificWeekdays(<Weekday>{
              Weekday.monday,
              Weekday.tuesday,
              Weekday.wednesday,
              Weekday.thursday,
              Weekday.friday,
            }),
            effectiveFrom: d(2026, 7, 27),
          ),
          ScheduleVersion(
            schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
            effectiveFrom: d(2026, 8, 10),
          ),
        ],
      );
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[
          ...datesFrom(d(2026, 7, 27), d(2026, 7, 31)),
          ...datesFrom(d(2026, 8, 3), d(2026, 8, 7)),
          ...datesFrom(d(2026, 8, 10), d(2026, 8, 12)),
        ]),
        d(2026, 8, 13),
      );

      expect(streak.current, 13);
      expect(streak.longest, 13);
    });

    test('a week straddling a mode change counts once and cannot break', () {
      // 3 a week until Thursday, daily from Thursday on. The week is half one
      // mode and half the other, so it cannot be judged fairly by either — the
      // guard makes it count its days without ever ending the run.
      final Habit habit = versionedHabit(
        start: d(2026, 8, 3),
        versions: <ScheduleVersion>[
          ScheduleVersion(
            schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
            effectiveFrom: d(2026, 8, 3),
          ),
          ScheduleVersion(
            schedule: SpecificWeekdays.daily(),
            effectiveFrom: d(2026, 8, 6),
          ),
        ],
      );
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[
          d(2026, 8, 3),
          d(2026, 8, 4),
          ...datesFrom(d(2026, 8, 6), d(2026, 8, 9)),
        ]),
        d(2026, 8, 10),
      );

      // Four daily days plus the two done before the switch, each counted once.
      expect(streak.current, 6);
    });
  });

  group('input hygiene', () {
    test("ignores other habits' entries", () {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final Streak streak = streakOf(habit, <HabitEntry>[
        ...entriesOn(<DateOnly>[d(2026, 8, 6)]),
        ...entriesOn(
          datesFrom(d(2026, 8, 1), d(2026, 8, 5)),
          habitId: 'someone-else',
        ),
      ], d(2026, 8, 6));

      expect(streak.current, 1);
      expect(streak.longest, 1);
    });

    test('ignores entries outside the habit range', () {
      final Habit habit = weekdayHabit(
        start: d(2026, 8, 3),
        end: d(2026, 8, 5),
      );
      final Streak streak = streakOf(
        habit,
        entriesOn(datesFrom(d(2026, 8, 1), d(2026, 8, 5))),
        d(2026, 8, 6),
      );

      expect(streak.current, 3);
      expect(streak.lastCompletedDate, d(2026, 8, 5));
    });

    test('never counts a future entry', () {
      // Should not exist — the policy refuses to create one — but a corrupt
      // row must not inflate today's streak.
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final Streak streak = streakOf(
        habit,
        entriesOn(<DateOnly>[d(2026, 8, 6), d(2026, 8, 7)]),
        d(2026, 8, 6),
      );

      expect(streak.current, 1);
      expect(streak.lastCompletedDate, d(2026, 8, 6));
    });

    test('is empty when there are no entries at all', () {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final Streak streak = streakOf(habit, <HabitEntry>[], d(2026, 8, 6));

      expect(streak.current, 0);
      expect(streak.longest, 0);
      expect(streak.lastCompletedDate, isNull);
      expect(streak.hasHistory, isFalse);
    });
  });
}
