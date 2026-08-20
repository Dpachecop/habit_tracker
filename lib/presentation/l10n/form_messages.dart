import '../../domain/entities/habit_schedule.dart';
import '../../domain/services/schedule_change_policy.dart';
import '../../l10n/generated/app_localizations.dart';
import '../blocs/habit_form/habit_form_state.dart';

/// Text for the habit form's own vocabulary.
///
/// Same rule as everywhere else: `HabitFormField` and `PeriodReachability` carry
/// no words, and this is the single place they acquire any.
extension FormMessages on AppLocalizations {
  /// Why a field is not acceptable yet.
  String messageForFormField(HabitFormField field, {required int maxTimes}) =>
      switch (field) {
        HabitFormField.name => formNameRequired,
        HabitFormField.weekdays => formWeekdaysRequired,
        HabitFormField.times => formTimesTooMany(maxTimes),
        HabitFormField.timeWindow => formTimeWindowInvalid,
        HabitFormField.dateRange => formEndBeforeStart,
      };

  /// The name of a calendar bucket, for the period selector.
  String labelForPeriod(SchedulePeriod period) => switch (period) {
    SchedulePeriod.week => formPeriodWeek,
    SchedulePeriod.month => formPeriodMonth,
    SchedulePeriod.year => formPeriodYear,
  };

  /// The §3.4 warning, spelled out with its numbers.
  ///
  /// Three strings rather than one with the period injected: "this week" and
  /// "this month" are not interchangeable fragments in every language, and
  /// gluing them in would produce sentences no translator agreed to.
  String messageForUnreachablePeriod(PeriodReachability reachability) =>
      switch (reachability.period) {
        SchedulePeriod.week => formUnreachableWeek(
          reachability.missing,
          reachability.daysLeft,
        ),
        SchedulePeriod.month => formUnreachableMonth(
          reachability.missing,
          reachability.daysLeft,
        ),
        SchedulePeriod.year => formUnreachableYear(
          reachability.missing,
          reachability.daysLeft,
        ),
      };

  /// When a schedule change starts applying, in words.
  ///
  /// The two modes differ (`ARCHITECTURE.md` §3.4) and the difference matters to
  /// the user: one is reassurance that the streak survives, the other is notice
  /// that the current period already counts.
  String noticeForScheduleChange(HabitSchedule schedule) => switch (schedule) {
    SpecificWeekdays() => formScheduleChangeTomorrow,
    TimesPerPeriod() => formScheduleChangeToday,
  };
}
