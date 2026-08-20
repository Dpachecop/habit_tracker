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
