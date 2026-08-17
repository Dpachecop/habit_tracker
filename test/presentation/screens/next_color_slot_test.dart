import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/config/l10n/app_locales.dart';
import 'package:habit_tracker/config/theme/app_theme.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_color_slot.dart';
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
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  /// Mounts the create form with a suggested slot, as the route does.
  Future<void> pumpCreateForm(
    WidgetTester tester,
    HabitColorSlot? suggested,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 3600)
      ..devicePixelRatio = 1;

    // Tear the previous tree down first. Re-pumping the same widget type at the
    // same position keeps its State — and with it the BlocProvider's existing
    // cubit — so a second call would silently reuse the first form.
    await tester.pumpWidget(const SizedBox.shrink());

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
          localizationsDelegates: AppLocales.delegates,
          supportedLocales: AppLocales.supported,
          theme: AppTheme.light,
          home: HabitFormScreen(suggestedColor: suggested),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Saves with a name and returns the habit that was written.
  Future<Habit> saveWithName(WidgetTester tester, String name) async {
    await tester.enterText(find.byType(TextField), name);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    return deps.habitsDatasource.habits.values.last;
  }

  testWidgets('a new habit starts on the slot it was handed', (tester) async {
    // §3.6: the declaration order of HabitColorSlot *is* the colorblind-safety
    // guarantee, so new habits walk it in order rather than all landing on the
    // same default.
    await pumpCreateForm(tester, HabitColorSlot.aqua);

    final Habit saved = await saveWithName(tester, 'Meditate');

    expect(saved.colorSlot, HabitColorSlot.aqua);
  });

  testWidgets('falls back to the first slot when handed nothing', (
    tester,
  ) async {
    await pumpCreateForm(tester, null);

    final Habit saved = await saveWithName(tester, 'Meditate');

    expect(saved.colorSlot, HabitColorSlot.blue);
  });

  testWidgets('the user can still override the suggestion', (tester) async {
    await pumpCreateForm(tester, HabitColorSlot.aqua);

    // The swatches are rendered in declaration order, so the last one is red.
    await tester.tap(find.byType(InkWell).at(HabitColorSlot.values.length - 1));
    await tester.pumpAndSettle();

    final Habit saved = await saveWithName(tester, 'Meditate');

    expect(saved.colorSlot, HabitColorSlot.red);
  });

  testWidgets('the range start defaults to today', (tester) async {
    await pumpCreateForm(tester, HabitColorSlot.blue);

    final Habit saved = await saveWithName(tester, 'Meditate');

    expect(saved.range.start, DateOnly.today());
    expect(saved.range.isOpenEnded, isTrue);
    // And a fresh habit has exactly one schedule version.
    expect(saved.scheduleHistory, hasLength(1));
  });

  testWidgets('two habits in a row do not have to share a color', (
    tester,
  ) async {
    // The screen picks the slot, so this checks the plumbing carries it rather
    // than the picking logic itself.
    await pumpCreateForm(tester, HabitColorSlot.blue);
    final Habit first = await saveWithName(tester, 'One');

    await pumpCreateForm(tester, HabitColorSlot.orange);
    final Habit second = await saveWithName(tester, 'Two');

    expect(first.colorSlot, isNot(second.colorSlot));
  });

  test('the fixtures still agree on the anchor date', () {
    // Guards the assumption the rest of these tests lean on.
    expect(d(2026, 8, 6).weekday.isoValue, 4);
  });
}
