import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/config/theme/app_colors.dart';
import 'package:habit_tracker/domain/services/habit_day_status.dart';
import 'package:habit_tracker/presentation/widgets/habit_heatmap.dart';

import '../../support/pump_app.dart';

void main() {
  const Color accent = Color(0xFF2A78D6);

  /// Mounts the strip inside a box of a known width.
  ///
  /// The width is what decides the column count, so it has to be pinned rather
  /// than left to whatever the test surface happens to be.
  Future<void> pumpHeatmap(
    WidgetTester tester,
    List<DayStatus> statuses, {
    double width = 300,
  }) async {
    await tester.pumpApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: HabitHeatmap(statuses: statuses, accent: accent),
        ),
      ),
    );
  }

  /// Every cell the strip drew, in reading order.
  List<Color?> cellColors(WidgetTester tester) =>
      tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(HabitHeatmap),
              matching: find.byType(Container),
            ),
          )
          .map((Container cell) => (cell.decoration! as BoxDecoration).color)
          .toList();

  /// How many columns fit in [width], by the widget's own arithmetic.
  int columnsIn(double width) =>
      ((width + HabitHeatmap.cellGap) /
              (HabitHeatmap.cellSize + HabitHeatmap.cellGap))
          .floor();

  testWidgets('fills four rows of whatever fits across the width', (
    tester,
  ) async {
    const double width = 300;
    final int columns = columnsIn(width);

    await pumpHeatmap(
      tester,
      List<DayStatus>.filled(400, DayStatus.notDue),
      width: width,
    );

    expect(cellColors(tester), hasLength(columns * HabitHeatmap.rows));
  });

  testWidgets('a narrower card simply shows fewer days', (tester) async {
    await pumpHeatmap(
      tester,
      List<DayStatus>.filled(400, DayStatus.notDue),
      width: 120,
    );

    expect(cellColors(tester), hasLength(columnsIn(120) * HabitHeatmap.rows));
  });

  testWidgets('shows the most recent days, not the oldest', (tester) async {
    // The tail matters: a strip that showed the first N days of a long history
    // would freeze in the past and never change again.
    const double width = 300;
    final int visible = columnsIn(width) * HabitHeatmap.rows;
    final List<DayStatus> statuses = <DayStatus>[
      ...List<DayStatus>.filled(500, DayStatus.missed),
      ...List<DayStatus>.filled(visible, DayStatus.completed),
    ];

    await pumpHeatmap(tester, statuses, width: width);

    expect(cellColors(tester).every((Color? color) => color == accent), isTrue);
  });

  testWidgets('the last cell is today', (tester) async {
    const double width = 300;
    final int visible = columnsIn(width) * HabitHeatmap.rows;
    final List<DayStatus> statuses = <DayStatus>[
      ...List<DayStatus>.filled(visible - 1, DayStatus.notDue),
      DayStatus.completed,
    ];

    await pumpHeatmap(tester, statuses, width: width);

    expect(cellColors(tester).last, accent);
  });

  testWidgets('keeps its shape on a habit with almost no history', (
    tester,
  ) async {
    // Padded at the front rather than drawn short, so a card does not change
    // height as history accumulates.
    const double width = 300;

    await pumpHeatmap(tester, <DayStatus>[
      DayStatus.completed,
      DayStatus.completed,
    ], width: width);

    expect(cellColors(tester), hasLength(columnsIn(width) * HabitHeatmap.rows));
    expect(cellColors(tester).last, accent);
  });

  testWidgets('gives the three statuses three different tones', (tester) async {
    await pumpHeatmap(tester, <DayStatus>[
      DayStatus.completed,
      DayStatus.missed,
      DayStatus.notDue,
    ], width: 60);

    final Set<Color?> tones = cellColors(tester).toSet();
    // A miss must not look like a day that was never asked for — that is the
    // whole reason DayStatus has three values.
    expect(tones, contains(accent));
    expect(tones, contains(AppColors.lightSurfaceContainer));
    expect(tones.length, greaterThanOrEqualTo(3));
  });

  testWidgets('a completed day is painted in the habit colour', (tester) async {
    await pumpHeatmap(tester, <DayStatus>[DayStatus.completed], width: 20);

    expect(cellColors(tester), contains(accent));
  });

  testWidgets('speaks as one label, not seventy-six', (tester) async {
    const double width = 300;
    final int visible = columnsIn(width) * HabitHeatmap.rows;

    await pumpHeatmap(tester, <DayStatus>[
      ...List<DayStatus>.filled(visible - 3, DayStatus.notDue),
      DayStatus.completed,
      DayStatus.completed,
      DayStatus.completed,
    ], width: width);

    expect(
      find.bySemanticsLabel('Last $visible days, 3 completed.'),
      findsOneWidget,
    );
  });

  testWidgets('draws nothing rather than overflowing in no space', (
    tester,
  ) async {
    await pumpHeatmap(tester, <DayStatus>[DayStatus.completed], width: 4);

    expect(tester.takeException(), isNull);
    expect(cellColors(tester), isEmpty);
  });
}
