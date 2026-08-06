import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';

void main() {
  group('SpecificWeekdays', () {
    test('daily is the seven-day case, not a mode of its own', () {
      final SpecificWeekdays daily = SpecificWeekdays.daily();
      expect(daily.isDaily, isTrue);
      expect(daily.days.length, 7);
      expect(daily, SpecificWeekdays(Weekday.all));
    });

    test('is equal regardless of insertion order', () {
      // Sets come back from storage in whatever order the list was written in.
      // If that changed equality, every reload would look like an edit.
      expect(
        SpecificWeekdays(<Weekday>{Weekday.wednesday, Weekday.monday}),
        SpecificWeekdays(<Weekday>{Weekday.monday, Weekday.wednesday}),
      );
    });

    test('refuses an empty set', () {
      expect(
        () => SpecificWeekdays(<Weekday>{}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('exposes the days it is due on', () {
      final SpecificWeekdays schedule = SpecificWeekdays(<Weekday>{
        Weekday.monday,
        Weekday.wednesday,
        Weekday.saturday,
      });
      expect(schedule.includes(Weekday.monday), isTrue);
      expect(schedule.includes(Weekday.tuesday), isFalse);
      expect(schedule.isDaily, isFalse);
    });

    test('cannot be mutated through the exposed set', () {
      final SpecificWeekdays schedule = SpecificWeekdays(<Weekday>{
        Weekday.monday,
      });
      expect(() => schedule.days.add(Weekday.tuesday), throwsUnsupportedError);
    });
  });

  group('TimesPerPeriod', () {
    test('is equal on the same target and period', () {
      expect(
        TimesPerPeriod(times: 3, period: SchedulePeriod.week),
        TimesPerPeriod(times: 3, period: SchedulePeriod.week),
      );
      expect(
        TimesPerPeriod(times: 3, period: SchedulePeriod.week),
        isNot(TimesPerPeriod(times: 3, period: SchedulePeriod.month)),
      );
    });

    test('refuses a target below one', () {
      expect(
        () => TimesPerPeriod(times: 0, period: SchedulePeriod.week),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TimesPerPeriod(times: -1, period: SchedulePeriod.week),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
