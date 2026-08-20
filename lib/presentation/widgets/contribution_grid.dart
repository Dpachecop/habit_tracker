import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme/app_dimens.dart';
import '../../domain/entities/date_only.dart';
import '../../domain/entities/weekday.dart';
import '../../domain/services/habit_day_status.dart';
import '../l10n/l10n_extensions.dart';

/// The GitHub-style contribution grid on the habit detail screen.
///
/// Seven rows, one per weekday, and one column per ISO week. Unlike the compact
/// strip on the habit card — four rows in reading order, where a column means
/// nothing — this **is** a calendar, so it can be labelled and read by pattern:
/// a sparse Tuesday row says something a flat run of days cannot.
///
/// How many weeks are shown is decided by the width available. The owner chose
/// "as many months as fit, no scrolling" (2026-08-20) over a scrollable year:
/// no hidden gesture, at the cost of not seeing the whole year at once.
class ContributionGrid extends StatelessWidget {
  /// [completedDays] and the schedule come from the habit; the grid asks the
  /// domain for each day's status itself only through [statusOf].
  const ContributionGrid({
    required this.today,
    required this.statusOf,
    required this.accent,
    super.key,
  });

  /// The last day the grid shows.
  final DateOnly today;

  /// What a given day meant. Supplied rather than computed so the rule stays in
  /// the domain and this widget stays a painter.
  final DayStatus Function(DateOnly date) statusOf;

  /// The habit's color, for completed days.
  final Color accent;

  /// Side of one cell.
  static const double cellSize = 13;

  /// Gap between cells.
  static const double cellGap = 4;

  /// Width reserved for the Mon/Wed/Fri labels down the left.
  static const double labelWidth = 34;

  /// Height reserved for the month labels along the top.
  static const double monthLabelHeight = 18;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gridWidth = constraints.maxWidth - labelWidth;
        final int weeks = _weeksIn(gridWidth);
        if (weeks <= 0) return const SizedBox.shrink();

        // The grid ends on the Sunday of today's week, so the last column is a
        // whole week and today sits in it. Starting from a Monday is what makes
        // every row a single weekday.
        final DateOnly lastSunday = today.addDays(7 - today.weekday.isoValue);
        final DateOnly firstMonday = lastSunday.addDays(-(weeks * 7 - 1));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _MonthLabels(firstMonday: firstMonday, weeks: weeks),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _WeekdayLabels(),
                Expanded(
                  child: _Cells(
                    firstMonday: firstMonday,
                    weeks: weeks,
                    statusOf: statusOf,
                    accent: accent,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// How many whole week columns fit in [width].
  static int _weeksIn(double width) {
    if (!width.isFinite || width <= 0) return 0;
    return ((width + cellGap) / (cellSize + cellGap)).floor();
  }
}

/// Month names above the columns they start in.
///
/// Positioned rather than evenly spread: a label has to sit over the first week
/// of its month or it points at the wrong data. Months too narrow to fit their
/// own name are skipped instead of overlapping the next one.
class _MonthLabels extends StatelessWidget {
  /// Creates the strip of labels.
  const _MonthLabels({required this.firstMonday, required this.weeks});

  /// Monday of the leftmost column.
  final DateOnly firstMonday;

  /// How many columns there are.
  final int weeks;

  /// Roughly how much room a three-letter month name needs.
  static const double _minLabelWidth = 30;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateFormat format = DateFormat.MMM(
      Localizations.localeOf(context).toLanguageTag(),
    );
    const double columnWidth =
        ContributionGrid.cellSize + ContributionGrid.cellGap;

    final List<Widget> labels = <Widget>[];
    int? lastMonth;
    double lastLabelX = -_minLabelWidth;

    for (int week = 0; week < weeks; week++) {
      final DateOnly monday = firstMonday.addDays(week * 7);
      if (monday.month == lastMonth) continue;
      lastMonth = monday.month;

      final double x = week * columnWidth;
      // Skip a label that would collide with the previous one; a squeezed month
      // is better dropped than printed on top of its neighbour.
      if (x - lastLabelX < _minLabelWidth) continue;
      lastLabelX = x;

      labels.add(
        Positioned(
          left: x,
          child: Text(
            _capitalize(format.format(monday.toDateTime())),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: ContributionGrid.labelWidth),
      child: SizedBox(
        height: ContributionGrid.monthLabelHeight,
        child: Stack(children: labels),
      ),
    );
  }

  /// Upper-cases the first letter; Spanish month abbreviations arrive
  /// lower-cased from ICU.
  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

/// Mon / Wed / Fri down the left edge.
///
/// Every other row, the way GitHub does it: seven labels at this cell size
/// would not fit and three are enough to orient the eye.
class _WeekdayLabels extends StatelessWidget {
  /// Creates the column of labels.
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateFormat format = DateFormat.E(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return SizedBox(
      width: ContributionGrid.labelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final Weekday day in Weekday.values)
            SizedBox(
              height: ContributionGrid.cellSize + ContributionGrid.cellGap,
              child:
                  day.isoValue.isOdd
                      ? Text(
                        // 2026-08-03 is a Monday, so the ISO number indexes that
                        // week. Capitalized like every other day name in the
                        // app; ICU hands Spanish back lower-cased.
                        _capitalize(
                          format.format(DateTime(2026, 8, 2 + day.isoValue)),
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  /// Upper-cases the first letter.
  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

/// The cells themselves, seven rows by [weeks] columns.
class _Cells extends StatelessWidget {
  /// Creates the grid body.
  const _Cells({
    required this.firstMonday,
    required this.weeks,
    required this.statusOf,
    required this.accent,
  });

  /// Monday of the leftmost column.
  final DateOnly firstMonday;

  /// Column count.
  final int weeks;

  /// What a given day meant.
  final DayStatus Function(DateOnly date) statusOf;

  /// The habit's color.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    int completed = 0;

    final List<Widget> rows = <Widget>[];
    for (int row = 0; row < Weekday.values.length; row++) {
      final List<Widget> cells = <Widget>[];
      for (int week = 0; week < weeks; week++) {
        final DateOnly date = firstMonday.addDays(week * 7 + row);
        final DayStatus status = statusOf(date);
        if (status == DayStatus.completed) completed++;

        cells.add(
          Padding(
            padding: EdgeInsets.only(
              right: week == weeks - 1 ? 0 : ContributionGrid.cellGap,
            ),
            child: Container(
              width: ContributionGrid.cellSize,
              height: ContributionGrid.cellSize,
              decoration: BoxDecoration(
                // The same three tones as the card's strip, for the same
                // reasons — see HabitDayStatuses.
                color: switch (status) {
                  DayStatus.completed => accent,
                  DayStatus.missed => scheme.onSurfaceVariant.withValues(
                    alpha: 0.28,
                  ),
                  DayStatus.notDue => scheme.surfaceContainer,
                },
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        );
      }
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom:
                row == Weekday.values.length - 1 ? 0 : ContributionGrid.cellGap,
          ),
          child: Row(children: cells),
        ),
      );
    }

    return Semantics(
      // One label for the whole grid. Three hundred unlabelled cells would be
      // noise to a screen reader, not information.
      label: context.l10n.heatmapSummary(weeks * 7, completed),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}
