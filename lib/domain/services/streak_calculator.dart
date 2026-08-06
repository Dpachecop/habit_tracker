import '../entities/date_only.dart';
import '../entities/date_period.dart';
import '../entities/habit.dart';
import '../entities/habit_entry.dart';
import '../entities/habit_schedule.dart';
import '../entities/schedule_version.dart';
import '../entities/streak.dart';

/// Derives a habit's streak from its entries. Pure function, no I/O, no Flutter.
///
/// This is the piece the whole app leans on: if it is right, everything else is
/// drawing data; if it is wrong, every screen lies. Hence it is a plain
/// function over values, so it can be tested exhaustively without a harness.
///
/// ## How the walk works
///
/// One pass backwards from the last relevant day to the habit's start. At each
/// step it asks `habit.scheduleOn(cursor)` — never a single schedule — so a run
/// can cross a schedule change and survive it (`ARCHITECTURE.md` §3.4). Mode A
/// consumes one day per step; mode B consumes a whole calendar period.
///
/// The same pass yields both figures: `current` is the run still standing when
/// the first break is met, `longest` is the largest run seen anywhere in the
/// history. Two passes would only be two chances to disagree.
abstract final class StreakCalculator {
  /// Computes the streak for [habit] as of [today].
  ///
  /// [entries] may hold other habits' check-ins and days outside the range;
  /// both are filtered out. Passing the full history is the normal case.
  static Streak calculate({
    required Habit habit,
    required Iterable<HabitEntry> entries,
    required DateOnly today,
  }) {
    final Set<DateOnly> completedDays = <DateOnly>{
      for (final HabitEntry entry in entries)
        if (entry.habitId == habit.id && habit.range.contains(entry.date))
          entry.date,
    };

    final DateOnly? lastCompleted = _latestOnOrBefore(completedDays, today);

    // Either the habit has not started yet, or it never had a single day in
    // scope. Nothing to walk.
    final DateOnly? lastDay = habit.range.lastRelevantDayOn(today);
    if (lastDay == null) {
      return Streak(current: 0, longest: 0, lastCompletedDate: lastCompleted);
    }

    final DateOnly firstDay = habit.range.start;
    final _StreakTally tally = _StreakTally();
    DateOnly cursor = lastDay;

    while (cursor >= firstDay) {
      switch (habit.scheduleOn(cursor)) {
        case final SpecificWeekdays schedule:
          _walkWeekdayScheduledDay(
            tally: tally,
            schedule: schedule,
            day: cursor,
            today: today,
            completedDays: completedDays,
          );
          cursor = cursor.addDays(-1);

        case final TimesPerPeriod schedule:
          cursor = _walkPeriod(
            tally: tally,
            habit: habit,
            schedule: schedule,
            cursor: cursor,
            firstDay: firstDay,
            lastDay: lastDay,
            completedDays: completedDays,
          );
      }
    }

    tally.close();
    return Streak(
      current: tally.current,
      longest: tally.longest,
      lastCompletedDate: lastCompleted,
    );
  }

  /// Mode A — judges a single day.
  ///
  /// Days the habit is not due on are transparent: they neither add to the run
  /// nor break it. Under §3.5 they cannot even hold an entry.
  static void _walkWeekdayScheduledDay({
    required _StreakTally tally,
    required SpecificWeekdays schedule,
    required DateOnly day,
    required DateOnly today,
    required Set<DateOnly> completedDays,
  }) {
    if (!schedule.includes(day.weekday)) return;

    if (completedDays.contains(day)) {
      tally.addDays(1);
      return;
    }
    // Today is still open until midnight, so a due-but-unchecked today is
    // pending, not failed. Any other missed due day breaks the run.
    if (day != today) tally.breakRun();
  }

