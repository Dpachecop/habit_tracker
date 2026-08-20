import 'package:flutter/material.dart';

import '../../config/theme/app_dimens.dart';
import '../../domain/services/habit_day_status.dart';
import '../l10n/l10n_extensions.dart';

/// The strip of day cells at the bottom of a habit card.
///
/// Four rows read left to right, top to bottom, so the last cell is today and
/// the whole strip is simply "the last N days". That shape comes from the
/// owner's design (2026-08-17), chosen over a seven-row GitHub-style grid where
/// a column would be a week: it is more compact and matches the mockups, at the
/// cost of a column meaning nothing. Nothing is labelled here for that reason —
/// labels would imply a structure the grid does not have.
///
/// How many columns fit is a question about width, so the widget answers it
/// rather than the bloc: it is handed a long tail of statuses and shows the last
/// ones that fit.
class HabitHeatmap extends StatelessWidget {
  /// [statuses] runs oldest first and ends today.
  const HabitHeatmap({required this.statuses, required this.accent, super.key});

  /// One status per day, oldest first.
  final List<DayStatus> statuses;

  /// The habit's color, used for completed days.
  final Color accent;

  /// Rows in the grid. From the design.
  static const int rows = 4;

  /// Side of one cell.
  static const double cellSize = 12;

  /// Gap between cells, on both axes.
  static const double cellGap = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = _columnsFor(constraints.maxWidth);
        if (columns == 0) return const SizedBox.shrink();

        final List<DayStatus> visible = _tail(columns * rows);
        final int completed =
            visible
                .where((DayStatus status) => status == DayStatus.completed)
                .length;

        return Semantics(
          // One label for the whole strip. Exposing seventy-six unlabelled
          // cells to a screen reader would be noise, not information.
          label: context.l10n.heatmapSummary(visible.length, completed),
          // Excluded rather than merged: the cells have nothing to say
          // individually.
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int row = 0; row < rows; row++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: row == rows - 1 ? 0 : cellGap,
                  ),
                  child: Row(
                    children: <Widget>[
                      for (int column = 0; column < columns; column++)
                        Padding(
                          padding: EdgeInsets.only(
                            right: column == columns - 1 ? 0 : cellGap,
                          ),
                          child: _Cell(
                            status: visible[row * columns + column],
                            accent: accent,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// How many whole cells fit across [width].
  int _columnsFor(double width) {
    if (!width.isFinite || width <= 0) return 0;
    // n cells need n*cell + (n-1)*gap, which rearranges to this.
    return ((width + cellGap) / (cellSize + cellGap)).floor();
  }

  /// The last [count] statuses, padded at the front if there are fewer.
  ///
  /// Padding with `notDue` rather than clipping the grid keeps the shape
  /// rectangular on a brand-new habit, so the card does not change size as
  /// history accumulates.
  List<DayStatus> _tail(int count) {
    if (statuses.length >= count) {
      return statuses.sublist(statuses.length - count);
    }
    return <DayStatus>[
      ...List<DayStatus>.filled(count - statuses.length, DayStatus.notDue),
      ...statuses,
    ];
  }
}

/// One day.
class _Cell extends StatelessWidget {
  /// Creates the cell.
  const _Cell({required this.status, required this.accent});

  /// What that day meant.
  final DayStatus status;

  /// The habit's color.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    // Three tones for three meanings. A miss is grey rather than a faded
    // version of the habit's color on purpose: a washed-out habit color reads
    // as "partly done", and nothing in this app is partly done.
    final Color color = switch (status) {
      DayStatus.completed => accent,
      DayStatus.missed => scheme.onSurfaceVariant.withValues(alpha: 0.28),
      DayStatus.notDue => scheme.surfaceContainer,
    };

    return Container(
      width: HabitHeatmap.cellSize,
      height: HabitHeatmap.cellSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}
