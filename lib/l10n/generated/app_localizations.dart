import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Product name, shown in the OS task switcher.
  ///
  /// In en, this message translates to:
  /// **'Habit Tracker'**
  String get appTitle;

  /// Title of the main panel listing every habit.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get homeTitle;

  /// Shown on the main panel when the user has created nothing.
  ///
  /// In en, this message translates to:
  /// **'No habits yet.'**
  String get homeEmpty;

  /// Failure code 'network'. Reassuring rather than alarming: offline writes are queued, not lost.
  ///
  /// In en, this message translates to:
  /// **'No connection. Your changes will sync once you are back online.'**
  String get errorNetwork;

  /// Failure code 'not_found'.
  ///
  /// In en, this message translates to:
  /// **'We could not find that.'**
  String get errorNotFound;

  /// Failure code 'permission'.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to that.'**
  String get errorPermission;

  /// Failure code 'cache'.
  ///
  /// In en, this message translates to:
  /// **'The data stored on this device could not be read.'**
  String get errorCache;

  /// Failure code 'unknown'. Deliberately vague — the detail goes to the log, not to the user.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorUnknown;

  /// Failure code 'completion.archived'.
  ///
  /// In en, this message translates to:
  /// **'This habit is archived.'**
  String get errorCompletionArchived;

  /// Failure code 'completion.outside_range'.
  ///
  /// In en, this message translates to:
  /// **'That day falls outside the habit\'s date range.'**
  String get errorCompletionOutsideRange;

  /// Failure code 'completion.future_date'.
  ///
  /// In en, this message translates to:
  /// **'You cannot check off a day that has not happened yet.'**
  String get errorCompletionFutureDate;

  /// Failure code 'completion.already_recorded'.
  ///
  /// In en, this message translates to:
  /// **'You already checked this day off.'**
  String get errorCompletionAlreadyRecorded;

  /// Failure code 'completion.not_scheduled'. The no-over-completion rule, ARCHITECTURE.md 3.5.
  ///
  /// In en, this message translates to:
  /// **'This habit is not scheduled for that day.'**
  String get errorCompletionNotScheduled;

  /// Failure code 'completion.quota_reached'. The no-over-completion rule, ARCHITECTURE.md 3.5.
  ///
  /// In en, this message translates to:
  /// **'You have already met this period\'s goal.'**
  String get errorCompletionQuotaReached;

  /// Short label under a disabled check button when the habit is not due today.
  ///
  /// In en, this message translates to:
  /// **'Not today'**
  String get checkDisabledNotToday;

  /// Progress within the current week for an N-times-per-period habit.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{target} this week'**
  String quotaProgressWeek(int completed, int target);

  /// Progress within the current month for an N-times-per-period habit.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{target} this month'**
  String quotaProgressMonth(int completed, int target);

  /// Progress within the current year for an N-times-per-period habit.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{target} this year'**
  String quotaProgressYear(int completed, int target);

  /// Greeting on the home header before noon. No name: the account is anonymous until the last phase, and 'Good morning, null' is worse than no name at all.
  ///
  /// In en, this message translates to:
  /// **'Good morning.'**
  String get homeGreetingMorning;

  /// Greeting between noon and 19h.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon.'**
  String get homeGreetingAfternoon;

  /// Greeting from 19h onwards.
  ///
  /// In en, this message translates to:
  /// **'Good evening.'**
  String get homeGreetingEvening;

  /// Summary under the greeting. Counts only habits that are due today and still uncompleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing left for today. Well done.} =1{You have 1 habit left to complete today.} other{You have {count} habits left to complete today.}}'**
  String homeHabitsLeft(int count);

  /// Shown instead of the count when the user has habits but none of them fall on today.
  ///
  /// In en, this message translates to:
  /// **'Nothing is scheduled for today.'**
  String get homeNothingDueToday;

  /// Second line of the empty state, under homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create your first goal to start a streak.'**
  String get homeEmptyHint;

  /// Streak label on a habit card. Counts completed days, not periods.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} day streak}}'**
  String streakDays(int count);

  /// Shown in place of streakDays when the current streak is zero.
  ///
  /// In en, this message translates to:
  /// **'No streak yet'**
  String get streakNone;

  /// Schedule label for SpecificWeekdays covering all seven days.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get scheduleDaily;

  /// Schedule label for TimesPerPeriod over a week. Distinct from a weekday list on purpose: here the user picks which days, and that is a different goal.
  ///
  /// In en, this message translates to:
  /// **'{times, plural, =1{Once a week} =2{Twice a week} other{{times} times a week}}'**
  String scheduleTimesPerWeek(int times);

  /// Schedule label for TimesPerPeriod over a month.
  ///
  /// In en, this message translates to:
  /// **'{times, plural, =1{Once a month} =2{Twice a month} other{{times} times a month}}'**
  String scheduleTimesPerMonth(int times);

  /// Schedule label for TimesPerPeriod over a year.
  ///
  /// In en, this message translates to:
  /// **'{times, plural, =1{Once a year} =2{Twice a year} other{{times} times a year}}'**
  String scheduleTimesPerYear(int times);

  /// Bottom navigation label.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// Bottom navigation label.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Bottom navigation label.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Placeholder body for tabs whose phase has not been built yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon.'**
  String get comingSoon;

  /// HabitCategory.health
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// HabitCategory.fitness
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get categoryFitness;

  /// HabitCategory.mind
  ///
  /// In en, this message translates to:
  /// **'Mind'**
  String get categoryMind;

  /// HabitCategory.learning
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get categoryLearning;

  /// HabitCategory.work
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// HabitCategory.finance
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get categoryFinance;

  /// HabitCategory.social
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get categorySocial;

  /// HabitCategory.home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get categoryHome;

  /// HabitCategory.creativity
  ///
  /// In en, this message translates to:
  /// **'Creativity'**
  String get categoryCreativity;

  /// HabitCategory.other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
