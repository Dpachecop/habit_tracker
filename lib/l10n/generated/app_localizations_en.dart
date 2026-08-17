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
  String get errorNetwork =>
      'No connection. Your changes will sync once you are back online.';

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
  String get errorCompletionOutsideRange =>
      'That day falls outside the habit\'s date range.';

  @override
  String get errorCompletionFutureDate =>
      'You cannot check off a day that has not happened yet.';

  @override
  String get errorCompletionAlreadyRecorded =>
      'You already checked this day off.';

  @override
  String get errorCompletionNotScheduled =>
      'This habit is not scheduled for that day.';

  @override
  String get errorCompletionQuotaReached =>
      'You have already met this period\'s goal.';

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
