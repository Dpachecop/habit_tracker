import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/date_period.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';

import '../fixtures.dart';

void main() {
  group('DatePeriod.week', () {
    test('starts on Monday and ends on Sunday', () {
      final DatePeriod week = DatePeriod.containing(
        d(2026, 8, 6),
        SchedulePeriod.week,
      );
      expect(week.start, d(2026, 8, 3));
      expect(week.end, d(2026, 8, 9));
      expect(week.lengthInDays, 7);
    });

    test('puts Sunday in the week that started six days earlier', () {
      // The classic off-by-one: with a Sunday-first week this lands in the next
      // bucket and a "3 times a week" goal silently resets a day early.
      final DatePeriod week = DatePeriod.containing(
        d(2026, 8, 9),
        SchedulePeriod.week,
      );
      expect(week.start, d(2026, 8, 3));
    });

    test('spans two months when the week straddles them', () {
      final DatePeriod week = DatePeriod.containing(
        d(2026, 9, 1),
        SchedulePeriod.week,
      );
      expect(week.start, d(2026, 8, 31));
      expect(week.end, d(2026, 9, 6));
    });

    test('spans two years when the week straddles them', () {
      final DatePeriod week = DatePeriod.containing(
        d(2026, 1, 1),
        SchedulePeriod.week,
      );
      expect(week.start, d(2025, 12, 29));
      expect(week.end, d(2026, 1, 4));
    });
  });

  group('DatePeriod.month', () {
    test('runs from the first to the last day', () {
      final DatePeriod month = DatePeriod.containing(
        d(2026, 8, 6),
        SchedulePeriod.month,
      );
      expect(month.start, d(2026, 8, 1));
      expect(month.end, d(2026, 8, 31));
    });

    test('gets February right in and out of a leap year', () {
      expect(
        DatePeriod.containing(d(2026, 2, 10), SchedulePeriod.month).end,
        d(2026, 2, 28),
      );
      expect(
        DatePeriod.containing(d(2028, 2, 10), SchedulePeriod.month).end,
        d(2028, 2, 29),
      );
    });
  });

  group('DatePeriod.year', () {
    test('runs from January 1st to December 31st', () {
      final DatePeriod year = DatePeriod.containing(
        d(2026, 8, 6),
        SchedulePeriod.year,
      );
      expect(year.start, d(2026, 1, 1));
      expect(year.end, d(2026, 12, 31));
      expect(year.lengthInDays, 365);
    });
  });

  group('DatePeriod.previous', () {
    test('steps back one week across a year boundary', () {
      final DatePeriod week = DatePeriod.containing(
        d(2026, 1, 1),
        SchedulePeriod.week,
      );
      expect(week.previous.start, d(2025, 12, 22));
    });

    test('steps back into a shorter month', () {
      final DatePeriod march = DatePeriod.containing(
        d(2026, 3, 15),
        SchedulePeriod.month,
      );
      expect(march.previous.start, d(2026, 2, 1));
      expect(march.previous.end, d(2026, 2, 28));
    });
  });

  test('contains covers both ends of the period', () {
    final DatePeriod week = DatePeriod.containing(
      d(2026, 8, 6),
      SchedulePeriod.week,
    );
    expect(week.contains(d(2026, 8, 3)), isTrue);
    expect(week.contains(d(2026, 8, 9)), isTrue);
    expect(week.contains(d(2026, 8, 2)), isFalse);
    expect(week.contains(d(2026, 8, 10)), isFalse);
  });
}
