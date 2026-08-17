import 'package:intl/intl.dart';

import '../../domain/entities/habit_schedule.dart';
import '../../domain/entities/weekday.dart';
import '../../l10n/generated/app_localizations.dart';

/// Turns a [HabitSchedule] into the line that sits under a habit's name.
///
/// The two modes get **different shapes of sentence**, and that is the whole
/// point rather than an inconsistency. "Twice a week" and "Mon and Thu" are not
/// the same goal in this app: in the first the user chooses which days, in the
/// second they do not and the check will not even appear on a Tuesday
/// (`ARCHITECTURE.md` §3.5). A card that blurred them would be lying about what
/// the user committed to.
extension ScheduleLabels on AppLocalizations {
  /// The human-readable description of [schedule].
  String labelForSchedule(HabitSchedule schedule) => switch (schedule) {
    // All seven days reads as "Daily" — the domain has no separate daily mode
    // and this is where that decision becomes visible to the user.
    final SpecificWeekdays weekdays when weekdays.isDaily => scheduleDaily,
    final SpecificWeekdays weekdays => _weekdayList(weekdays.days),
    final TimesPerPeriod times => switch (times.period) {
      SchedulePeriod.week => scheduleTimesPerWeek(times.times),
      SchedulePeriod.month => scheduleTimesPerMonth(times.times),
      SchedulePeriod.year => scheduleTimesPerYear(times.times),
    },
  };

  /// Abbreviated day names in ISO order, e.g. "Mon, Wed, Sat".
  ///
  /// Names come from `intl` rather than the `.arb` files: the abbreviations for
  /// every locale are already in the ICU data, and duplicating fourteen of them
  /// by hand would be fourteen chances to get one wrong.
  String _weekdayList(Set<Weekday> days) {
    final List<Weekday> ordered =
        days.toList()
          ..sort((Weekday a, Weekday b) => a.isoValue.compareTo(b.isoValue));
    final DateFormat format = DateFormat.E(localeName);
    return ordered
        .map((Weekday day) => _capitalize(format.format(_sampleDate(day))))
        .join(', ');
  }

  /// A real date that falls on [day], so `intl` can name it.
  ///
  /// 2026-08-03 is a Monday, so offsetting by the ISO number lands on each day
  /// of that week. Any Monday would do; this one is the anchor the tests use.
  DateTime _sampleDate(Weekday day) => DateTime(2026, 8, 2 + day.isoValue);

  /// Upper-cases the first letter.
  ///
  /// Spanish abbreviations come back lower-cased from ICU ("lun"), which reads
  /// as a typo next to a title-cased habit name. English is already capitalized,
  /// so this is a no-op there.
  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
