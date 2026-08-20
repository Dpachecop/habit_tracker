import 'package:equatable/equatable.dart';

import 'weekday.dart';

/// The calendar bucket a [TimesPerPeriod] goal is counted in.
///
/// Weeks are ISO weeks starting on Monday, months are calendar months, years
/// are calendar years. Buckets are never sliding windows: "3 times a week"
/// resets on Monday, it does not mean "3 in any rolling 7 days".
enum SchedulePeriod {
  /// Monday-to-Sunday ISO week.
  week,

  /// First to last day of a calendar month.
  month,

  /// January 1st to December 31st.
  year,
}

/// How often a habit has to be done.
///
/// A sealed union rather than a bag of nullable fields, because the two modes
/// are structurally different and the streak engine wants exactly two branches
/// (`ARCHITECTURE.md` §3.2). Sealing also means adding a third mode later is a
/// compile error at every place that has to handle it, not a silent fallthrough.
sealed class HabitSchedule extends Equatable {
  /// Const so schedules can be built in `const` contexts and compared cheaply.
  const HabitSchedule();
}

/// Do the habit on named days of the week: Monday, Wednesday, Saturday.
///
/// "Daily" is this case holding all seven days — see [SpecificWeekdays.daily].
/// There is deliberately no third union member for it, or every branch of the
/// engine would have to remember that daily and weekdays mean the same thing.
final class SpecificWeekdays extends HabitSchedule {
  /// Throws [ArgumentError] on an empty set: a habit scheduled on no day at all
  /// can never be completed and would sit in the list as a permanent blank.
  /// Callers validate user input before getting here; reaching this throw means
  /// either a bug or corrupt stored data, and both should be loud.
  SpecificWeekdays(Set<Weekday> days) : days = Set<Weekday>.unmodifiable(days) {
    if (days.isEmpty) {
      throw ArgumentError.value(days, 'days', 'must contain at least one day');
    }
  }

  /// Every day of the week — the way this app expresses a daily habit.
  factory SpecificWeekdays.daily() => SpecificWeekdays(Weekday.all);

  /// The days the habit is due on. Unmodifiable; a schedule is a value.
  final Set<Weekday> days;

  /// Whether the habit is due on [weekday].
  bool includes(Weekday weekday) => days.contains(weekday);

  /// Whether this covers all seven days, i.e. reads as "daily" in the UI.
  bool get isDaily => days.length == Weekday.values.length;

  /// Sorted ISO numbers, so two sets with the same days compare equal
  /// regardless of the order they were inserted in.
  @override
  List<Object?> get props => <Object?>[
    days.map((Weekday day) => day.isoValue).toList()..sort(),
  ];
}

/// Do the habit [times] times per [period], on whichever days suit the user.
///
/// The engine counts completions per calendar bucket; which days they landed on
/// is irrelevant (`ARCHITECTURE.md` §4, mode B).
final class TimesPerPeriod extends HabitSchedule {
  /// Throws [ArgumentError] when [times] is below 1 — a target of zero is not a
  /// goal, and a negative one is corrupt data.
  TimesPerPeriod({required this.times, required this.period}) {
    if (times < 1) {
      throw ArgumentError.value(times, 'times', 'must be at least 1');
    }
  }

  /// How many completions the period asks for.
  ///
  /// This is the target *as configured now*. The target a given period is
  /// actually judged against is the highest value in force during it — that
  /// rule lives on `Habit`, not here, because it needs the version history
  /// (`ARCHITECTURE.md` §3.4).
  final int times;

  /// The calendar bucket the count resets in.
  final SchedulePeriod period;

  @override
  List<Object?> get props => <Object?>[times, period];
}
