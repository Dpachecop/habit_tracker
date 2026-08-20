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

  /// App bar title when creating a habit.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get formTitleCreate;

  /// App bar title when editing one.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get formTitleEdit;

  /// Primary action of the habit form.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get formSave;

  /// Confirmation after creating a habit.
  ///
  /// In en, this message translates to:
  /// **'Goal created.'**
  String get formSavedCreate;

  /// Confirmation after editing a habit.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get formSavedEdit;

  /// Label of the habit name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get formNameLabel;

  /// Placeholder example in the name field.
  ///
  /// In en, this message translates to:
  /// **'Morning meditation'**
  String get formNameHint;

  /// Validation message for an empty name.
  ///
  /// In en, this message translates to:
  /// **'Give your goal a name.'**
  String get formNameRequired;

  /// Section label for the category picker.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get formCategoryLabel;

  /// Section label for the color picker.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get formColorLabel;

  /// Section label for the schedule.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get formScheduleLabel;

  /// Schedule mode where the user names the weekdays. Distinct from the other mode because here the app decides which days count.
  ///
  /// In en, this message translates to:
  /// **'On set days'**
  String get formScheduleModeWeekdays;

  /// Schedule mode where the user only sets a count per period and picks the days freely.
  ///
  /// In en, this message translates to:
  /// **'A number of times'**
  String get formScheduleModeTimes;

  /// Validation message when no weekday is selected.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day.'**
  String get formWeekdaysRequired;

  /// Shortcut that selects all seven weekdays.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get formEveryDay;

  /// Label for the completions-per-period number.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get formTimesLabel;

  /// Label before the period selector.
  ///
  /// In en, this message translates to:
  /// **'Per'**
  String get formPeriodLabel;

  /// SchedulePeriod.week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get formPeriodWeek;

  /// SchedulePeriod.month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get formPeriodMonth;

  /// SchedulePeriod.year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get formPeriodYear;

  /// Validation when the target exceeds the days available in the period. February is why the monthly cap is 28.
  ///
  /// In en, this message translates to:
  /// **'At most {max} — a day can only be completed once.'**
  String formTimesTooMany(int max);

  /// Section label for the optional daily time window.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get formTimeWindowLabel;

  /// Toggle meaning no particular time of day.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get formAllDay;

  /// Start of the time window.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get formTimeFrom;

  /// End of the time window.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get formTimeTo;

  /// Validation for an inverted time window.
  ///
  /// In en, this message translates to:
  /// **'The end has to come after the start.'**
  String get formTimeWindowInvalid;

  /// Section label for the date range.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get formDatesLabel;

  /// Label for the range start.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get formStartDate;

  /// Label for the range end.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get formEndDate;

  /// Toggle for an open-ended habit.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get formNoEndDate;

  /// Validation for an inverted date range.
  ///
  /// In en, this message translates to:
  /// **'The end cannot come before the start.'**
  String get formEndBeforeStart;

  /// Notice shown when editing to a SpecificWeekdays schedule. ARCHITECTURE.md 3.4.
  ///
  /// In en, this message translates to:
  /// **'The new days apply from tomorrow. Every day up to today keeps the old schedule, so the streak you have earned is safe.'**
  String get formScheduleChangeTomorrow;

  /// Notice shown when editing to a TimesPerPeriod schedule. ARCHITECTURE.md 3.4.
  ///
  /// In en, this message translates to:
  /// **'The new target applies from today. The days you have already completed still count towards it.'**
  String get formScheduleChangeToday;

  /// Dialog title for the 3.4 warning.
  ///
  /// In en, this message translates to:
  /// **'This period is already out of reach'**
  String get formUnreachableTitle;

  /// The 3.4 warning for a weekly target. Burning a streak in silence is not acceptable, so the user is told and decides.
  ///
  /// In en, this message translates to:
  /// **'You would need {missing} more this week and only {daysLeft} days are left. Saving will break the streak at the end of the week.'**
  String formUnreachableWeek(int missing, int daysLeft);

  /// The 3.4 warning for a monthly target.
  ///
  /// In en, this message translates to:
  /// **'You would need {missing} more this month and only {daysLeft} days are left. Saving will break the streak at the end of the month.'**
  String formUnreachableMonth(int missing, int daysLeft);

  /// The 3.4 warning for a yearly target.
  ///
  /// In en, this message translates to:
  /// **'You would need {missing} more this year and only {daysLeft} days are left. Saving will break the streak at the end of the year.'**
  String formUnreachableYear(int missing, int daysLeft);

  /// Confirms the change despite the warning.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get formUnreachableConfirm;

  /// Dismisses a confirmation without acting.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get formBack;

  /// Destructive action at the bottom of the edit form.
  ///
  /// In en, this message translates to:
  /// **'Archive goal'**
  String get formArchive;

  /// Explains that archiving is not deletion — habits are never hard-deleted because entries reference them.
  ///
  /// In en, this message translates to:
  /// **'It leaves your list but keeps its history. Nothing is deleted.'**
  String get formArchiveExplain;

  /// Confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Archive this goal?'**
  String get formArchiveConfirmTitle;

  /// Confirms archiving.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get formArchiveConfirm;

  /// Confirmation after archiving.
  ///
  /// In en, this message translates to:
  /// **'Goal archived.'**
  String get formArchived;

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
