import 'package:equatable/equatable.dart';

import 'weekday.dart';

/// A calendar day with no time and no zone attached.
///
/// Every streak rule in this app is about *days*, not instants, and mixing the
/// two is how streak engines corrupt themselves: a `DateTime` carries a clock
/// and an offset, so two check-ins on the same day stop being equal the moment
/// the user crosses a timezone or the country moves its clocks. `HabitEntry`
/// keeps the audit instant in UTC and does all of its arithmetic here
/// (`ARCHITECTURE.md` §3.3).
///
/// Day arithmetic goes through `DateTime`'s component constructor, never
/// through `Duration`. Adding `Duration(days: 1)` across a DST change lands on
/// 23:00 of the same day; adding one to the day field cannot.
final class DateOnly extends Equatable implements Comparable<DateOnly> {
  /// Builds a date, normalizing out-of-range components the way `DateTime`
  /// does — `DateOnly(2026, 1, 32)` is 2026-02-01.
  ///
  /// That is deliberate rather than tolerated: it is what makes
  /// `DateOnly(year, month, day + 7)` a correct way to move a week forward.
  factory DateOnly(int year, int month, int day) {
    final DateTime normalized = DateTime(year, month, day);
    return DateOnly._(normalized.year, normalized.month, normalized.day);
  }

  /// The already-normalized constructor. Private so no caller can build a
  /// nonexistent date such as February 30th and break equality against the
  /// normalized March 2nd that means the same thing.
  const DateOnly._(this.year, this.month, this.day);

  /// Takes the calendar day a moment falls on **in local time**.
  ///
  /// Local, not UTC: a check-in at 23:30 belongs to the day the user
  /// experienced, not to tomorrow in London.
  factory DateOnly.fromDateTime(DateTime moment) {
    final DateTime local = moment.toLocal();
    return DateOnly._(local.year, local.month, local.day);
  }

  /// Today's local date. [now] exists so tests and the calculator can be driven
  /// by a fixed clock instead of the wall clock.
  factory DateOnly.today([DateTime? now]) =>
      DateOnly.fromDateTime(now ?? DateTime.now());

  /// Parses the `yyyy-MM-dd` form written by [toIso8601].
  ///
  /// This is the format embedded in the entry document id, so parsing has to
  /// round-trip exactly. Throws [FormatException] on anything else.
  factory DateOnly.parse(String value) {
    final RegExp pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final RegExpMatch? match = pattern.firstMatch(value);
    if (match == null) {
      throw FormatException('Expected a yyyy-MM-dd date', value);
    }
    return DateOnly(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  /// The calendar year.
  final int year;

  /// The month, 1 through 12.
  final int month;

  /// The day of the month, 1 through 31.
  final int day;

  /// This date as local midnight, for the rare caller that needs a `DateTime`.
  DateTime toDateTime() => DateTime(year, month, day);

  /// This date as a UTC instant.
  ///
  /// Used internally for day counting: UTC days are always 24 hours long, so
  /// differences taken here are immune to daylight saving.
  DateTime toUtcDateTime() => DateTime.utc(year, month, day);

  /// The weekday this date falls on.
  Weekday get weekday => Weekday.fromIso(toUtcDateTime().weekday);

  /// Returns the date [days] later, or earlier when [days] is negative.
  DateOnly addDays(int days) => DateOnly(year, month, day + days);

  /// How many days separate this date from [other]; negative when [other] is
  /// in the past.
  int daysUntil(DateOnly other) =>
      other.toUtcDateTime().difference(toUtcDateTime()).inDays;

  /// The `yyyy-MM-dd` form. Part of the entry document id, so it is stable
  /// storage format and not just a display concern.
  String toIso8601() {
    final String mm = month.toString().padLeft(2, '0');
    final String dd = day.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  /// Whether this date is earlier than [other].
  bool operator <(DateOnly other) => compareTo(other) < 0;

  /// Whether this date is earlier than or the same as [other].
  bool operator <=(DateOnly other) => compareTo(other) <= 0;

  /// Whether this date is later than [other].
  bool operator >(DateOnly other) => compareTo(other) > 0;

  /// Whether this date is later than or the same as [other].
  bool operator >=(DateOnly other) => compareTo(other) >= 0;

  @override
  int compareTo(DateOnly other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  List<Object?> get props => <Object?>[year, month, day];

  @override
  String toString() => toIso8601();
}
