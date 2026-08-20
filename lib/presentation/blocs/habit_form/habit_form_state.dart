import 'package:equatable/equatable.dart';

import '../../../domain/entities/date_only.dart';
import '../../../domain/entities/date_range.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_category.dart';
import '../../../domain/entities/habit_color_slot.dart';
import '../../../domain/entities/habit_schedule.dart';
import '../../../domain/entities/time_window.dart';
import '../../../domain/entities/weekday.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/services/schedule_change_policy.dart';

/// Which of the two schedule modes the form is showing.
///
/// A UI-level toggle, not a domain type: the domain has a sealed union, and the
/// form needs to remember *both* branches' settings while the user flips between
/// them so that switching back does not lose what they had typed.
enum ScheduleMode {
  /// Named weekdays — the user says which days.
  weekdays,

  /// A count per calendar period — the user picks the days freely.
  timesPerPeriod,
}

/// A field the user has to fix before the form can be saved.
///
/// The enum carries no text. Presentation turns each one into a sentence, the
/// same way it does with failure codes, so the form stays language-free.
enum HabitFormField {
  /// The name is blank.
  name,

  /// No weekday is selected.
  weekdays,

  /// The target is outside 1..max for the chosen period.
  times,

  /// The time window ends before it starts.
  timeWindow,

  /// The range ends before it starts.
  dateRange,
}

/// How far the form has got.
enum HabitFormStatus {
  /// The user is filling it in.
  editing,

  /// A write is in flight.
  saving,

  /// Saved; the screen should close.
  saved,

  /// Archived; the screen should close.
  archived,

  /// A write failed. The form stays open with the values intact.
  failure,
}

/// Everything the habit form holds.
///
/// One flat class rather than a union: the form is a single screen whose fields
/// are all live at once, and modelling that as states would mean rebuilding the
/// whole thing on every keystroke.
final class HabitFormState extends Equatable {
  /// Full constructor. Prefer the two named factories.
  const HabitFormState({
    required this.name,
    required this.category,
    required this.colorSlot,
    required this.scheduleMode,
    required this.weekdays,
    required this.times,
    required this.period,
    required this.rangeStart,
    required this.today,
    this.original,
    this.timeWindow,
    this.rangeEnd,
    this.status = HabitFormStatus.editing,
    this.failure,
    this.showErrors = false,
    this.pendingWarning,
  });

  /// A blank form for a new habit.
  ///
  /// Defaults are the commonest answer, so the fastest path to a saved habit is
  /// a name and one tap: daily, starting today, no end, all day.
  factory HabitFormState.create({
    required DateOnly today,
    required HabitColorSlot suggestedColor,
  }) => HabitFormState(
    name: '',
    category: HabitCategory.health,
    colorSlot: suggestedColor,
    scheduleMode: ScheduleMode.weekdays,
    weekdays: Weekday.all,
    times: 3,
    period: SchedulePeriod.week,
    rangeStart: today,
    today: today,
  );

  /// A form filled in from an existing habit.
  ///
  /// The *current* schedule seeds the fields; the history behind it stays on
  /// [original] and is what makes an edit append rather than overwrite.
  factory HabitFormState.edit({required Habit habit, required DateOnly today}) {
    final HabitSchedule schedule = habit.currentSchedule;
    return HabitFormState(
      original: habit,
      name: habit.name,
      category: habit.category,
      colorSlot: habit.colorSlot,
      scheduleMode:
          schedule is TimesPerPeriod
              ? ScheduleMode.timesPerPeriod
              : ScheduleMode.weekdays,
      // The branch the user is *not* on keeps a sensible default, so flipping
      // the toggle never lands on an invalid form.
      weekdays: schedule is SpecificWeekdays ? schedule.days : Weekday.all,
      times: schedule is TimesPerPeriod ? schedule.times : 3,
      period:
          schedule is TimesPerPeriod ? schedule.period : SchedulePeriod.week,
      timeWindow: habit.timeWindow,
      rangeStart: habit.range.start,
      rangeEnd: habit.range.end,
      today: today,
    );
  }

  /// The habit being edited, or `null` when creating one.
  final Habit? original;

  /// Name as typed.
  final String name;

  /// Chosen category.
  final HabitCategory category;

  /// Chosen palette slot.
  final HabitColorSlot colorSlot;

  /// Which schedule branch is showing.
  final ScheduleMode scheduleMode;

  /// Days selected in the weekdays branch.
  final Set<Weekday> weekdays;

  /// Target in the times-per-period branch.
  final int times;

  /// Bucket in the times-per-period branch.
  final SchedulePeriod period;

  /// Daily time window, or `null` for all day.
  final TimeWindow? timeWindow;

  /// First day of the range.
  final DateOnly rangeStart;

  /// Last day of the range, or `null` for open-ended.
  final DateOnly? rangeEnd;

  /// The day the form is being filled on. Fixed at construction so a form left
  /// open past midnight does not silently change what "from tomorrow" means.
  final DateOnly today;

