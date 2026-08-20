import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme/app_dimens.dart';
import '../../domain/entities/date_only.dart';
import '../../domain/entities/date_period.dart';
import '../../domain/entities/habit_schedule.dart';
import '../../domain/entities/weekday.dart';
import '../../domain/services/habit_day_status.dart';

/// One month, read-only, with today ringed and completed days dotted.
///
/// Deliberately not tappable — the owner's call on 2026-08-20. The domain would
/// allow checking a past day off (only the future is refused), so making the
/// cells interactive is an additive change if it is ever wanted; nothing here
/// would have to be undone first.
///
/// Weeks start on Monday, matching every other date calculation in the app.
class MonthCalendar extends StatelessWidget {
  /// [month] can be any day inside the month to draw.
  const MonthCalendar({
    required this.month,
    required this.today,
    required this.statusOf,
    required this.accent,
    super.key,
  });

  /// Any day of the month being shown.
  final DateOnly month;

  /// Today, for the ring.
  final DateOnly today;

  /// What a given day meant.
  final DayStatus Function(DateOnly date) statusOf;

  /// The habit's color, for the completion dot.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final DatePeriod period = DatePeriod.containing(
      month,
      SchedulePeriod.month,
    );
    // Back up to the Monday on or before the 1st, so the first row is a whole
    // week and every column is one weekday.
    final DateOnly gridStart = period.start.addDays(
      -(period.start.weekday.isoValue - 1),
    );
    // Six rows always. Five would be enough for most months, but a grid that
    // changes height as you page months makes the whole sheet jump.
    const int rowCount = 6;

    return Column(
      children: <Widget>[
        const _WeekdayHeader(),
        const SizedBox(height: AppSpacing.sm),
        for (int row = 0; row < rowCount; row++)
          Row(
            children: <Widget>[
              for (int column = 0; column < 7; column++)
                Expanded(
                  child: _DayCell(
                    date: gridStart.addDays(row * 7 + column),
                    month: period,
                    today: today,
                    statusOf: statusOf,
                    accent: accent,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Mon…Sun across the top.
class _WeekdayHeader extends StatelessWidget {
  /// Creates the header row.
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateFormat format = DateFormat.E(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Row(
      children: <Widget>[
        for (final Weekday day in Weekday.values)
          Expanded(
            child: Text(
              // 2026-08-03 is a Monday, so the ISO number indexes that week.
              _capitalize(format.format(DateTime(2026, 8, 2 + day.isoValue))),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  /// Upper-cases the first letter, for locales that abbreviate in lower case.
  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

/// A single date in the month grid.
class _DayCell extends StatelessWidget {
  /// Creates the cell.
  const _DayCell({
    required this.date,
    required this.month,
    required this.today,
    required this.statusOf,
    required this.accent,
  });

  /// The date this cell is.
  final DateOnly date;

  /// The month being shown, for telling the spill-over days apart.
  final DatePeriod month;

  /// Today.
  final DateOnly today;

  /// What a given day meant.
  final DayStatus Function(DateOnly date) statusOf;

  /// The habit's color.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final bool isThisMonth = month.contains(date);
    final bool isToday = date == today;
    // Days spilling in from the neighbouring months are shown rather than
    // blanked, so the week rows stay whole, but greyed so they cannot be
    // mistaken for this month's.
    final bool isCompleted =
        isThisMonth && statusOf(date) == DayStatus.completed;

    return SizedBox(
      height: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration:
                isToday
                    ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.primary, width: 2),
                    )
                    : null,
            child: Text(
              '${date.day}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    isThisMonth
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: isToday ? FontWeight.w600 : null,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // A dot rather than a filled cell: the number has to stay readable,
          // and three of the palette's light slots do not carry dark text.
          SizedBox(
            height: 6,
            child:
                isCompleted
                    ? Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    )
                    : null,
          ),
        ],
      ),
    );
  }
}
