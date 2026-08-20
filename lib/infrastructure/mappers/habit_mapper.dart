import '../../domain/entities/date_only.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_category.dart';
import '../../domain/entities/habit_color_slot.dart';
import '../../domain/entities/habit_schedule.dart';
import '../../domain/entities/schedule_version.dart';
import '../../domain/entities/time_window.dart';
import '../../domain/entities/weekday.dart';
import '../models/habit_dto.dart';

/// Converts between the stored shape and the domain entity.
///
/// The interesting half is the schedule. `HabitSchedule` is a sealed union, and
/// a document cannot hold a union — so each version is written with a `type`
/// discriminator and read back through a switch that fails loudly on anything
/// unrecognized. That failure is the point: a document written by a newer
/// version of the app must not be silently downgraded into the wrong schedule.
abstract final class HabitMapper {
  /// Key holding the union discriminator inside a schedule version map.
  static const String _typeKey = 'type';

  /// Discriminator for `SpecificWeekdays`.
  static const String _weekdaysType = 'specificWeekdays';

  /// Discriminator for `TimesPerPeriod`.
  static const String _timesType = 'timesPerPeriod';

  /// Builds the entity. Throws [FormatException] on unreadable stored data.
  static Habit toEntity(HabitDto dto) => Habit(
    id: dto.id,
    name: dto.name,
    category: _enumByName(
      HabitCategory.values,
      dto.category,
      'category',
      // Unknown categories are the one case worth absorbing: it is a label,
      // it cannot corrupt a streak, and losing the habit entirely because a
      // future version added "travel" would be a far worse outcome.
      fallback: HabitCategory.other,
    ),
    colorSlot: _enumByName(
      HabitColorSlot.values,
      dto.colorSlot,
      'colorSlot',
      fallback: HabitColorSlot.blue,
    ),
    scheduleHistory: dto.scheduleHistory.map(_versionToEntity).toList(),
    range: DateRange(
      start: DateOnly.parse(dto.rangeStart),
      end: dto.rangeEnd == null ? null : DateOnly.parse(dto.rangeEnd!),
    ),
    timeWindow: _timeWindow(dto),
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
    isArchived: dto.isArchived,
  );

  /// Builds the DTO.
  static HabitDto toDto(Habit habit) => HabitDto(
    id: habit.id,
    name: habit.name,
    category: habit.category.name,
    colorSlot: habit.colorSlot.name,
    scheduleHistory: habit.scheduleHistory.map(_versionToMap).toList(),
    rangeStart: habit.range.start.toIso8601(),
    rangeEnd: habit.range.end?.toIso8601(),
    timeWindowStartMinute: habit.timeWindow?.startMinuteOfDay,
    timeWindowEndMinute: habit.timeWindow?.endMinuteOfDay,
    createdAt: habit.createdAt,
    updatedAt: habit.updatedAt,
    isArchived: habit.isArchived,
  );

  /// Writes one schedule version.
  static Map<String, dynamic> _versionToMap(ScheduleVersion version) {
    final HabitSchedule schedule = version.schedule;
    return <String, dynamic>{
      'effectiveFrom': version.effectiveFrom.toIso8601(),
      ...switch (schedule) {
        final SpecificWeekdays weekdays => <String, dynamic>{
          _typeKey: _weekdaysType,
          // ISO numbers, sorted, so two identical schedules serialize
          // identically and a re-save is not seen as a change.
          'days':
              weekdays.days.map((Weekday day) => day.isoValue).toList()..sort(),
        },
        final TimesPerPeriod times => <String, dynamic>{
          _typeKey: _timesType,
          'times': times.times,
          'period': times.period.name,
        },
      },
    };
  }

  /// Reads one schedule version.
  static ScheduleVersion _versionToEntity(Map<String, dynamic> map) {
    final Object? effectiveFrom = map['effectiveFrom'];
    if (effectiveFrom is! String) {
      throw FormatException('Schedule version without effectiveFrom: $map');
    }

    final Object? type = map[_typeKey];
    final HabitSchedule schedule = switch (type) {
      _weekdaysType => SpecificWeekdays(
        (map['days']! as List<Object?>)
            .map((Object? day) => Weekday.fromIso((day! as num).toInt()))
            .toSet(),
      ),
      _timesType => TimesPerPeriod(
        times: (map['times']! as num).toInt(),
        period: _enumByName(
          SchedulePeriod.values,
          map['period'] as String? ?? '',
          'period',
        ),
      ),
      // No fallback here, unlike the category. Guessing a schedule would
      // silently rewrite what the user committed to, and every streak with it.
      _ => throw FormatException('Unknown schedule type "$type"'),
    };

    return ScheduleVersion(
      schedule: schedule,
      effectiveFrom: DateOnly.parse(effectiveFrom),
    );
  }

  /// Rebuilds the time window, treating a half-written pair as "all day".
  static TimeWindow? _timeWindow(HabitDto dto) {
    final int? start = dto.timeWindowStartMinute;
    final int? end = dto.timeWindowEndMinute;
    if (start == null || end == null) return null;
    return TimeWindow(startMinuteOfDay: start, endMinuteOfDay: end);
  }

  /// Looks an enum value up by its `name`.
  ///
  /// With a [fallback] an unknown value degrades to it; without one it throws.
  /// Which of the two applies is a per-field decision about how much damage a
  /// wrong guess would do.
  static T _enumByName<T extends Enum>(
    List<T> values,
    String name,
    String field, {
    T? fallback,
  }) {
    for (final T value in values) {
      if (value.name == name) return value;
    }
    if (fallback != null) return fallback;
    throw FormatException('Unknown $field "$name"');
  }
}
