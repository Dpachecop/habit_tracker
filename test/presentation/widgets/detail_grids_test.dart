import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/config/l10n/app_locales.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/services/habit_day_status.dart';
import 'package:habit_tracker/presentation/widgets/contribution_grid.dart';
import 'package:habit_tracker/presentation/widgets/month_calendar.dart';

import '../../domain/fixtures.dart';
import '../../support/pump_app.dart';

void main() {
  const Color accent = Color(0xFF2A78D6);

  /// A Thursday.
  final DateOnly today = d(2026, 8, 6);

  group('ContributionGrid', () {
    /// Mounts the grid at a known width.
    Future<void> pumpGrid(
      WidgetTester tester, {
      required DayStatus Function(DateOnly) statusOf,
      double width = 360,
      Locale locale = AppLocales.english,
    }) async {
      await tester.pumpApp(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ContributionGrid(
              today: today,
              statusOf: statusOf,
              accent: accent,
            ),
          ),
        ),
        locale: locale,
      );
    }

    /// Every cell colour the grid drew.
    List<Color?> cells(WidgetTester tester) =>
        tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(ContributionGrid),
                matching: find.byType(Container),
              ),
            )
            .map((Container cell) => (cell.decoration! as BoxDecoration).color)
            .toList();

    testWidgets('draws seven rows, one per weekday', (tester) async {
      await pumpGrid(tester, statusOf: (_) => DayStatus.notDue);

      // Whatever the column count works out to, the total has to divide by 7.
      expect(cells(tester).length % 7, 0);
      expect(cells(tester), isNotEmpty);
    });

    testWidgets('a whole row is one weekday, which is the point', (
      tester,
    ) async {
      // The compact strip on the card cannot do this: there, a column means
      // nothing. Here every seventh cell in reading order is the same weekday,
      // so painting only Tuesdays lights exactly one row.
      await pumpGrid(
        tester,
        statusOf:
            (DateOnly date) =>
                date.weekday.isoValue == 2
                    ? DayStatus.completed
                    : DayStatus.notDue,
      );

      final List<Color?> drawn = cells(tester);
      final int columns = drawn.length ~/ 7;
      // Tuesday is the second row, so cells [columns .. 2*columns) are it.
      final Iterable<Color?> tuesdayRow = drawn.skip(columns).take(columns);

      expect(tuesdayRow.every((Color? color) => color == accent), isTrue);
      expect(drawn.take(columns).every((Color? c) => c != accent), isTrue);
    });

    testWidgets('ends on the week that contains today', (tester) async {
      await pumpGrid(
        tester,
        statusOf:
            (DateOnly date) =>
                date == today ? DayStatus.completed : DayStatus.notDue,
      );

      // Today is a Thursday: row index 3, last column.
      final List<Color?> drawn = cells(tester);
      final int columns = drawn.length ~/ 7;
      expect(drawn[3 * columns + (columns - 1)], accent);
    });

    testWidgets('labels the months it spans', (tester) async {
      await pumpGrid(tester, statusOf: (_) => DayStatus.notDue);

      // Whatever the width allows, August has to be in there — the grid ends on
      // today's week.
      expect(find.text('Aug'), findsOneWidget);
    });

    testWidgets('labels weekdays down the side, every other row', (
      tester,
    ) async {
      await pumpGrid(tester, statusOf: (_) => DayStatus.notDue);

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      // The even rows are left blank: seven labels would not fit.
      expect(find.text('Tue'), findsNothing);
    });

    testWidgets('renders in Spanish', (tester) async {
      await pumpGrid(
        tester,
        statusOf: (_) => DayStatus.notDue,
        locale: AppLocales.spanish,
      );

      expect(find.text('Lun'), findsOneWidget);
    });

    testWidgets('draws nothing rather than overflowing in no space', (
      tester,
    ) async {
      await pumpGrid(tester, statusOf: (_) => DayStatus.notDue, width: 30);

      expect(tester.takeException(), isNull);
    });
  });

  group('MonthCalendar', () {
    /// Mounts one month.
    Future<void> pumpMonth(
      WidgetTester tester, {
      required DateOnly month,
      DayStatus Function(DateOnly)? statusOf,
    }) async {
      await tester.pumpApp(
        SizedBox(
          width: 360,
          child: MonthCalendar(
            month: month,
            today: today,
            statusOf: statusOf ?? (_) => DayStatus.notDue,
            accent: accent,
          ),
        ),
      );
    }

    testWidgets('shows the whole month, weeks starting on Monday', (
      tester,
    ) async {
      await pumpMonth(tester, month: d(2026, 8, 1));

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      // August has 31 days; the 31st has to be there.
      expect(find.text('31'), findsWidgets);
    });

    testWidgets('rings today', (tester) async {
      await pumpMonth(tester, month: d(2026, 8, 1));

      final Iterable<Container> ringed = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).border != null,
          );

      // Exactly one: today.
      expect(ringed, hasLength(1));
    });

    testWidgets('does not ring anything in a month that is not this one', (
      tester,
    ) async {
      await pumpMonth(tester, month: d(2026, 5, 1));

      final Iterable<Container> ringed = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).border != null,
          );

      expect(ringed, isEmpty);
    });

    testWidgets('dots the days that were completed', (tester) async {
      await pumpMonth(
        tester,
        month: d(2026, 8, 1),
        statusOf:
            (DateOnly date) =>
                date == d(2026, 8, 5) || date == d(2026, 8, 12)
                    ? DayStatus.completed
                    : DayStatus.notDue,
      );

      final Iterable<Container> dots = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color == accent,
          );

      expect(dots, hasLength(2));
    });

    testWidgets('keeps the same height whatever month it shows', (
      tester,
    ) async {
      // Six rows always. A grid that changed height would make the sheet jump
      // as the user pages.
      await pumpMonth(tester, month: d(2026, 2, 1));
      final double february = tester.getSize(find.byType(MonthCalendar)).height;

      await pumpMonth(tester, month: d(2026, 8, 1));
      final double august = tester.getSize(find.byType(MonthCalendar)).height;

      expect(february, august);
    });

    testWidgets('ignores completions in the spill-over days', (tester) async {
      // The last days of July show in August's first row, greyed. A dot there
      // would claim August had a completion it did not.
      await pumpMonth(
        tester,
        month: d(2026, 8, 1),
        statusOf:
            (DateOnly date) =>
                date == d(2026, 7, 30) ? DayStatus.completed : DayStatus.notDue,
      );

      final Iterable<Container> dots = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color == accent,
          );

      expect(dots, isEmpty);
    });
  });
}
