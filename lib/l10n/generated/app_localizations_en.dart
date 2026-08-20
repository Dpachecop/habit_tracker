// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Habit Tracker';

  @override
  String get homeTitle => 'Habits';

  @override
  String get homeEmpty => 'No habits yet.';

  @override
  String get errorNetwork => 'No connection. Your changes will sync once you are back online.';

  @override
  String get errorNotFound => 'We could not find that.';

  @override
  String get errorPermission => 'You do not have access to that.';

  @override
  String get errorCache => 'The data stored on this device could not be read.';

  @override
  String get errorUnknown => 'Something went wrong.';

  @override
  String get errorCompletionArchived => 'This habit is archived.';

  @override
  String get errorCompletionOutsideRange => 'That day falls outside the habit\'s date range.';

  @override
  String get errorCompletionFutureDate => 'You cannot check off a day that has not happened yet.';

  @override
  String get errorCompletionAlreadyRecorded => 'You already checked this day off.';

  @override
  String get errorCompletionNotScheduled => 'This habit is not scheduled for that day.';

  @override
  String get errorCompletionQuotaReached => 'You have already met this period\'s goal.';

  @override
  String get checkDisabledNotToday => 'Not today';

  @override
  String quotaProgressWeek(int completed, int target) {
    return '$completed/$target this week';
  }

  @override
  String quotaProgressMonth(int completed, int target) {
    return '$completed/$target this month';
  }

  @override
  String quotaProgressYear(int completed, int target) {
    return '$completed/$target this year';
  }

  @override
  String get homeGreetingMorning => 'Good morning.';

  @override
  String get homeGreetingAfternoon => 'Good afternoon.';

  @override
  String get homeGreetingEvening => 'Good evening.';

  @override
  String homeHabitsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count habits left to complete today.',
      one: 'You have 1 habit left to complete today.',
      zero: 'Nothing left for today. Well done.',
    );
    return '$_temp0';
  }

  @override
  String get homeNothingDueToday => 'Nothing is scheduled for today.';

  @override
  String get homeEmptyHint => 'Create your first goal to start a streak.';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get streakNone => 'No streak yet';

  @override
  String get scheduleDaily => 'Daily';

  @override
  String scheduleTimesPerWeek(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '$times times a week',
      two: 'Twice a week',
      one: 'Once a week',
    );
    return '$_temp0';
  }

  @override
  String scheduleTimesPerMonth(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '$times times a month',
      two: 'Twice a month',
      one: 'Once a month',
    );
    return '$_temp0';
  }

  @override
  String scheduleTimesPerYear(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '$times times a year',
      two: 'Twice a year',
      one: 'Once a year',
    );
    return '$_temp0';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navSettings => 'Settings';

  @override
  String get navProfile => 'Profile';

  @override
  String get comingSoon => 'Coming soon.';

  @override
  String get formTitleCreate => 'New goal';

  @override
  String get formTitleEdit => 'Edit goal';

  @override
  String get formSave => 'Save';

  @override
  String get formSavedCreate => 'Goal created.';

  @override
  String get formSavedEdit => 'Changes saved.';

  @override
  String get formNameLabel => 'Name';

  @override
  String get formNameHint => 'Morning meditation';

  @override
  String get formNameRequired => 'Give your goal a name.';

  @override
  String get formCategoryLabel => 'Category';

  @override
  String get formColorLabel => 'Color';

  @override
  String get formScheduleLabel => 'How often';

  @override
  String get formScheduleModeWeekdays => 'On set days';

  @override
  String get formScheduleModeTimes => 'A number of times';

  @override
  String get formWeekdaysRequired => 'Pick at least one day.';

  @override
  String get formEveryDay => 'Every day';

  @override
  String get formTimesLabel => 'Times';

  @override
  String get formPeriodLabel => 'Per';

  @override
  String get formPeriodWeek => 'Week';

  @override
  String get formPeriodMonth => 'Month';

  @override
  String get formPeriodYear => 'Year';

  @override
  String formTimesTooMany(int max) {
    return 'At most $max — a day can only be completed once.';
  }

  @override
  String get formTimeWindowLabel => 'Time of day';

  @override
  String get formAllDay => 'All day';

  @override
  String get formTimeFrom => 'From';

  @override
  String get formTimeTo => 'To';

  @override
  String get formTimeWindowInvalid => 'The end has to come after the start.';

  @override
  String get formDatesLabel => 'Dates';

  @override
  String get formStartDate => 'Starts';

  @override
  String get formEndDate => 'Ends';

  @override
  String get formNoEndDate => 'No end date';

  @override
  String get formEndBeforeStart => 'The end cannot come before the start.';

  @override
  String get formScheduleChangeTomorrow => 'The new days apply from tomorrow. Every day up to today keeps the old schedule, so the streak you have earned is safe.';

  @override
  String get formScheduleChangeToday => 'The new target applies from today. The days you have already completed still count towards it.';

  @override
  String get formUnreachableTitle => 'This period is already out of reach';

  @override
  String formUnreachableWeek(int missing, int daysLeft) {
    return 'You would need $missing more this week and only $daysLeft days are left. Saving will break the streak at the end of the week.';
  }

  @override
  String formUnreachableMonth(int missing, int daysLeft) {
    return 'You would need $missing more this month and only $daysLeft days are left. Saving will break the streak at the end of the month.';
  }

  @override
  String formUnreachableYear(int missing, int daysLeft) {
    return 'You would need $missing more this year and only $daysLeft days are left. Saving will break the streak at the end of the year.';
  }

  @override
  String get formUnreachableConfirm => 'Save anyway';

  @override
  String get formBack => 'Go back';

  @override
  String get formArchive => 'Archive goal';

  @override
  String get formArchiveExplain => 'It leaves your list but keeps its history. Nothing is deleted.';

  @override
  String get formArchiveConfirmTitle => 'Archive this goal?';

  @override
  String get formArchiveConfirm => 'Archive';

  @override
  String get formArchived => 'Goal archived.';

  @override
  String heatmapSummary(int days, int completed) {
    return 'Last $days days, $completed completed.';
  }

  @override
  String get detailTitle => 'Goal';

  @override
  String get detailEdit => 'Edit';

  @override
  String get detailClose => 'Close';

  @override
  String get detailPreviousMonth => 'Previous month';

  @override
  String get detailNextMonth => 'Next month';

  @override
  String detailStreakChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'No streak',
    );
    return '$_temp0';
  }

  @override
  String detailLongestStreak(int count) {
    return 'Best: $count';
  }

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryFitness => 'Fitness';

  @override
  String get categoryMind => 'Mind';

  @override
  String get categoryLearning => 'Learning';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryFinance => 'Finance';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryHome => 'Home';

  @override
  String get categoryCreativity => 'Creativity';

  @override
  String get categoryOther => 'Other';
}
