import '../../domain/entities/habit_category.dart';
import '../../domain/entities/habit_schedule.dart';
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
