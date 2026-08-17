import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

import '../../../domain/entities/date_only.dart';
import '../../../domain/entities/date_range.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_category.dart';
import '../../../domain/entities/habit_color_slot.dart';
import '../../../domain/entities/habit_schedule.dart';
import '../../../domain/entities/weekday.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/repositories/entries_repository.dart';
import '../../../domain/repositories/habits_repository.dart';

/// **Temporary scaffolding. Delete when phase 4 ships the habit form.**
///
/// Phase 3 builds the home screen, and phase 4 builds the only way to create a
/// habit — so for one phase the app has cards to draw and no way to get any.
/// This button fills that gap so the screen can actually be reviewed on a
/// device instead of only in tests.
///
/// Compiled out of release builds entirely: [maybeBuild] returns null unless
/// `kDebugMode`, so no shipped binary contains it.
abstract final class DebugSeedButton {
  /// The button in debug, nothing at all otherwise.
  static Widget? maybeBuild({
    required HabitsRepository habits,
    required EntriesRepository entries,
    required VoidCallback onSeeded,
  }) {
    if (!kDebugMode) return null;
    return _SeedButton(habits: habits, entries: entries, onSeeded: onSeeded);
  }
}

/// The actual floating button.
class _SeedButton extends StatelessWidget {
  /// Creates it.
  const _SeedButton({
    required this.habits,
    required this.entries,
    required this.onSeeded,
  });

  /// Where habits get written.
  final HabitsRepository habits;

  /// Where check-ins get written.
  final EntriesRepository entries;

  /// Called once the sample data is in.
  final VoidCallback onSeeded;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _seed(context),
      icon: const Icon(Icons.science_outlined),
      // Not localized on purpose: it never reaches a user, and putting it in the
      // .arb files would imply it is part of the product.
      label: const Text('Seed sample data'),
    );
  }

  /// Resets storage to three habits that between them cover every card state.
  ///
  /// One daily with a run of history, one on named weekdays that today is *not*
  /// one of, and one times-per-week — so the home screen shows a streak, a
  /// "not today" and a filled check side by side.
  ///
  /// **Idempotent**, and it has to be: the ids are fixed and everything else
  /// gets archived first, so pressing the button five times leaves three habits
  /// rather than fifteen. The first version generated a fresh uuid each press
  /// and the list filled up with duplicates within a minute of use.
  Future<void> _seed(BuildContext context) async {
    final DateTime now = DateTime.now().toUtc();
    final DateOnly today = DateOnly.today();

    // A Monday that is at least two weeks back, so the weekly quota habit has a
    // closed period behind it.
    final DateOnly start = today
        .addDays(-today.weekday.isoValue + 1)
        .addDays(-14);

    final Habit daily = Habit.create(
      id: 'sample-daily',
      name: 'Morning meditation',
      category: HabitCategory.mind,
      colorSlot: HabitColorSlot.aqua,
      schedule: SpecificWeekdays.daily(),
      range: DateRange.openEnded(start),
      createdAt: now,
    );

    // Whichever weekday today is *not*, so the "not today" state is guaranteed
    // rather than dependent on when this button is pressed.
    final Weekday notToday = Weekday.fromIso(
      today.weekday.isoValue == 7 ? 1 : today.weekday.isoValue + 1,
    );
    final Habit weekdays = Habit.create(
      id: 'sample-weekdays',
      name: 'Read 20 pages',
      category: HabitCategory.learning,
      colorSlot: HabitColorSlot.yellow,
      schedule: SpecificWeekdays(<Weekday>{notToday}),
      range: DateRange.openEnded(start),
      createdAt: now,
    );

    final Habit weekly = Habit.create(
      id: 'sample-weekly',
      name: 'Go to the gym',
      category: HabitCategory.fitness,
      colorSlot: HabitColorSlot.orange,
      schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
      range: DateRange.openEnded(start),
      createdAt: now,
    );

    // Archive anything that is not part of the sample set, so a screen left
    // messy by earlier presses comes back clean. Archiving rather than deleting
    // because the repository has no delete — removing a habit would tear a hole
    // in the history of its entries.
    const Set<String> sampleIds = <String>{
      'sample-daily',
      'sample-weekdays',
      'sample-weekly',
    };
    final Either<Failure, List<Habit>> existing =
        await habits.watchHabits().first;
    for (final Habit habit in existing.getRight().getOrElse(
      () => const <Habit>[],
    )) {
      if (!sampleIds.contains(habit.id)) {
        await habits.archiveHabit(habit.id);
      }
    }

    for (final Habit habit in <Habit>[daily, weekdays, weekly]) {
      await habits.saveHabit(habit);
    }

    // Twelve days of the daily habit, ending yesterday, so it shows a live
    // streak with today still open.
    for (int back = 12; back >= 1; back--) {
      await entries.complete(
        habit: daily,
        date: today.addDays(-back),
        today: today,
      );
    }

    // Fill this week's quota on the weekly habit, so its check is blocked.
    final DateOnly monday = today.addDays(-today.weekday.isoValue + 1);
    for (int offset = 0; offset < 3; offset++) {
      final DateOnly date = monday.addDays(offset);
      if (date > today) break;
      await entries.complete(habit: weekly, date: date, today: today);
    }

    onSeeded();
  }
}
