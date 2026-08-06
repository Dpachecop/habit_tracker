import 'package:equatable/equatable.dart';

import 'date_only.dart';
import 'habit_schedule.dart';

/// A schedule together with the day it started applying.
///
/// Editing a habit's schedule appends one of these; it never overwrites the
/// previous one. A 40-day streak earned under "Monday to Friday" has to survive
/// the switch to "3 times a week", and it only can if the days before the
/// change are still judged by the rules that were actually in force then
/// (`ARCHITECTURE.md` §3.4).
final class ScheduleVersion extends Equatable {
  /// [effectiveFrom] is inclusive: the schedule applies on that day already.
  const ScheduleVersion({required this.schedule, required this.effectiveFrom});

  /// The rules this version puts in place.
  final HabitSchedule schedule;

  /// First day this version applies, inclusive. It runs until the next
  /// version's [effectiveFrom], or forever if it is the last one.
  final DateOnly effectiveFrom;

  /// Returns a copy with the fields given replaced.
  ScheduleVersion copyWith({
    HabitSchedule? schedule,
    DateOnly? effectiveFrom,
  }) => ScheduleVersion(
    schedule: schedule ?? this.schedule,
    effectiveFrom: effectiveFrom ?? this.effectiveFrom,
  );

  @override
  List<Object?> get props => <Object?>[schedule, effectiveFrom];
}
