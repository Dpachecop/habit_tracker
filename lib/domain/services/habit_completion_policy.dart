import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/date_only.dart';
import '../entities/date_period.dart';
import '../entities/habit.dart';
import '../entities/habit_entry.dart';
import '../entities/habit_schedule.dart';
import '../failures/failure.dart';

/// Why a day cannot be checked off.
///
/// Presentation needs the distinction: "today is not one of your days" and
/// "you already did your 3 this week" are the same refusal to the engine but
/// two different sentences to the user.
enum CompletionBlockReason {
  /// The habit is archived; its history is read-only now.
  archived,

  /// The day falls outside the habit's date range.
  outsideRange,

  /// The day has not happened yet. The future is not checkable — a streak has
  /// to be earned day by day.
  futureDate,

  /// There is already an entry for that day. Checking again is a no-op; the UI
  /// should be offering to uncheck instead.
  alreadyCompleted,

  /// Mode A: the habit is not due on that weekday (`ARCHITECTURE.md` §3.5).
  notScheduled,

  /// Mode B: the period's quota is full (`ARCHITECTURE.md` §3.5).
  quotaReached;

  /// The failure code this reason maps to, so the policy and the repositories
  /// cannot drift apart on naming.
  String get failureCode => switch (this) {
    CompletionBlockReason.archived => FailureCodes.completionArchived,
    CompletionBlockReason.outsideRange => FailureCodes.completionOutsideRange,
    CompletionBlockReason.futureDate => FailureCodes.completionFutureDate,
    CompletionBlockReason.alreadyCompleted =>
      FailureCodes.completionAlreadyRecorded,
    CompletionBlockReason.notScheduled => FailureCodes.completionNotScheduled,
    CompletionBlockReason.quotaReached => FailureCodes.completionQuotaReached,
  };
}

/// Whether a given day can be checked, and the numbers behind the answer.
///
/// The counts travel with the verdict because the home card shows them either
/// way — "1/3 this week" while there is room, "3/3 this week" once there is
/// not. Recomputing them in the UI would mean a second implementation of §3.4's
/// target rule.
final class CompletionAvailability extends Equatable {
  /// The allowed verdict. [periodTarget] and [completedInPeriod] are `null` for
  /// mode-A habits, which have no quota to report.
  const CompletionAvailability.allowed({
    this.completedInPeriod,
    this.periodTarget,
  }) : isAllowed = true,
       reason = null;

  /// The refused verdict, with the reason and whatever counts are relevant.
  const CompletionAvailability.blocked(
    CompletionBlockReason this.reason, {
    this.completedInPeriod,
    this.periodTarget,
  }) : isAllowed = false;

  /// Whether the day can be checked right now.
  final bool isAllowed;

  /// Why not, when [isAllowed] is false; `null` otherwise.
  final CompletionBlockReason? reason;

  /// Completions already recorded in the day's period (mode B only).
  final int? completedInPeriod;

  /// The target that period is judged against (mode B only). This is §3.4's
  /// highest-in-force value, not necessarily the currently configured one.
  final int? periodTarget;

  @override
  List<Object?> get props => <Object?>[
    isAllowed,
    reason,
    completedInPeriod,
    periodTarget,
  ];
}

/// The rule that decides whether a habit may be checked off on a given day.
///
/// The centrepiece is that **over-completing is not allowed**
/// (`ARCHITECTURE.md` §3.5): a goal states how much you meant to do, and doing
/// five days when you committed to three is not that goal. Doing more means
/// editing the goal, which §3.4 makes safe.
///
/// The rule lives here, in the domain, and not in the widget that draws the
/// checkbox. The UI disables the button as a courtesy so the error is rarely
/// reached; correctness does not depend on it having done so.
abstract final class HabitCompletionPolicy {
  /// Judges [date] for [habit] as of [today].
  ///
  /// [entries] only has to contain this habit's entries for the period around
  /// [date] — the whole history works too, everything else is filtered out.
  /// Passing too few is the caller's bug and would show up as a quota that
  /// never fills.
  static CompletionAvailability check({
    required Habit habit,
    required Iterable<HabitEntry> entries,
    required DateOnly date,
    required DateOnly today,
  }) {
    if (habit.isArchived) {
      return const CompletionAvailability.blocked(
        CompletionBlockReason.archived,
      );
    }
    if (date > today) {
      return const CompletionAvailability.blocked(
        CompletionBlockReason.futureDate,
      );
    }
    if (!habit.range.contains(date)) {
      return const CompletionAvailability.blocked(
        CompletionBlockReason.outsideRange,
      );
    }

    final Iterable<HabitEntry> own = entries.where(
      (HabitEntry entry) => entry.habitId == habit.id,
    );
    // Checked before the schedule rules on purpose: a day completed under the
    // old schedule stays completed even if today's rules no longer schedule it.
    // Reporting `notScheduled` there would be both wrong and confusing.
    if (own.any((HabitEntry entry) => entry.date == date)) {
      return const CompletionAvailability.blocked(
        CompletionBlockReason.alreadyCompleted,
      );
    }

    switch (habit.scheduleOn(date)) {
      case final SpecificWeekdays schedule:
        return schedule.includes(date.weekday)
            ? const CompletionAvailability.allowed()
            : const CompletionAvailability.blocked(
              CompletionBlockReason.notScheduled,
            );
      case final TimesPerPeriod schedule:
        final DatePeriod period = DatePeriod.containing(date, schedule.period);
        final int target = habit.targetForPeriod(period);
        final int completed =
            own
                .where(
                  (HabitEntry entry) =>
                      period.contains(entry.date) &&
                      habit.range.contains(entry.date),
                )
                .length;
        if (completed >= target) {
          return CompletionAvailability.blocked(
            CompletionBlockReason.quotaReached,
            completedInPeriod: completed,
            periodTarget: target,
          );
        }
        return CompletionAvailability.allowed(
          completedInPeriod: completed,
          periodTarget: target,
        );
    }
  }

  /// [check] as an `Either`, for the repositories that have to refuse a write.
  ///
  /// This is the enforcement point: an entry is only ever created after this
  /// returns a `Right`, so a client that ignores the disabled button still
  /// cannot write an illegal entry.
  static Either<Failure, Unit> ensureCanComplete({
    required Habit habit,
    required Iterable<HabitEntry> entries,
    required DateOnly date,
    required DateOnly today,
  }) {
    final CompletionAvailability availability = check(
      habit: habit,
      entries: entries,
      date: date,
      today: today,
    );
    if (availability.isAllowed) return const Right<Failure, Unit>(unit);
    return Left<Failure, Unit>(
      ValidationFailure(code: availability.reason!.failureCode),
    );
  }

  /// Whether an existing check-in may be removed.
  ///
  /// Unchecking is always allowed on a live habit, including for past days —
  /// correcting a mistap is legitimate and can only ever lower a streak, never
  /// forge one. Archived habits are frozen.
  static Either<Failure, Unit> ensureCanUncomplete({required Habit habit}) {
    if (habit.isArchived) {
      return const Left<Failure, Unit>(
        ValidationFailure(code: FailureCodes.completionArchived),
      );
    }
    return const Right<Failure, Unit>(unit);
  }
}
