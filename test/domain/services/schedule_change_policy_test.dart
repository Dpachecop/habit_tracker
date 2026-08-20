import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_entry.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';
import 'package:habit_tracker/domain/services/schedule_change_policy.dart';

import '../fixtures.dart';

void main() {
  group('when a change takes effect — §3.4', () {
    test('named weekdays start tomorrow', () {
      // Today cannot become due retroactively. If the user adds Thursday on a
      // Thursday, that Thursday was never a day they signed up for.
      expect(
        ScheduleChangePolicy.effectiveFromFor(
          SpecificWeekdays(<Weekday>{Weekday.thursday}),
          d(2026, 8, 6),
        ),
        d(2026, 8, 7),
      );
    });

    test('a times-per-period target starts today', () {
      // Safe in both directions because the period is judged by the highest
      // target in force during it.
      expect(
        ScheduleChangePolicy.effectiveFromFor(
          TimesPerPeriod(times: 5, period: SchedulePeriod.week),
          d(2026, 8, 6),
        ),
        d(2026, 8, 6),
      );
    });

    test('crosses a month boundary correctly', () {
      expect(
        ScheduleChangePolicy.effectiveFromFor(
          SpecificWeekdays.daily(),
          d(2026, 8, 31),
        ),
        d(2026, 9, 1),
      );
    });
  });

  group('whether the open period is still reachable', () {
    test('is not asked about named weekdays', () {
      // No quota to fall short of, and it starts tomorrow anyway.
      expect(
        ScheduleChangePolicy.reachabilityAfterChange(
          habit: weekdayHabit(start: d(2026, 8, 3)),
          newSchedule: SpecificWeekdays.daily(),
          entries: const <HabitEntry>[],
          today: d(2026, 8, 6),
        ),
        isNull,
      );
    });

    test('the warned-about case: 3 to 5 on a Saturday', () {
      // §3.4's own example. Two more completions needed, one day left, so the
      // week is already lost and the streak breaks at midnight. The rule stands;
      // the form has to say so out loud.
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 3));
      final PeriodReachability? result =
          ScheduleChangePolicy.reachabilityAfterChange(
            habit: habit,
            newSchedule: TimesPerPeriod(times: 5, period: SchedulePeriod.week),
            entries: entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 5))),
            today: d(2026, 8, 8),
          );

      expect(result, isNotNull);
      expect(result!.target, 5);
      expect(result.completed, 3);
      // Saturday the 8th plus Sunday the 9th.
      expect(result.daysLeft, 2);
      expect(result.missing, 2);
      expect(result.isReachable, isTrue);
    });

    test('the same change one day later is unreachable', () {
      final PeriodReachability result =
          ScheduleChangePolicy.reachabilityAfterChange(
            habit: timesHabit(times: 3, start: d(2026, 8, 3)),
            newSchedule: TimesPerPeriod(times: 5, period: SchedulePeriod.week),
            entries: entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 5))),
            // Sunday: one day left, two completions still needed.
            today: d(2026, 8, 9),
          )!;

      expect(result.daysLeft, 1);
      expect(result.missing, 2);
      expect(result.isReachable, isFalse);
    });

    test('raising early in the week is fine', () {
      final PeriodReachability result =
          ScheduleChangePolicy.reachabilityAfterChange(
            habit: timesHabit(times: 3, start: d(2026, 8, 3)),
            newSchedule: TimesPerPeriod(times: 5, period: SchedulePeriod.week),
            entries: entriesOn(<DateOnly>[d(2026, 8, 3)]),
            today: d(2026, 8, 4),
          )!;

      expect(result.missing, 4);
      expect(result.daysLeft, 6);
      expect(result.isReachable, isTrue);
    });

    test('lowering the target keeps the higher one, per §3.4', () {
      // Dropping 5 to 3 mid-week does not shrink the week's target — that is
      // what keeps the five entries already written legal under §3.5.
      final PeriodReachability result =
          ScheduleChangePolicy.reachabilityAfterChange(
            habit: timesHabit(times: 5, start: d(2026, 8, 3)),
            newSchedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
            entries: entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 6))),
            today: d(2026, 8, 7),
          )!;

      expect(result.target, 5);
      expect(result.missing, 1);
      expect(result.isReachable, isTrue);
    });

    test('a met period needs nothing more', () {
      final PeriodReachability result =
          ScheduleChangePolicy.reachabilityAfterChange(
            habit: timesHabit(times: 3, start: d(2026, 8, 3)),
            newSchedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
            entries: entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 5))),
            today: d(2026, 8, 6),
          )!;

      expect(result.missing, 0);
      expect(result.isReachable, isTrue);
    });

    test('a habit that ends mid-period cannot use the days after it', () {
      // The range clips the runway: a goal finishing on Wednesday cannot catch
      // up on Thursday.
      final PeriodReachability result =
          ScheduleChangePolicy.reachabilityAfterChange(
            habit: timesHabit(
              times: 3,
              start: d(2026, 8, 3),
              end: d(2026, 8, 5),
            ),
            newSchedule: TimesPerPeriod(times: 4, period: SchedulePeriod.week),
            entries: entriesOn(<DateOnly>[d(2026, 8, 3)]),
            today: d(2026, 8, 4),
          )!;

      // Tuesday and Wednesday only, not the rest of the ISO week.
      expect(result.daysLeft, 2);
      expect(result.missing, 3);
      expect(result.isReachable, isFalse);
    });

    test('counts a monthly period across its whole length', () {
      final PeriodReachability result =
          ScheduleChangePolicy.reachabilityAfterChange(
            habit: timesHabit(
              times: 2,
              period: SchedulePeriod.month,
              start: d(2026, 8, 1),
            ),
            newSchedule: TimesPerPeriod(times: 6, period: SchedulePeriod.month),
            entries: entriesOn(<DateOnly>[d(2026, 8, 2)]),
            today: d(2026, 8, 6),
          )!;

      expect(result.target, 6);
      expect(result.missing, 5);
      // The 6th through the 31st.
      expect(result.daysLeft, 26);
      expect(result.isReachable, isTrue);
    });
  });
}
