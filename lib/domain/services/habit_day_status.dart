import '../entities/date_only.dart';
import '../entities/habit.dart';
import '../entities/habit_entry.dart';
import '../entities/habit_schedule.dart';

/// What a single day meant for a habit.
///
/// Three values, not two, and the third is the one that matters. A Tuesday on a
/// Monday/Wednesday/Saturday habit is **not a failure** — nothing was asked. A
/// grid that painted it the same as a genuinely missed day would misrepresent
/// how consistent someone has been, which is the one thing the grid exists to
/// show.
enum DayStatus {
  /// There is an entry for it.
  completed,

  /// It was due and it did not happen. Only ever in the past.
  missed,

  /// Nothing was asked: not a scheduled day, outside the habit's range, still
  /// in the future, or today while it is still open.
  notDue,
}

/// Reduces a habit's history to one status per day.
///
/// A pure projection of the same rules the streak engine walks, kept in the
/// domain for the same reason: the heatmap must not decide for itself what
/// counts as a miss, or it would eventually disagree with the streak drawn
/// three centimetres above it on the same card.
abstract final class HabitDayStatuses {
  /// The status of [date].
  static DayStatus on({
    required Habit habit,
    required Set<DateOnly> completedDays,
    required DateOnly date,
    required DateOnly today,
  }) {
    if (completedDays.contains(date)) return DayStatus.completed;
    if (!habit.range.contains(date)) return DayStatus.notDue;
    // Today is open until midnight and the future has not happened. Neither is
    // a miss — the same reason today never breaks a streak.
    if (date >= today) return DayStatus.notDue;

    return switch (habit.scheduleOn(date)) {
      final SpecificWeekdays schedule =>
        schedule.includes(date.weekday) ? DayStatus.missed : DayStatus.notDue,
      // A count per period puts no obligation on any particular day. In a
      // three-a-week habit the four days you did not go are not four failures;
      // falling short is a fact about the week, and the week is not a cell.
      TimesPerPeriod() => DayStatus.notDue,
    };
  }

  /// One status per day for the [length] days ending on [today], oldest first.
  ///
  /// Oldest first because that is reading order, which is how the card's strip
  /// is laid out: the last cell is today.
  static List<DayStatus> lastDays({
    required Habit habit,
    required Iterable<HabitEntry> entries,
    required DateOnly today,
    required int length,
  }) => between(
    habit: habit,
    entries: entries,
    from: today.addDays(-(length - 1)),
    to: today,
    today: today,
  );

  /// One status per day from [from] to [to], both inclusive, oldest first.
  ///
  /// The general form. The detail screen needs it because its grids start on
  /// calendar boundaries — a Monday for the week columns, the first of the
  /// month for the month view — rather than "N days back from now".
  ///
  /// Returns an empty list when [to] precedes [from], which is what a caller
  /// asking about an inverted range deserves rather than a crash.
  static List<DayStatus> between({
    required Habit habit,
    required Iterable<HabitEntry> entries,
    required DateOnly from,
    required DateOnly to,
    required DateOnly today,
  }) {
    if (to < from) return const <DayStatus>[];

    final Set<DateOnly> completed = completedDaysOf(habit, entries);
    final int days = from.daysUntil(to) + 1;

    return <DayStatus>[
      for (int offset = 0; offset < days; offset++)
        on(
          habit: habit,
          completedDays: completed,
          date: from.addDays(offset),
          today: today,
        ),
    ];
  }

  /// The days [habit] was completed on, out of a mixed pile of entries.
  ///
  /// Exposed because callers that ask about several ranges — the detail screen
  /// draws two grids over the same history — should filter once rather than
  /// per range.
  static Set<DateOnly> completedDaysOf(
    Habit habit,
    Iterable<HabitEntry> entries,
  ) => <DateOnly>{
    for (final HabitEntry entry in entries)
      if (entry.habitId == habit.id) entry.date,
  };
}
