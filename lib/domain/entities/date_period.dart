import 'package:equatable/equatable.dart';

import 'date_only.dart';
import 'habit_schedule.dart';

/// One concrete calendar bucket — the ISO week of 2026-08-06, August 2026, or
/// the year 2026 — with both ends inclusive.
///
/// [TimesPerPeriod] says *which kind* of bucket a habit counts in;
/// this says *which one*. Keeping the boundary maths in a value object stops
/// the streak engine and the completion policy from each rolling their own
/// "start of week", which is exactly the kind of duplication that produces two
/// different answers for the same Sunday.
final class DatePeriod extends Equatable {
  /// Both ends inclusive. Private because the only sane way to build a bucket
  /// is [DatePeriod.containing] — an arbitrary start/end pair would not be a
  /// calendar period at all.
  const DatePeriod._(this.unit, this.start, this.end);

  /// The bucket of the given [unit] that [date] falls in.
  factory DatePeriod.containing(DateOnly date, SchedulePeriod unit) {
    switch (unit) {
      case SchedulePeriod.week:
        // ISO weeks start on Monday, so back up by however many days we are
        // past it.
        final DateOnly start = date.addDays(-(date.weekday.isoValue - 1));
        return DatePeriod._(unit, start, start.addDays(6));
      case SchedulePeriod.month:
        // Day zero of the next month is the last day of this one, which saves
        // a leap-year table.
        return DatePeriod._(
          unit,
          DateOnly(date.year, date.month, 1),
          DateOnly(date.year, date.month + 1, 0),
        );
      case SchedulePeriod.year:
        return DatePeriod._(
          unit,
          DateOnly(date.year, 1, 1),
          DateOnly(date.year, 12, 31),
        );
    }
  }

  /// The kind of bucket this is.
  final SchedulePeriod unit;

  /// First day of the bucket, inclusive.
  final DateOnly start;

  /// Last day of the bucket, inclusive.
  final DateOnly end;

  /// Whether [date] falls inside the bucket.
  bool contains(DateOnly date) => date >= start && date <= end;

  /// The bucket immediately before this one.
  ///
  /// Derived from the day before [start] rather than by subtracting a fixed
  /// length, so month buckets of different lengths and the week that straddles
  /// New Year's Eve all come out right.
  DatePeriod get previous => DatePeriod.containing(start.addDays(-1), unit);

  /// How many days the bucket spans.
  int get lengthInDays => start.daysUntil(end) + 1;

  @override
  List<Object?> get props => <Object?>[unit, start, end];

  @override
  String toString() => '${unit.name}[$start..$end]';
}
