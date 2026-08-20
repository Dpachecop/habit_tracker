import '../../domain/entities/habit_category.dart';
import '../../domain/entities/habit_schedule.dart';
import '../../domain/services/habit_completion_policy.dart';
import '../../l10n/generated/app_localizations.dart';

/// Labels for the domain enums that reach the screen.
///
/// Same rule as `FailureMessages`: the domain names its values in English
/// identifiers and knows nothing about how they are shown. Everything that
/// turns one of those values into words lives here, so a new language is one
/// `.arb` file and no code change at all.
extension DomainLabels on AppLocalizations {
  /// The display name of a habit's category.
  ///
  /// Exhaustive on purpose — no `default` branch. Adding a category to the
  /// enum then becomes a compile error here, which is precisely the reminder
  /// that it also needs a translation.
  String labelForCategory(HabitCategory category) => switch (category) {
    HabitCategory.health => categoryHealth,
    HabitCategory.fitness => categoryFitness,
    HabitCategory.mind => categoryMind,
    HabitCategory.learning => categoryLearning,
    HabitCategory.work => categoryWork,
    HabitCategory.finance => categoryFinance,
    HabitCategory.social => categorySocial,
    HabitCategory.home => categoryHome,
    HabitCategory.creativity => categoryCreativity,
    HabitCategory.other => categoryOther,
  };

  /// The short label a card shows in place of the streak when the check is
  /// blocked.
  ///
  /// Deliberately not the same strings as `FailureMessages`: those are full
  /// sentences for a snackbar after a refused tap ("This habit is not scheduled
  /// for that day."), while a card has room for three words and is explaining a
  /// *state*, not an error. Same domain reason, two registers.
  String messageForBlockReason(
    CompletionBlockReason? reason,
    CompletionAvailability availability,
  ) => switch (reason) {
    CompletionBlockReason.notScheduled => checkDisabledNotToday,
    // The one case with numbers, and the reason they travel on the verdict.
    CompletionBlockReason.quotaReached => _quotaOrFallback(availability),
    CompletionBlockReason.alreadyCompleted => errorCompletionAlreadyRecorded,
    CompletionBlockReason.archived => errorCompletionArchived,
    CompletionBlockReason.outsideRange => errorCompletionOutsideRange,
    CompletionBlockReason.futureDate => errorCompletionFutureDate,
    // Unreachable while the card only asks about blocked states, but a blocked
    // verdict always has a reason and this keeps the switch total.
    null => '',
  };

  /// "3/3 this week", falling back to the generic sentence if the verdict
  /// somehow arrived without its counters.
  String _quotaOrFallback(CompletionAvailability availability) {
    final int? completed = availability.completedInPeriod;
    final int? target = availability.periodTarget;
    final SchedulePeriod? period = availability.period;
    if (completed == null || target == null || period == null) {
      return errorCompletionQuotaReached;
    }
    return quotaProgress(period: period, completed: completed, target: target);
  }

  /// Progress within the current period, as "2/3 this week".
  ///
  /// The numbers come straight from `CompletionAvailability`, which already
  /// applied §3.4's highest-target-in-force rule. Recomputing them here would
  /// be a second implementation of that rule, and the two would eventually
  /// disagree.
  String quotaProgress({
    required SchedulePeriod period,
    required int completed,
    required int target,
  }) => switch (period) {
    SchedulePeriod.week => quotaProgressWeek(completed, target),
    SchedulePeriod.month => quotaProgressMonth(completed, target),
    SchedulePeriod.year => quotaProgressYear(completed, target),
  };
}
