import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/date_range.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_category.dart';
import 'package:habit_tracker/domain/entities/habit_color_slot.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/schedule_version.dart';
import 'package:habit_tracker/domain/entities/time_window.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';
import 'package:habit_tracker/infrastructure/mappers/habit_mapper.dart';
import 'package:habit_tracker/infrastructure/models/habit_dto.dart';

import '../../domain/fixtures.dart';

void main() {
  /// Sends a habit all the way to a document map and back.
  ///
  /// The full loop, not just entity→DTO: a field that serializes but does not
  /// deserialize is exactly the bug this catches, and only the round trip sees
  /// it.
  Habit roundTrip(Habit habit) => HabitMapper.toEntity(
    HabitDto.fromMap(habit.id, HabitMapper.toDto(habit).toMap()),
  );

  group('round trip', () {
    test('keeps a weekdays habit identical', () {
      final Habit habit = weekdayHabit(
        days: <Weekday>{Weekday.monday, Weekday.wednesday, Weekday.saturday},
        start: d(2026, 8, 3),
      );

      expect(roundTrip(habit), habit);
    });

    test('keeps a times-per-period habit identical', () {
      final Habit habit = timesHabit(
        times: 4,
        period: SchedulePeriod.month,
        start: d(2026, 8, 3),
        end: d(2026, 12, 31),
      );

      expect(roundTrip(habit), habit);
    });

    test('keeps a multi-version schedule history in order', () {
      // The §3.4 case. If the history came back reordered or collapsed,
      // scheduleOn would answer with the wrong rules and every past streak
      // would change.
      final Habit habit = versionedHabit(
        start: d(2026, 7, 27),
        versions: <ScheduleVersion>[
          ScheduleVersion(
            schedule: SpecificWeekdays(<Weekday>{
              Weekday.monday,
              Weekday.friday,
            }),
            effectiveFrom: d(2026, 7, 27),
          ),
          ScheduleVersion(
            schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
            effectiveFrom: d(2026, 8, 10),
          ),
          ScheduleVersion(
            schedule: TimesPerPeriod(times: 5, period: SchedulePeriod.week),
            effectiveFrom: d(2026, 9, 1),
          ),
        ],
      );

      final Habit restored = roundTrip(habit);
      expect(restored, habit);
      expect(restored.scheduleHistory.length, 3);
      expect(restored.scheduleOn(d(2026, 8, 1)), isA<SpecificWeekdays>());
      expect(
        restored.currentSchedule,
        TimesPerPeriod(times: 5, period: SchedulePeriod.week),
      );
    });

    test('keeps an archived habit archived', () {
      final Habit habit = weekdayHabit().copyWith(isArchived: true);
      expect(roundTrip(habit).isArchived, isTrue);
    });

    test('keeps the time window, and keeps null meaning all day', () {
      final Habit timed = weekdayHabit().copyWith(
        timeWindow: TimeWindow.fromClock(
          startHour: 7,
          startMinute: 0,
          endHour: 8,
          endMinute: 30,
        ),
      );

      expect(roundTrip(timed).timeWindow, timed.timeWindow);
      expect(roundTrip(weekdayHabit()).timeWindow, isNull);
    });

    test('keeps an open-ended range open-ended', () {
      final Habit habit = weekdayHabit(start: d(2026, 8, 3));
      expect(roundTrip(habit).range, DateRange.openEnded(d(2026, 8, 3)));
      expect(roundTrip(habit).range.isOpenEnded, isTrue);
    });
  });

  group('the stored shape', () {
    test('writes dates as yyyy-MM-dd, not timestamps', () {
      // Calendar days must not become instants on the way out, or the timezone
      // that DateOnly exists to remove comes back through the database.
      final Map<String, dynamic> map =
          HabitMapper.toDto(
            weekdayHabit(start: d(2026, 8, 3), end: d(2026, 8, 9)),
          ).toMap();

      expect(map['rangeStart'], '2026-08-03');
      expect(map['rangeEnd'], '2026-08-09');
    });

    test('writes weekdays as sorted ISO numbers', () {
      // Sorted so that saving the same schedule twice produces the same
      // document and does not register as a change.
      final Map<String, dynamic> map =
          HabitMapper.toDto(
            weekdayHabit(
              days: <Weekday>{Weekday.saturday, Weekday.monday},
              start: d(2026, 8, 3),
            ),
          ).toMap();
      final List<Map<String, dynamic>> history =
          map['scheduleHistory']! as List<Map<String, dynamic>>;

      expect(history.single['type'], 'specificWeekdays');
      expect(history.single['days'], <int>[1, 6]);
    });

    test('writes the union discriminator for times-per-period', () {
      final Map<String, dynamic> map =
          HabitMapper.toDto(timesHabit(times: 3, start: d(2026, 8, 3))).toMap();
      final List<Map<String, dynamic>> history =
          map['scheduleHistory']! as List<Map<String, dynamic>>;

      expect(history.single['type'], 'timesPerPeriod');
      expect(history.single['times'], 3);
      expect(history.single['period'], 'week');
    });
  });

  group('corrupt documents', () {
    /// A valid document to mutate one field at a time.
    Map<String, dynamic> validDocument() =>
        HabitMapper.toDto(weekdayHabit(start: d(2026, 8, 3))).toMap();

    test('a missing field throws instead of defaulting', () {
      final Map<String, dynamic> data = validDocument()..remove('name');
      expect(
        () => HabitDto.fromMap('habit-1', data),
        throwsA(isA<FormatException>()),
      );
    });

    test('an unknown schedule type throws', () {
      // No guessing here on purpose: inventing a schedule would silently
      // rewrite what the user committed to, and every streak with it.
      final Map<String, dynamic> data = validDocument();
      data['scheduleHistory'] = <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'everyFullMoon',
          'effectiveFrom': '2026-08-03',
        },
      ];

      expect(
        () => HabitMapper.toEntity(HabitDto.fromMap('habit-1', data)),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'an unknown category degrades to "other" instead of losing the habit',
      () {
        // The opposite call, and for a reason: a category is a label. It cannot
        // corrupt a streak, so dropping the whole habit over one would be a much
        // worse outcome than showing it under "Other".
        final Map<String, dynamic> data = validDocument();
        data['category'] = 'timeTravel';

        final Habit habit = HabitMapper.toEntity(
          HabitDto.fromMap('habit-1', data),
        );
        expect(habit.category, HabitCategory.other);
      },
    );

    test('an unknown color slot degrades to the first slot', () {
      final Map<String, dynamic> data = validDocument();
      data['colorSlot'] = 'infrared';

      expect(
        HabitMapper.toEntity(HabitDto.fromMap('habit-1', data)).colorSlot,
        HabitColorSlot.blue,
      );
    });
  });
}
