import 'package:equatable/equatable.dart';

import 'date_only.dart';
import 'date_period.dart';
import 'date_range.dart';
import 'habit_category.dart';
import 'habit_color_slot.dart';
import 'habit_schedule.dart';
import 'schedule_version.dart';
import 'time_window.dart';

/// A goal the user tracks — the "meta" of this app.
///
/// The one thing to internalize: **a habit has no single schedule field.** It
/// owns an ordered history of [ScheduleVersion]s and everything reads it
/// through [scheduleOn], so that changing the rules today cannot rewrite what
/// yesterday was judged by (`ARCHITECTURE.md` §3.4). Nothing outside this class
/// should walk [scheduleHistory] by hand.
final class Habit extends Equatable {
  /// [scheduleHistory] must be non-empty and strictly ascending by
  /// `effectiveFrom`; both are thrown on rather than repaired, because a
  /// silently reordered history would answer [scheduleOn] with the wrong rules
  /// and quietly corrupt streaks.
  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.colorSlot,
    required List<ScheduleVersion> scheduleHistory,
    required this.range,
    required this.createdAt,
    required this.updatedAt,
    this.timeWindow,
    this.isArchived = false,
  }) : scheduleHistory = List<ScheduleVersion>.unmodifiable(scheduleHistory) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    if (scheduleHistory.isEmpty) {
      throw ArgumentError.value(
        scheduleHistory,
        'scheduleHistory',
        'must hold at least one version',
      );
    }
    for (int i = 1; i < scheduleHistory.length; i++) {
      if (scheduleHistory[i].effectiveFrom <=
          scheduleHistory[i - 1].effectiveFrom) {
        throw ArgumentError.value(
          scheduleHistory,
          'scheduleHistory',
          'must be strictly ascending by effectiveFrom',
        );
      }
    }
  }

  /// Builds a brand-new habit with a single schedule version starting on the
  /// first day of its range.
  ///
  /// [id] comes from the caller — uuid generation is a client concern and would
  /// otherwise pull a package into the domain for no gain.
  factory Habit.create({
    required String id,
    required String name,
    required HabitCategory category,
    required HabitColorSlot colorSlot,
    required HabitSchedule schedule,
    required DateRange range,
    required DateTime createdAt,
    TimeWindow? timeWindow,
  }) => Habit(
    id: id,
    name: name,
    category: category,
    colorSlot: colorSlot,
    scheduleHistory: <ScheduleVersion>[
      ScheduleVersion(schedule: schedule, effectiveFrom: range.start),
    ],
    range: range,
    createdAt: createdAt,
    updatedAt: createdAt,
    timeWindow: timeWindow,
  );

  /// Client-generated uuid. Generated locally so a habit can be created with no
  /// network and still keep its identity once it syncs.
  final String id;

  /// What the user calls this goal.
  final String name;

  /// The area of life it belongs to, used for grouping in the reports.
  final HabitCategory category;

  /// Palette slot, not a resolved color — see `HabitColorSlot`.
  final HabitColorSlot colorSlot;

  /// Every schedule this habit has ever had, oldest first, unmodifiable.
  ///
  /// Read it through [scheduleOn]; the raw list is exposed only for
  /// persistence and for the form's "this change applies from…" notice.
  final List<ScheduleVersion> scheduleHistory;

  /// When the habit was due to run, from and optionally until.
  final DateRange range;

  /// The slot of the day it should happen in; `null` means all day. Never
  /// affects streaks.
  final TimeWindow? timeWindow;

  /// Creation instant, UTC.
  final DateTime createdAt;

  /// Last modification instant, UTC.
  final DateTime updatedAt;

  /// Archived habits leave the main list but keep their history.
  ///
  /// There is no hard delete: entries reference the habit, and dropping it
  /// would tear a hole in the year heatmap and every past report.
  final bool isArchived;

  /// The schedule in force on [date].
  ///
  /// Dates before the first version fall back to it. That only happens if the
  /// range start was moved earlier after the fact, and answering with the
  /// oldest known rules beats throwing at the caller mid-calculation.
  HabitSchedule scheduleOn(DateOnly date) {
    ScheduleVersion inForce = scheduleHistory.first;
    for (final ScheduleVersion version in scheduleHistory) {
      if (version.effectiveFrom > date) break;
      inForce = version;
    }
    return inForce.schedule;
  }

  /// The schedule the habit runs on right now — the newest version.
  HabitSchedule get currentSchedule => scheduleHistory.last.schedule;

  /// Every version that was in force at any point between [from] and [to],
  /// both inclusive.
  ///
  /// A window can span more than one version, which is exactly what the streak
  /// engine needs to know when it judges a whole period.
  List<ScheduleVersion> versionsCovering(DateOnly from, DateOnly to) {
    final List<ScheduleVersion> covering = <ScheduleVersion>[];
    for (int i = 0; i < scheduleHistory.length; i++) {
      final ScheduleVersion version = scheduleHistory[i];
      // The first version also covers everything before its own start, per the
      // fallback documented on `scheduleOn`.
      if (i > 0 && version.effectiveFrom > to) continue;
      final bool isLast = i == scheduleHistory.length - 1;
      if (!isLast) {
        final DateOnly validUntil = scheduleHistory[i + 1].effectiveFrom
            .addDays(-1);
        if (validUntil < from) continue;
      }
      covering.add(version);
    }
    return covering;
  }

  /// How many completions [period] has to be judged against.
  ///
  /// **The highest `times` in force at any point during the period**, not the
  /// current one (`ARCHITECTURE.md` §3.4). That single rule handles both
  /// directions of a mid-period change: raising the goal on Wednesday makes the
  /// whole week ask for the new number, and lowering it leaves the week at the
  /// old one — which it must, or the entries already written would become
  /// retroactively illegal under the no-over-completion rule (§3.5).
  ///
  /// Returns 0 when no `TimesPerPeriod` version of this period's unit was ever
  /// in force during it, i.e. the period is not a mode-B period at all.
  int targetForPeriod(DatePeriod period) {
    int target = 0;
    for (final ScheduleVersion version in versionsCovering(
      period.start,
      period.end,
    )) {
      final HabitSchedule schedule = version.schedule;
      if (schedule is TimesPerPeriod &&
          schedule.period == period.unit &&
          schedule.times > target) {
        target = schedule.times;
      }
    }
    return target;
  }

  /// Whether the habit is live on [date] — inside its range and not archived.
  bool isActiveOn(DateOnly date) => !isArchived && range.contains(date);

  /// Returns a copy with a new schedule version appended.
  ///
  /// Appending is the only way to change a schedule. An edit made on a day that
  /// already has a version replaces that version instead of stacking a second
  /// one, so editing twice in a morning does not litter the history.
  ///
  /// Throws [ArgumentError] when [version] predates the newest one: back-dating
  /// a change would rewrite days that were already judged.
  Habit appendScheduleVersion(ScheduleVersion version, {DateTime? updatedAt}) {
    final List<ScheduleVersion> history = List<ScheduleVersion>.of(
      scheduleHistory,
    );
    final ScheduleVersion newest = history.last;
    if (version.effectiveFrom == newest.effectiveFrom) {
      history[history.length - 1] = version;
    } else if (version.effectiveFrom > newest.effectiveFrom) {
      history.add(version);
    } else {
      throw ArgumentError.value(
        version.effectiveFrom,
        'version.effectiveFrom',
        'must not predate the newest version (${newest.effectiveFrom})',
      );
    }
    return copyWith(
      scheduleHistory: history,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }

  /// Returns a copy with the fields given replaced.
  ///
  /// [clearTimeWindow] is needed because passing `timeWindow: null` cannot be
  /// distinguished from omitting it, and moving a habit back to "all day" is a
  /// real edit.
  Habit copyWith({
    String? name,
    HabitCategory? category,
    HabitColorSlot? colorSlot,
    List<ScheduleVersion>? scheduleHistory,
    DateRange? range,
    TimeWindow? timeWindow,
    bool clearTimeWindow = false,
    DateTime? updatedAt,
    bool? isArchived,
  }) => Habit(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    colorSlot: colorSlot ?? this.colorSlot,
    scheduleHistory: scheduleHistory ?? this.scheduleHistory,
    range: range ?? this.range,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    timeWindow: clearTimeWindow ? null : (timeWindow ?? this.timeWindow),
    isArchived: isArchived ?? this.isArchived,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    category,
    colorSlot,
    scheduleHistory,
    range,
    timeWindow,
    createdAt,
    updatedAt,
    isArchived,
  ];
}
