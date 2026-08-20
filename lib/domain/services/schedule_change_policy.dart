import 'package:equatable/equatable.dart';

import '../entities/date_only.dart';
import '../entities/date_period.dart';
import '../entities/habit.dart';
import '../entities/habit_entry.dart';
import '../entities/habit_schedule.dart';

/// The rules around *changing* a habit's schedule (`ARCHITECTURE.md` §3.4).
///
/// Editing a schedule never overwrites the old one — that is `Habit`'s job. What
/// lives here is the two questions the form has to answer before it does:
/// **from when** the new rules apply, and **whether the change quietly burns the
/// current streak**.
///
/// In the domain rather than in the form because both are business rules. A
/// second implementation inside a widget would drift from the engine that
/// actually scores the days.
abstract final class ScheduleChangePolicy {
  /// The day a newly chosen [schedule] starts applying.
  ///
  /// The two modes differ, and §3.4 explains why:
  ///
  /// - `SpecificWeekdays` → **tomorrow**. Applying it today could add today's
  ///   weekday to the set, turning a day that was never due into a day that
  ///   suddenly is. The user would be handed a requirement after the fact.
  /// - `TimesPerPeriod` → **today**. The period's target is the highest value in
  ///   force during it, so applying it now is safe in both directions: raising
  ///   asks for more of the open period, and lowering leaves the entries already
  ///   written legal.
  static DateOnly effectiveFromFor(HabitSchedule schedule, DateOnly today) =>
      switch (schedule) {
        SpecificWeekdays() => today.addDays(1),
        TimesPerPeriod() => today,
      };

  /// Whether the open period can still be met after the change.
  ///
  /// Returns `null` when the question does not apply — a `SpecificWeekdays`
  /// schedule has no quota to fall short of, and it takes effect tomorrow
  /// anyway.
  ///
  /// This exists because of the warning §3.4 demands. Raising a weekly goal from
  /// 3 to 5 on a Saturday leaves one day to earn two completions, so the week is
  /// already lost and the streak will break at midnight. The rule stays as the
  /// owner asked, but **burning a streak in silence is not acceptable** — the
  /// form has to say so and let the user decide.
  ///
  /// [entries] only has to cover the current period; anything else is ignored.
  static PeriodReachability? reachabilityAfterChange({
    required Habit habit,
    required HabitSchedule newSchedule,
    required Iterable<HabitEntry> entries,
    required DateOnly today,
  }) {
    if (newSchedule is! TimesPerPeriod) return null;

    final DatePeriod period = DatePeriod.containing(today, newSchedule.period);

    // What the target *would become*: §3.4's highest-in-force rule, with the new
    // value thrown into the comparison.
    final int currentTarget = habit.targetForPeriod(period);
    final int target =
        currentTarget > newSchedule.times ? currentTarget : newSchedule.times;

    final int completed =
        entries
            .where(
              (HabitEntry entry) =>
                  entry.habitId == habit.id &&
                  period.contains(entry.date) &&
                  habit.range.contains(entry.date),
            )
            .length;

    // Days still available, today included. Clipped by the habit's own end date:
    // a goal that finishes on Wednesday cannot use Thursday to catch up.
    final DateOnly? rangeEnd = habit.range.end;
    final DateOnly lastUsableDay =
        rangeEnd != null && rangeEnd < period.end ? rangeEnd : period.end;
    final int daysLeft =
        today > lastUsableDay ? 0 : today.daysUntil(lastUsableDay) + 1;

    return PeriodReachability(
      period: newSchedule.period,
      target: target,
      completed: completed,
      daysLeft: daysLeft,
    );
  }
}

/// Whether the period the user is in can still reach its target.
final class PeriodReachability extends Equatable {
  /// Bundles the four numbers the warning needs to explain itself.
  const PeriodReachability({
    required this.period,
    required this.target,
    required this.completed,
    required this.daysLeft,
  });

  /// Which calendar bucket this is about.
  final SchedulePeriod period;

  /// The target the period would be judged against.
  final int target;

  /// Completions already recorded in it.
  final int completed;

  /// Days still available to complete, today included.
  final int daysLeft;

  /// How many more completions the period still needs.
  int get missing {
    final int remaining = target - completed;
    return remaining < 0 ? 0 : remaining;
  }

  /// Whether the target is still achievable.
  ///
  /// One completion per day is the ceiling — the entry id is
  /// `{habitId}_{yyyy-MM-dd}`, so a day cannot be checked twice. That is what
  /// makes [daysLeft] a hard limit rather than an estimate.
  bool get isReachable => missing <= daysLeft;

  @override
  List<Object?> get props => <Object?>[period, target, completed, daysLeft];
}
