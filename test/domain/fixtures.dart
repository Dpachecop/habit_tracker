/// Builders shared by the domain tests.
///
/// Streak cases are only readable if the noise — ids, colors, categories,
/// timestamps — stays out of the test body. Everything here fixes those to
/// constants so a test can say what it is actually about: dates, schedules and
/// entries.
///
/// Calendar anchors used throughout, all real 2026 dates:
/// Mon 2026-07-27 · Mon 2026-08-03 · **Thu 2026-08-06** · Sun 2026-08-09 ·
/// Mon 2026-08-10. The ISO week of 2026-09-01 starts on Mon 2026-08-31, which
/// is the month-straddling case §9 asks for.
library;

import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/date_range.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_category.dart';
import 'package:habit_tracker/domain/entities/habit_color_slot.dart';
import 'package:habit_tracker/domain/entities/habit_entry.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/schedule_version.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';

/// The habit id every fixture uses unless told otherwise.
const String testHabitId = 'habit-1';

/// A fixed instant for `createdAt` / `updatedAt`, so habits compare equal.
final DateTime testClock = DateTime.utc(2026, 1, 1, 12);

/// Shorthand for a [DateOnly]. Used constantly; the full constructor would
/// drown the tables of dates these tests are made of.
DateOnly d(int year, int month, int day) => DateOnly(year, month, day);

/// A habit on named weekdays (mode A), defaulting to daily.
Habit weekdayHabit({
  Set<Weekday>? days,
  DateOnly? start,
  DateOnly? end,
  String id = testHabitId,
  bool isArchived = false,
}) {
  final DateOnly from = start ?? d(2026, 1, 1);
  return Habit(
    id: id,
    name: 'Test habit',
    category: HabitCategory.health,
    colorSlot: HabitColorSlot.blue,
    scheduleHistory: <ScheduleVersion>[
      ScheduleVersion(
        schedule: SpecificWeekdays(days ?? Weekday.all),
        effectiveFrom: from,
      ),
    ],
    range: DateRange(start: from, end: end),
    createdAt: testClock,
    updatedAt: testClock,
    isArchived: isArchived,
  );
}

/// A habit with an N-per-period target (mode B).
Habit timesHabit({
  int times = 3,
  SchedulePeriod period = SchedulePeriod.week,
  DateOnly? start,
  DateOnly? end,
  String id = testHabitId,
  bool isArchived = false,
}) {
  final DateOnly from = start ?? d(2026, 1, 1);
  return Habit(
    id: id,
    name: 'Test habit',
    category: HabitCategory.fitness,
    colorSlot: HabitColorSlot.orange,
    scheduleHistory: <ScheduleVersion>[
      ScheduleVersion(
        schedule: TimesPerPeriod(times: times, period: period),
        effectiveFrom: from,
      ),
    ],
    range: DateRange(start: from, end: end),
    createdAt: testClock,
    updatedAt: testClock,
    isArchived: isArchived,
  );
}

/// A habit whose schedule changed over time — the §3.4 cases.
Habit versionedHabit({
  required List<ScheduleVersion> versions,
  required DateOnly start,
  DateOnly? end,
  String id = testHabitId,
}) => Habit(
  id: id,
  name: 'Test habit',
  category: HabitCategory.mind,
  colorSlot: HabitColorSlot.green,
  scheduleHistory: versions,
  range: DateRange(start: start, end: end),
  createdAt: testClock,
  updatedAt: testClock,
);

/// Check-ins for [dates], all belonging to [habitId].
List<HabitEntry> entriesOn(
  List<DateOnly> dates, {
  String habitId = testHabitId,
}) =>
    dates
        .map(
          (DateOnly date) =>
              HabitEntry.on(habitId, date, clock: date.toDateTime()),
        )
        .toList();

/// Every date in `[from, to]`, both inclusive. For the runs of consecutive
/// days that mode-A tests are full of.
List<DateOnly> datesFrom(DateOnly from, DateOnly to) {
  final List<DateOnly> dates = <DateOnly>[];
  for (DateOnly day = from; day <= to; day = day.addDays(1)) {
    dates.add(day);
  }
  return dates;
}
