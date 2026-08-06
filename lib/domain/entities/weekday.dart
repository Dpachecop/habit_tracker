/// A day of the week, numbered as ISO 8601 does it — Monday is 1, Sunday is 7.
///
/// The app anchors weeks to Monday (see `ARCHITECTURE.md` §3.3), so the ISO
/// numbering is the one the whole domain speaks. Declaration order matches it,
/// which lets `Weekday.values[iso - 1]` stay a valid lookup.
enum Weekday {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);

  /// Builds a weekday from its ISO number.
  const Weekday(this.isoValue);

  /// The ISO 8601 number of this day, 1 (Monday) through 7 (Sunday).
  ///
  /// It matches `DateTime.weekday`, which is what makes the conversion in
  /// [fromIso] a plain index lookup instead of a switch.
  final int isoValue;

  /// Returns the weekday for an ISO number, as produced by `DateTime.weekday`.
  ///
  /// Throws [RangeError] outside 1..7 rather than clamping: an out-of-range
  /// value can only come from corrupt stored data, and silently mapping it to
  /// Monday would quietly shift a habit's schedule.
  static Weekday fromIso(int isoValue) {
    if (isoValue < 1 || isoValue > 7) {
      throw RangeError.range(isoValue, 1, 7, 'isoValue');
    }
    return Weekday.values[isoValue - 1];
  }

  /// Every weekday, in ISO order.
  ///
  /// A "daily" habit is `SpecificWeekdays` over this set — the domain has no
  /// separate daily mode (`ARCHITECTURE.md` §3.2).
  static Set<Weekday> get all => Weekday.values.toSet();
}