  /// Mode B — judges the whole calendar period the cursor sits in and returns
  /// the day the walk should continue from.
  ///
  /// Periods are consumed whole rather than day by day, which is what makes
  /// "3 times a week" indifferent to *which* three days they were.
  static DateOnly _walkPeriod({
    required _StreakTally tally,
    required Habit habit,
    required TimesPerPeriod schedule,
    required DateOnly cursor,
    required DateOnly firstDay,
    required DateOnly lastDay,
    required Set<DateOnly> completedDays,
  }) {
    final DatePeriod period = DatePeriod.containing(cursor, schedule.period);
    final DateOnly windowStart =
        period.start < firstDay ? firstDay : period.start;
    final DateOnly windowEnd = cursor;
    final int completed = _countBetween(completedDays, windowStart, windowEnd);

    if (_isJudgeable(
          habit: habit,
          period: period,
          windowStart: windowStart,
          windowEnd: windowEnd,
          lastDay: lastDay,
        ) &&
        completed < habit.targetForPeriod(period)) {
      // A closed period that fell short ends the run, and its own completions
      // belong to no run at all — the week was not met.
      tally.breakRun();
    } else {
      tally.addDays(completed);
    }

    return windowStart.addDays(-1);
  }

  /// Whether a period is allowed to break the streak.
  ///
  /// Three cases stay out of it, and all three exist so that a run already
  /// earned is never taken away retroactively:
  ///
  /// - **The open period.** It still has days left, so being at 1 of 3 on a
  ///   Tuesday is not a failure yet (`ARCHITECTURE.md` §4).
  /// - **A period only partly in scope.** A habit that starts on a Sunday would
  ///   otherwise fail its first week against a target of 3 before it had three
  ///   days to spend.
  /// - **A period that straddles a change of mode.** Weeks are never split at a
  ///   version boundary (§3.4), so a week that was half "Mon/Wed" and half
  ///   "3 a week" cannot be judged fairly by either rule. Its completions still
  ///   count towards the run; it just cannot end it. In practice a change takes
  ///   effect today, so this only ever describes the open period anyway — it is
  ///   a guard, not a common path.
  static bool _isJudgeable({
    required Habit habit,
    required DatePeriod period,
    required DateOnly windowStart,
    required DateOnly windowEnd,
    required DateOnly lastDay,
  }) {
    if (period.contains(lastDay)) return false;
    if (windowStart != period.start || windowEnd != period.end) return false;
    return habit
        .versionsCovering(period.start, period.end)
        .every(
          (ScheduleVersion version) =>
              version.schedule is TimesPerPeriod &&
              (version.schedule as TimesPerPeriod).period == period.unit,
        );
  }

  /// The most recent completed day that is not in the future.
  static DateOnly? _latestOnOrBefore(Set<DateOnly> days, DateOnly limit) {
    DateOnly? latest;
    for (final DateOnly day in days) {
      if (day > limit) continue;
      if (latest == null || day > latest) latest = day;
    }
    return latest;
  }

  /// How many completed days fall in `[from, to]`, both inclusive.
  static int _countBetween(Set<DateOnly> days, DateOnly from, DateOnly to) {
    int count = 0;
    for (final DateOnly day in days) {
      if (day >= from && day <= to) count++;
    }
    return count;
  }
}

/// Running state of the backwards walk.
///
/// Exists so the walk can stay a single pass. `current` is captured at the
/// first break and never touched again — everything found further back belongs
/// to older runs and can only compete for `longest`.
final class _StreakTally {
  int _running = 0;
  int _longest = 0;
  int? _current;

  /// The run that is still alive today, once the walk has finished.
  int get current => _current ?? _running;

  /// The best run found anywhere in the history.
  int get longest => _longest;

  /// Adds [days] completed days to the run in progress.
  void addDays(int days) => _running += days;

  /// Ends the run in progress and starts a new one further back in time.
  void breakRun() {
    _current ??= _running;
    if (_running > _longest) _longest = _running;
    _running = 0;
  }

  /// Settles the last run once the walk reaches the start of the habit.
  void close() => breakRun();
}
