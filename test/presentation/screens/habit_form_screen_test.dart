import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/config/l10n/app_locales.dart';
import 'package:habit_tracker/config/theme/app_theme.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';
import 'package:habit_tracker/domain/repositories/entries_repository.dart';
import 'package:habit_tracker/domain/repositories/habits_repository.dart';
import 'package:habit_tracker/presentation/screens/habit_form/habit_form_screen.dart';

import '../../domain/fixtures.dart';
import '../../support/test_dependencies.dart';

void main() {
  late InMemoryDependencies deps;

  setUp(() => deps = InMemoryDependencies());

  tearDown(() async {
    await deps.dispose();
    // The surface is resized per test below; leaving it stretched would leak
    // into every later widget test in the run.
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  /// Mounts the form over in-memory storage, with the repositories provided the
  /// way the real app provides them.
  Future<void> pumpForm(
    WidgetTester tester, {
    Habit? habit,
    Locale locale = AppLocales.english,
  }) async {
    // A tall surface on purpose. The form is a ListView, which only inflates the
    // children it can show, so on the default 800x600 the Save button and the
    // archive action are simply not in the tree and `find.text` misses them —
    // a failure that looks like a bug in the screen and is not.
    tester.view
      ..physicalSize = const Size(1200, 3600)
      ..devicePixelRatio = 1;

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: <RepositoryProvider<Object>>[
          RepositoryProvider<HabitsRepository>.value(
            value: deps.dependencies.habitsRepository,
          ),
          RepositoryProvider<EntriesRepository>.value(
            value: deps.dependencies.entriesRepository,
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocales.delegates,
          supportedLocales: AppLocales.supported,
          theme: AppTheme.light,
          home: HabitFormScreen(habit: habit),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('creating', () {
    testWidgets('opens with the create title and no archive action', (
      tester,
    ) async {
      await pumpForm(tester);

      expect(find.text('New goal'), findsOneWidget);
      // Nothing to archive yet.
      expect(find.text('Archive goal'), findsNothing);
    });

    testWidgets('refuses to save without a name and says why', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Give your goal a name.'), findsOneWidget);
      expect(deps.habitsDatasource.habits, isEmpty);
    });

    testWidgets('writes the habit once it has a name', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.byType(TextField), 'Morning meditation');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(deps.habitsDatasource.habits, hasLength(1));
      expect(
        deps.habitsDatasource.habits.values.single.name,
        'Morning meditation',
      );
    });

    testWidgets('switches to the times-per-period branch', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.text('A number of times'));
      await tester.pumpAndSettle();

      // The weekday chips give way to the counter and the period selector.
      expect(find.text('Times'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Every day'), findsNothing);
    });
  });

  group('editing', () {
    testWidgets('opens filled in, with the archive action', (tester) async {
      final Habit habit = weekdayHabit(
        start: d(2026, 8, 1),
      ).copyWith(name: 'Read');
      deps.habitsDatasource.habits[habit.id] = habit;

      await pumpForm(tester, habit: habit);

      expect(find.text('Edit goal'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Archive goal'), findsOneWidget);
    });

    testWidgets('says nothing about timing until the schedule changes', (
      tester,
    ) async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      deps.habitsDatasource.habits[habit.id] = habit;

      await pumpForm(tester, habit: habit);

      expect(find.textContaining('apply from'), findsNothing);
    });

    testWidgets('explains that new weekdays start tomorrow', (tester) async {
      // The §3.4 reassurance: the streak already earned is safe.
      final Habit habit = weekdayHabit(
        days: <Weekday>{Weekday.monday},
        start: d(2026, 8, 1),
      );
      deps.habitsDatasource.habits[habit.id] = habit;

      await pumpForm(tester, habit: habit);
      await tester.tap(find.text('Tue'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('The new days apply from tomorrow'),
        findsOneWidget,
      );
    });

    testWidgets('explains that a new target starts today', (tester) async {
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 1));
      deps.habitsDatasource.habits[habit.id] = habit;

      await pumpForm(tester, habit: habit);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('The new target applies from today'),
        findsOneWidget,
      );
    });

    testWidgets('archiving asks first', (tester) async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      deps.habitsDatasource.habits[habit.id] = habit;

      await pumpForm(tester, habit: habit);
      await tester.tap(find.text('Archive goal'));
      await tester.pumpAndSettle();

      expect(find.text('Archive this goal?'), findsOneWidget);
      // And says it is not a delete, because a red button next to the word
      // "archive" reads like one.
      expect(find.textContaining('keeps its history'), findsWidgets);

      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();
      expect(deps.habitsDatasource.habits.values.single.isArchived, isFalse);
    });
  });

  group('languages', () {
    testWidgets('renders in Spanish', (tester) async {
      await pumpForm(tester, locale: AppLocales.spanish);

      expect(find.text('Nueva meta'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Todos los días'), findsOneWidget);
    });
  });
}
