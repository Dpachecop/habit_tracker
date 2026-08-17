import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/presentation/screens/shell/placeholder_screen.dart';

import 'support/test_dependencies.dart';

void main() {
  late InMemoryDependencies deps;

  setUp(() => deps = InMemoryDependencies());

  tearDown(() async {
    await deps.dispose();
    // The locale override is global to the binding; leaving it set would leak
    // into whatever test runs next.
    TestWidgetsFlutterBinding.instance.platformDispatcher
      ..clearLocaleTestValue()
      ..clearLocalesTestValue();
  });

  /// Boots the app over in-memory storage and lets it settle.
  ///
  /// The push is explicit: the fake datasources are broadcast controllers with
  /// no replay, so nothing reaches a subscriber until something is emitted.
  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(HabitTrackerApp(dependencies: deps.dependencies));
    await tester.pump();
    deps.emit();
    await tester.pumpAndSettle();
  }

  /// Forces the device language for the whole binding.
  ///
  /// Both values are set: `MaterialApp` resolves against the preference *list*,
  /// so setting only the single locale would leave it reading the real device.
  void useLocale(WidgetTester tester, String languageCode) {
    tester.platformDispatcher
      ..localeTestValue = Locale(languageCode)
      ..localesTestValue = <Locale>[Locale(languageCode)];
  }

  group('HabitTrackerApp', () {
    testWidgets('boots and lands on the home screen', (tester) async {
      await boot(tester);

      expect(find.text('Habit Tracker'), findsOneWidget);
    });

    testWidgets('shows the empty state when there are no habits', (
      tester,
    ) async {
      await boot(tester);

      // Ready-and-empty, not a spinner that never stops.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text('Create your first goal to start a streak.'),
        findsOneWidget,
      );
    });

    testWidgets('renders in Spanish on a Spanish device', (tester) async {
      useLocale(tester, 'es');
      await boot(tester);

      expect(
        find.text('Crea tu primera meta para empezar una racha.'),
        findsOneWidget,
      );
    });

    testWidgets('falls back to Spanish for an unsupported language', (
      tester,
    ) async {
      useLocale(tester, 'ja');
      await boot(tester);

      expect(
        find.text('Crea tu primera meta para empezar una racha.'),
        findsOneWidget,
      );
    });

    testWidgets('offers the four tabs and can switch between them', (
      tester,
    ) async {
      await boot(tester);

      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // The tab is a real screen saying it is not built yet, rather than a
      // blank that looks broken.
      expect(find.byType(PlaceholderScreen), findsOneWidget);
      expect(find.text('Coming soon.'), findsOneWidget);
    });

    testWidgets('keeps one router across rebuilds', (tester) async {
      // The router holds the navigation stack. Rebuilding the root widget must
      // not construct a new one, or every theme change would reset navigation.
      await boot(tester);

      final MaterialApp first = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );

      await tester.pumpWidget(HabitTrackerApp(dependencies: deps.dependencies));
      await tester.pumpAndSettle();

      final MaterialApp second = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );

      expect(identical(first.routerConfig, second.routerConfig), isTrue);
    });
  });
}
