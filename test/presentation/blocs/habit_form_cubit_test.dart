import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_category.dart';
import 'package:habit_tracker/domain/entities/habit_color_slot.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/schedule_version.dart';
import 'package:habit_tracker/domain/entities/time_window.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';
import 'package:habit_tracker/infrastructure/repositories/entries_repository_impl.dart';
import 'package:habit_tracker/infrastructure/repositories/habits_repository_impl.dart';
import 'package:habit_tracker/presentation/blocs/habit_form/habit_form_cubit.dart';
import 'package:habit_tracker/presentation/blocs/habit_form/habit_form_state.dart';

import '../../domain/fixtures.dart';
import '../../support/in_memory_datasources.dart';

void main() {
  /// A Thursday.
  final DateOnly today = d(2026, 8, 6);

  late InMemoryHabitsDatasource habitsStore;
  late InMemoryEntriesDatasource entriesStore;

  setUp(() {
    habitsStore = InMemoryHabitsDatasource();
    entriesStore = InMemoryEntriesDatasource();
  });

  tearDown(() async {
    await habitsStore.dispose();
    await entriesStore.dispose();
  });

  /// A create-mode cubit with a fixed clock and id.
  HabitFormCubit creating() => HabitFormCubit.create(
    habitsRepository: HabitsRepositoryImpl(habitsStore),
    entriesRepository: EntriesRepositoryImpl(entriesStore),
    today: () => today,
    idFactory: () => 'new-habit',
  );

  /// An edit-mode cubit over [habit].
  HabitFormCubit editing(Habit habit) {
    habitsStore.habits[habit.id] = habit;
    return HabitFormCubit.edit(
      habitsRepository: HabitsRepositoryImpl(habitsStore),
      entriesRepository: EntriesRepositoryImpl(entriesStore),
      habit: habit,
      today: () => today,
    );
  }

  group('validation', () {
    test('a blank name blocks the save and shows the errors', () async {
      final HabitFormCubit cubit = creating();

      await cubit.submit();

      expect(cubit.state.invalidFields, contains(HabitFormField.name));
      expect(cubit.state.showErrors, isTrue);
      // Nothing written.
      expect(habitsStore.habits, isEmpty);
      await cubit.close();
    });

    test('errors stay hidden until the first save attempt', () {
      // Flagging an empty name before the user has typed is nagging.
      final HabitFormCubit cubit = creating();
      expect(cubit.state.showErrors, isFalse);
      expect(cubit.state.isValid, isFalse);
      cubit.close();
    });

    test('an empty weekday set is invalid', () async {
      final HabitFormCubit cubit = creating()..nameChanged('Read');
      for (final Weekday day in Weekday.values) {
        cubit.weekdayToggled(day);
      }

      expect(cubit.state.weekdays, isEmpty);
      expect(cubit.state.invalidFields, contains(HabitFormField.weekdays));
      await cubit.close();
    });

    test('an inverted date range is invalid', () async {
      final HabitFormCubit cubit =
          creating()
            ..nameChanged('Read')
            ..startDateChanged(d(2026, 8, 10))
            ..endDateChanged(d(2026, 8, 1));

      expect(cubit.state.invalidFields, contains(HabitFormField.dateRange));
      await cubit.close();
    });

    test('the target is capped at what the period can hold', () async {
      // One completion per day is the ceiling, so 9 a week is not a goal, it is
      // a guaranteed failure.
      final HabitFormCubit cubit =
          creating()
            ..nameChanged('Gym')
            ..scheduleModeChanged(ScheduleMode.timesPerPeriod)
            ..timesChanged(9);

      expect(cubit.state.times, 7);
      expect(cubit.state.invalidFields, isNot(contains(HabitFormField.times)));
      await cubit.close();
    });

    test('shrinking the period re-clamps the target', () async {
      final HabitFormCubit cubit =
          creating()
            ..nameChanged('Gym')
            ..scheduleModeChanged(ScheduleMode.timesPerPeriod)
            ..periodChanged(SchedulePeriod.month)
            ..timesChanged(20)
            ..periodChanged(SchedulePeriod.week);

      // 20 a month is fine; 20 a week is not.
      expect(cubit.state.times, 7);
      await cubit.close();
    });
  });

  group('creating', () {
    test('writes the habit with one schedule version', () async {
      final HabitFormCubit cubit =
          creating()
            ..nameChanged('  Morning meditation  ')
            ..categoryChanged(HabitCategory.mind)
            ..colorChanged(HabitColorSlot.aqua);

      await cubit.submit();

      expect(cubit.state.status, HabitFormStatus.saved);
      final Habit saved = habitsStore.habits['new-habit']!;
      // Trimmed: trailing spaces in a name are never intentional.
      expect(saved.name, 'Morning meditation');
      expect(saved.category, HabitCategory.mind);
      expect(saved.colorSlot, HabitColorSlot.aqua);
      expect(saved.scheduleHistory, hasLength(1));
      expect(saved.range.start, today);
      expect(saved.range.isOpenEnded, isTrue);
      await cubit.close();
    });

    test('defaults to daily, which is the seven-day case', () async {
      final HabitFormCubit cubit = creating()..nameChanged('Water');

      await cubit.submit();

      final HabitSchedule schedule =
          habitsStore.habits['new-habit']!.currentSchedule;
      expect(schedule, isA<SpecificWeekdays>());
      expect((schedule as SpecificWeekdays).isDaily, isTrue);
      await cubit.close();
    });

    test('writes a times-per-period habit', () async {
      final HabitFormCubit cubit =
          creating()
            ..nameChanged('Gym')
            ..scheduleModeChanged(ScheduleMode.timesPerPeriod)
            ..timesChanged(3);

      await cubit.submit();

      expect(
        habitsStore.habits['new-habit']!.currentSchedule,
        TimesPerPeriod(times: 3, period: SchedulePeriod.week),
      );
      await cubit.close();
    });

    test('keeps the time window when one is set', () async {
      final HabitFormCubit cubit = creating()..nameChanged('Gym');
      cubit.allDayToggled(isAllDay: false);
      cubit.timeWindowChanged(
        TimeWindow.fromClock(
          startHour: 7,
          startMinute: 0,
          endHour: 8,
          endMinute: 30,
        ),
      );

      await cubit.submit();

      expect(habitsStore.habits['new-habit']!.timeWindow, isNotNull);
      await cubit.close();
    });

    test('never asks the §3.4 question — a new habit has no streak', () async {
      final HabitFormCubit cubit =
          creating()
            ..nameChanged('Gym')
            ..scheduleModeChanged(ScheduleMode.timesPerPeriod)
            ..timesChanged(7);

      await cubit.submit();

      expect(cubit.state.pendingWarning, isNull);
      expect(cubit.state.status, HabitFormStatus.saved);
      await cubit.close();
    });
  });

  group('editing — §3.4', () {
    test('renaming leaves the schedule history alone', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final HabitFormCubit cubit = editing(habit)..nameChanged('Renamed');

      await cubit.submit();

      final Habit saved = habitsStore.habits[habit.id]!;
      expect(saved.name, 'Renamed');
      // Re-saving an unchanged schedule must not litter the history.
      expect(saved.scheduleHistory, hasLength(1));
      await cubit.close();
    });

    test('a new weekday set is appended, effective tomorrow', () async {
      // Today cannot become due retroactively.
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final HabitFormCubit cubit = editing(habit)
        ..weekdayToggled(Weekday.sunday);

      await cubit.submit();

      final Habit saved = habitsStore.habits[habit.id]!;
      expect(saved.scheduleHistory, hasLength(2));
      expect(saved.scheduleHistory.last.effectiveFrom, d(2026, 8, 7));
      // And the past keeps its own rules.
      expect(saved.scheduleOn(d(2026, 8, 6)), habit.currentSchedule);
      await cubit.close();
    });

    test('a new target is appended, effective today', () async {
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 3));
      final HabitFormCubit cubit = editing(habit)..timesChanged(4);

      await cubit.submit();

      final Habit saved = habitsStore.habits[habit.id]!;
      expect(saved.scheduleHistory, hasLength(2));
      expect(saved.scheduleHistory.last.effectiveFrom, today);
      await cubit.close();
    });

    test('editing twice in one day replaces rather than stacks', () async {
      // A weekdays habit on purpose: both edits land on tomorrow, so the second
      // one replaces the first instead of stacking a third version. A quota
      // habit would trip the reachability warning here and never get to save,
      // which is correct behaviour but a different test.
      final Habit habit = weekdayHabit(
        days: <Weekday>{Weekday.monday},
        start: d(2026, 8, 1),
      );

      final HabitFormCubit first = editing(habit)
        ..weekdayToggled(Weekday.wednesday);
      await first.submit();
      await first.close();

      final HabitFormCubit second = editing(habitsStore.habits[habit.id]!)
        ..weekdayToggled(Weekday.friday);
      await second.submit();

      final Habit saved = habitsStore.habits[habit.id]!;
      // Two versions, not three: the original plus tomorrow's, whose date is
      // the same on both edits.
      expect(saved.scheduleHistory, hasLength(2));
      expect(saved.scheduleHistory.last.effectiveFrom, d(2026, 8, 7));
      expect(
        saved.currentSchedule,
        SpecificWeekdays(<Weekday>{
          Weekday.monday,
          Weekday.wednesday,
          Weekday.friday,
        }),
      );
      await second.close();
    });

    test('a change after a pending one does not throw', () async {
      // A weekdays edit earlier today left a version dated tomorrow. Switching
      // to a target now would propose *today*, which is older than the pending
      // version — appending that would throw. It gets floored instead.
      final Habit habit = versionedHabit(
        start: d(2026, 8, 1),
        versions: <ScheduleVersion>[
          ScheduleVersion(
            schedule: SpecificWeekdays.daily(),
            effectiveFrom: d(2026, 8, 1),
          ),
          ScheduleVersion(
            schedule: SpecificWeekdays(<Weekday>{Weekday.monday}),
            effectiveFrom: d(2026, 8, 7),
          ),
        ],
      );
      final HabitFormCubit cubit =
          editing(habit)
            ..scheduleModeChanged(ScheduleMode.timesPerPeriod)
            ..timesChanged(3);

      await cubit.submit();

      expect(cubit.state.status, HabitFormStatus.saved);
      final Habit saved = habitsStore.habits[habit.id]!;
      expect(saved.scheduleHistory.last.effectiveFrom, d(2026, 8, 7));
      expect(saved.currentSchedule, isA<TimesPerPeriod>());
      await cubit.close();
    });
  });

  group('the unreachable-period warning — §3.4', () {
    /// A weekly habit with three of its three done, on the given day.
    HabitFormCubit raisingTargetOn(DateOnly when) {
      final Habit habit = timesHabit(times: 3, start: d(2026, 8, 3));
      habitsStore.habits[habit.id] = habit;
      for (final DateOnly date in datesFrom(d(2026, 8, 3), d(2026, 8, 5))) {
        entriesStore.entries['${habit.id}_${date.toIso8601()}'] =
            entriesOn(<DateOnly>[date], habitId: habit.id).single;
      }
      return HabitFormCubit.edit(
        habitsRepository: HabitsRepositoryImpl(habitsStore),
        entriesRepository: EntriesRepositoryImpl(entriesStore),
        habit: habit,
        today: () => when,
      )..timesChanged(5);
    }

    test(
      'stops the save and explains, instead of burning the streak',
      () async {
        // Sunday: two more needed, one day left.
        final HabitFormCubit cubit = raisingTargetOn(d(2026, 8, 9));

        await cubit.submit();

        expect(cubit.state.pendingWarning, isNotNull);
        expect(cubit.state.pendingWarning!.isReachable, isFalse);
        expect(cubit.state.pendingWarning!.missing, 2);
        expect(cubit.state.pendingWarning!.daysLeft, 1);
        // Crucially: not saved yet.
        expect(cubit.state.status, HabitFormStatus.editing);
        expect(habitsStore.habits[testHabitId]!.scheduleHistory, hasLength(1));
        await cubit.close();
      },
    );

    test('confirming goes through — it is the user\'s call', () async {
      final HabitFormCubit cubit = raisingTargetOn(d(2026, 8, 9));
      await cubit.submit();

      await cubit.confirmSave();

      expect(cubit.state.status, HabitFormStatus.saved);
      expect(cubit.state.pendingWarning, isNull);
      expect(habitsStore.habits[testHabitId]!.scheduleHistory, hasLength(2));
      await cubit.close();
    });

    test('dismissing leaves the habit untouched', () async {
      final HabitFormCubit cubit = raisingTargetOn(d(2026, 8, 9));
      await cubit.submit();

      cubit.warningDismissed();

      expect(cubit.state.pendingWarning, isNull);
      expect(habitsStore.habits[testHabitId]!.scheduleHistory, hasLength(1));
      await cubit.close();
    });

    test('no warning when the week can still be met', () async {
      // Tuesday: plenty of runway.
      final HabitFormCubit cubit = raisingTargetOn(d(2026, 8, 4));

      await cubit.submit();

      expect(cubit.state.pendingWarning, isNull);
      expect(cubit.state.status, HabitFormStatus.saved);
      await cubit.close();
    });
  });

  group('archiving', () {
    test('archives instead of deleting, so the history survives', () async {
      final Habit habit = weekdayHabit(start: d(2026, 8, 1));
      final HabitFormCubit cubit = editing(habit);

      await cubit.archive();

      expect(cubit.state.status, HabitFormStatus.archived);
      expect(habitsStore.habits[habit.id]!.isArchived, isTrue);
      expect(habitsStore.habits, hasLength(1));
      await cubit.close();
    });

    test('does nothing when creating — there is nothing to archive', () async {
      final HabitFormCubit cubit = creating();

      await cubit.archive();

      expect(cubit.state.status, HabitFormStatus.editing);
      await cubit.close();
    });
  });
}