  /// How far the form has got.
  final HabitFormStatus status;

  /// Why the last write failed.
  final Failure? failure;

  /// Whether validation messages are visible.
  ///
  /// False until the first save attempt: flagging an empty name before the user
  /// has typed anything is nagging, not helping.
  final bool showErrors;

  /// Set when saving is paused on the §3.4 warning, waiting for a decision.
  final PeriodReachability? pendingWarning;

  /// Whether this form edits an existing habit.
  bool get isEditing => original != null;

  /// The largest target that makes sense for [period].
  ///
  /// A day can only be completed once — the entry id is `{habitId}_{date}` — so
  /// the ceiling is the number of days in the bucket. February is why the
  /// monthly cap is 28 rather than 31: a target of 30 a month would be
  /// unreachable every February and break the streak on the calendar's account.
  int get maxTimes => switch (period) {
    SchedulePeriod.week => 7,
    SchedulePeriod.month => 28,
    SchedulePeriod.year => 365,
  };

  /// The domain schedule the current fields describe.
  HabitSchedule get schedule => switch (scheduleMode) {
    ScheduleMode.weekdays => SpecificWeekdays(
      weekdays.isEmpty ? Weekday.all : weekdays,
    ),
    ScheduleMode.timesPerPeriod => TimesPerPeriod(
      times: times < 1 ? 1 : times,
      period: period,
    ),
  };

  /// Whether the schedule differs from the one the habit already has.
  ///
  /// Drives both the "from when" notice and whether a new version gets appended
  /// at all — re-saving an unchanged schedule must not litter the history.
  bool get hasScheduleChanged {
    final Habit? habit = original;
    if (habit == null) return true;
    return habit.currentSchedule != schedule;
  }

  /// Every field the user still has to fix.
  Set<HabitFormField> get invalidFields => <HabitFormField>{
    if (name.trim().isEmpty) HabitFormField.name,
    if (scheduleMode == ScheduleMode.weekdays && weekdays.isEmpty)
      HabitFormField.weekdays,
    if (scheduleMode == ScheduleMode.timesPerPeriod &&
        (times < 1 || times > maxTimes))
      HabitFormField.times,
    if (_isTimeWindowInvalid) HabitFormField.timeWindow,
    if (rangeEnd != null && rangeEnd! < rangeStart) HabitFormField.dateRange,
  };

  /// Whether the form can be written as it stands.
  bool get isValid => invalidFields.isEmpty;

  /// A half-set window, which the picker can produce mid-edit.
  bool get _isTimeWindowInvalid {
    final TimeWindow? window = timeWindow;
    return window != null && window.endMinuteOfDay <= window.startMinuteOfDay;
  }

  /// The range the current fields describe.
  DateRange get range => DateRange(start: rangeStart, end: rangeEnd);

  /// Returns a copy with the fields given replaced.
  ///
  /// The `clear*` flags exist because passing `null` cannot be told from
  /// omitting it, and "all day" and "no end date" are real choices rather than
  /// absences.
  HabitFormState copyWith({
    String? name,
    HabitCategory? category,
    HabitColorSlot? colorSlot,
    ScheduleMode? scheduleMode,
    Set<Weekday>? weekdays,
    int? times,
    SchedulePeriod? period,
    TimeWindow? timeWindow,
    bool clearTimeWindow = false,
    DateOnly? rangeStart,
    DateOnly? rangeEnd,
    bool clearRangeEnd = false,
    HabitFormStatus? status,
    Failure? failure,
    bool clearFailure = false,
    bool? showErrors,
    PeriodReachability? pendingWarning,
    bool clearPendingWarning = false,
  }) => HabitFormState(
    original: original,
    name: name ?? this.name,
    category: category ?? this.category,
    colorSlot: colorSlot ?? this.colorSlot,
    scheduleMode: scheduleMode ?? this.scheduleMode,
    weekdays: weekdays ?? this.weekdays,
    times: times ?? this.times,
    period: period ?? this.period,
    timeWindow: clearTimeWindow ? null : (timeWindow ?? this.timeWindow),
    rangeStart: rangeStart ?? this.rangeStart,
    rangeEnd: clearRangeEnd ? null : (rangeEnd ?? this.rangeEnd),
    today: today,
    status: status ?? this.status,
    failure: clearFailure ? null : (failure ?? this.failure),
    showErrors: showErrors ?? this.showErrors,
    pendingWarning:
        clearPendingWarning ? null : (pendingWarning ?? this.pendingWarning),
  );

  @override
  List<Object?> get props => <Object?>[
    original,
    name,
    category,
    colorSlot,
    scheduleMode,
    weekdays.map((Weekday day) => day.isoValue).toList()..sort(),
    times,
    period,
    timeWindow,
    rangeStart,
    rangeEnd,
    today,
    status,
    failure,
    showErrors,
    pendingWarning,
  ];
}
