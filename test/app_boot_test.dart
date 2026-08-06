import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';

void main() {
  group('HabitTrackerApp', () {
    testWidgets('boots and lands on the home screen', (tester) async {
      await tester.pumpWidget(const HabitTrackerApp());
      await tester.pumpAndSettle();

      expect(find.text('Habits'), findsOneWidget);
    });

    testWidgets('keeps one router across rebuilds', (tester) async {
      // The router holds the navigation stack. Rebuilding the root widget must
      // not construct a new one, or every theme change would reset navigation.
      await tester.pumpWidget(const HabitTrackerApp());
      await tester.pumpAndSettle();

      final MaterialApp first = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );

      await tester.pumpWidget(const HabitTrackerApp());
      await tester.pumpAndSettle();

      final MaterialApp second = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );

      expect(identical(first.routerConfig, second.routerConfig), isTrue);
    });
  });
}
