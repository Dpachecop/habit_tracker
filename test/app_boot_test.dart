import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';

import 'support/test_dependencies.dart';

void main() {
  group('HabitTrackerApp', () {
    tearDown(() {
      // The locale override is global to the binding; leaving it set would
      // leak into whatever test runs next in this file.
      TestWidgetsFlutterBinding.instance.platformDispatcher
        ..clearLocaleTestValue()
        ..clearLocalesTestValue();
    });

    testWidgets('boots and lands on the home screen', (tester) async {
      await tester.pumpWidget(
        HabitTrackerApp(dependencies: testDependencies()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Habits'), findsOneWidget);
    });

    testWidgets('renders in Spanish on a Spanish device', (tester) async {
      // End-to-end proof that the delegates are actually wired into
      // MaterialApp: a screen string, resolved through the device locale.
      // MaterialApp resolves against the whole preference list, so setting
      // only the single-locale value would leave it reading the real device.
      tester.platformDispatcher
        ..localeTestValue = const Locale('es')
        ..localesTestValue = const <Locale>[Locale('es')];

      await tester.pumpWidget(
        HabitTrackerApp(dependencies: testDependencies()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Metas'), findsOneWidget);
      expect(find.text('Habits'), findsNothing);
    });

    testWidgets('falls back to Spanish for an unsupported language', (
      tester,
    ) async {
      tester.platformDispatcher
        ..localeTestValue = const Locale('ja')
        ..localesTestValue = const <Locale>[Locale('ja')];

      await tester.pumpWidget(
        HabitTrackerApp(dependencies: testDependencies()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Metas'), findsOneWidget);
    });

    testWidgets('keeps one router across rebuilds', (tester) async {
      // The router holds the navigation stack. Rebuilding the root widget must
      // not construct a new one, or every theme change would reset navigation.
      await tester.pumpWidget(
        HabitTrackerApp(dependencies: testDependencies()),
      );
      await tester.pumpAndSettle();

      final MaterialApp first = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );

      await tester.pumpWidget(
        HabitTrackerApp(dependencies: testDependencies()),
      );
      await tester.pumpAndSettle();

      final MaterialApp second = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );

      expect(identical(first.routerConfig, second.routerConfig), isTrue);
    });
  });
}
