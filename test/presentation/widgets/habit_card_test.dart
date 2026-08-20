import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/config/l10n/app_locales.dart';
import 'package:habit_tracker/config/theme/habit_palette.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_entry.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/streak.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';
import 'package:habit_tracker/domain/services/habit_completion_policy.dart';
import 'package:habit_tracker/domain/services/habit_day_status.dart';
import 'package:habit_tracker/presentation/blocs/habits/habits_state.dart';
import 'package:habit_tracker/presentation/widgets/habit_card.dart';
import 'package:habit_tracker/presentation/widgets/habit_check_box.dart';

import '../../domain/fixtures.dart';
import '../../support/pump_app.dart';

void main() {
  /// A Thursday.
  final DateOnly today = d(2026, 8, 6);

  /// Builds the summary the card is handed, running the real domain services so
  /// the widget is fed the same shapes the bloc would produce.
  HabitSummary summaryFor(
    Habit habit, {
    List<HabitEntry> entries = const <HabitEntry>[],
    Streak streak = const Streak(current: 0, longest: 0),
  }) => HabitSummary(
    habit: habit,
    streak: streak,
    availability: HabitCompletionPolicy.check(
      habit: habit,
      entries: entries,
      date: today,
      today: today,
    ),
    isCompletedToday: entries.any((HabitEntry entry) => entry.date == today),
    // Through the real projection, so the card is fed exactly what the bloc
    // would feed it.
    recentDays: HabitDayStatuses.lastDays(
      habit: habit,
      entries: entries,
      today: today,
      length: 120,
    ),
  );

  group('a habit due today', () {
    testWidgets('shows its name, schedule and streak', (tester) async {
      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(
            weekdayHabit(start: d(2026, 8, 1)).copyWith(name: 'Meditate'),
            streak: const Streak(current: 12, longest: 12),
          ),
          onToggle: () {},
        ),
      );

      expect(find.text('Meditate'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('12 day streak'), findsOneWidget);
    });

    testWidgets('its check is enabled and reports the tap', (tester) async {
      int taps = 0;
      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(weekdayHabit(start: d(2026, 8, 1))),
          onToggle: () => taps++,
        ),
      );

      await tester.tap(find.byType(HabitCheckBox));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('says so when there is no streak yet', (tester) async {
      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(weekdayHabit(start: d(2026, 8, 1))),
          onToggle: () {},
        ),
      );

      expect(find.text('No streak yet'), findsOneWidget);
    });
  });

  group('a habit not due today', () {
    testWidgets('says "Not today" instead of a streak', (tester) async {
      // The state the design had no frame for, and the one that makes the
      // no-over-completion rule visible instead of mysterious.
      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(
            weekdayHabit(days: <Weekday>{Weekday.monday}, start: d(2026, 8, 1)),
          ),
          onToggle: () {},
        ),
      );

      expect(find.text('Not today'), findsOneWidget);
      expect(find.textContaining('streak'), findsNothing);
    });

    testWidgets('its check does nothing when tapped', (tester) async {
      int taps = 0;
      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(
            weekdayHabit(days: <Weekday>{Weekday.monday}, start: d(2026, 8, 1)),
          ),
          onToggle: () => taps++,
        ),
      );

      await tester.tap(find.byType(HabitCheckBox));
      await tester.pumpAndSettle();

      // Disabled by a null callback rather than a guard inside the handler, so
      // there is not even a ripple on a forbidden tap.
      expect(taps, 0);
    });
  });

  group('a habit whose quota is full', () {
    testWidgets('shows the period counters', (tester) async {
      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(
            timesHabit(times: 3, start: d(2026, 8, 3)),
            entries: entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 5))),
          ),
          onToggle: () {},
        ),
      );

      expect(find.text('3/3 this week'), findsOneWidget);
    });

    testWidgets('names the right bucket for a monthly goal', (tester) async {
      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(
            timesHabit(
              times: 2,
              period: SchedulePeriod.month,
              start: d(2026, 8, 1),
            ),
            entries: entriesOn(<DateOnly>[d(2026, 8, 2), d(2026, 8, 4)]),
          ),
          onToggle: () {},
        ),
      );

      expect(find.text('2/2 this month'), findsOneWidget);
    });
  });

  group('a habit already done today', () {
    testWidgets('strikes the name through and fills the check', (tester) async {
      final Habit habit = weekdayHabit(
        start: d(2026, 8, 1),
      ).copyWith(name: 'Drink water');

      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(habit, entries: entriesOn(<DateOnly>[today])),
          onToggle: () {},
        ),
      );

      final Text name = tester.widget<Text>(find.text('Drink water'));
      expect(name.style?.decoration, TextDecoration.lineThrough);

      // The fill is the habit's own color, per the design's checkbox note.
      final Material box = tester.widget<Material>(
        find.descendant(
          of: find.byType(HabitCheckBox),
          matching: find.byType(Material),
        ),
      );
      expect(box.color, HabitPalette.of(habit.colorSlot, Brightness.light));
    });

    testWidgets('still lets the user undo it', (tester) async {
      int taps = 0;
      await tester.pumpApp(
        HabitCard(
          summary: HabitSummary(
            habit: weekdayHabit(start: d(2026, 8, 1)),
            streak: const Streak(current: 1, longest: 1),
            // Completed today: the policy blocks *checking again*, but the card
            // must still offer to uncheck — a mistap has to be correctable.
            availability: const CompletionAvailability.blocked(
              CompletionBlockReason.alreadyCompleted,
            ),
            isCompletedToday: true,
            recentDays: const <DayStatus>[DayStatus.completed],
          ),
          onToggle: () => taps++,
        ),
      );

      await tester.tap(find.byType(HabitCheckBox));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });

  group('inside a scrolling list', () {
    testWidgets('lays out where the home screen actually puts it', (
      tester,
    ) async {
      // The regression this exists for: the card used a stretched Row to draw
      // its colored spine, which needs a bounded height. A ListView hands its
      // children an *infinite* one, so every card failed to lay out and the
      // list silently rendered nothing — while the header still counted them.
      // Wrapping the card in a plain Scaffold, as the other tests here do,
      // hides that completely.
      await tester.pumpApp(
        ListView(
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              HabitCard(
                summary: summaryFor(
                  weekdayHabit(id: 'habit-$i', start: d(2026, 8, 1)),
                ),
                onToggle: () {},
              ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(HabitCheckBox), findsNWidgets(3));
      // And it has real height, rather than collapsing to nothing.
      expect(
        tester.getSize(find.byType(HabitCard).first).height,
        greaterThan(60),
      );
    });
  });

  group('languages and themes', () {
    testWidgets('renders in Spanish', (tester) async {
      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(
            weekdayHabit(days: <Weekday>{Weekday.monday}, start: d(2026, 8, 1)),
          ),
          onToggle: () {},
        ),
        locale: AppLocales.spanish,
      );

      expect(find.text('Hoy no toca'), findsOneWidget);
    });

    testWidgets('lists specific weekdays in ISO order', (tester) async {
      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(
            weekdayHabit(
              // Deliberately out of order on the way in.
              days: <Weekday>{
                Weekday.saturday,
                Weekday.monday,
                Weekday.wednesday,
              },
              start: d(2026, 8, 1),
            ),
          ),
          onToggle: () {},
        ),
      );

      // Mon before Wed before Sat, whatever order the set was built in — and
      // named days rather than "3 times a week", because they are not the same
      // goal.
      expect(find.text('Mon, Wed, Sat'), findsOneWidget);
    });

    testWidgets('builds in dark mode too', (tester) async {
      await tester.pumpApp(
        HabitCard(
          summary: summaryFor(weekdayHabit(start: d(2026, 8, 1))),
          onToggle: () {},
        ),
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(HabitCheckBox), findsOneWidget);
    });
  });
}
