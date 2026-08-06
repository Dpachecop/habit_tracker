import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';

import '../fixtures.dart';

void main() {
  group('DateOnly', () {
    test('normalizes out-of-range components like DateTime does', () {
      expect(d(2026, 1, 32), d(2026, 2, 1));
      expect(d(2026, 13, 1), d(2027, 1, 1));
      expect(d(2026, 3, 0), d(2026, 2, 28));
    });

    test('knows 2028 is a leap year', () {
      expect(d(2028, 2, 29).addDays(1), d(2028, 3, 1));
      expect(d(2026, 2, 28).addDays(1), d(2026, 3, 1));
    });

    test('takes the local day of a moment, not the UTC one', () {
      // Late-evening local time is already tomorrow in UTC for eastern zones
      // and still yesterday for western ones. The entry belongs to the day the
      // user lived, which is what fromDateTime has to return.
      final DateTime localEvening = DateTime(2026, 8, 6, 23, 30);
      expect(DateOnly.fromDateTime(localEvening), d(2026, 8, 6));
    });

    test('moves across a year boundary', () {
      expect(d(2025, 12, 31).addDays(1), d(2026, 1, 1));
      expect(d(2026, 1, 1).addDays(-1), d(2025, 12, 31));
    });

    test('counts days between dates in both directions', () {
      expect(d(2026, 8, 6).daysUntil(d(2026, 8, 9)), 3);
      expect(d(2026, 8, 9).daysUntil(d(2026, 8, 6)), -3);
      expect(d(2026, 8, 6).daysUntil(d(2026, 8, 6)), 0);
      // Across a leap day, so the count cannot be a month-length guess.
      expect(d(2028, 2, 27).daysUntil(d(2028, 3, 1)), 3);
    });

    test('reports the ISO weekday', () {
      expect(d(2026, 8, 3).weekday, Weekday.monday);
      expect(d(2026, 8, 6).weekday, Weekday.thursday);
      expect(d(2026, 8, 9).weekday, Weekday.sunday);
    });

    test('round-trips through its ISO string', () {
      final DateOnly date = d(2026, 8, 6);
      expect(date.toIso8601(), '2026-08-06');
      expect(DateOnly.parse(date.toIso8601()), date);
      expect(d(2026, 12, 25).toIso8601(), '2026-12-25');
    });

    test('rejects anything that is not yyyy-MM-dd', () {
      expect(() => DateOnly.parse('2026-8-6'), throwsFormatException);
      expect(() => DateOnly.parse('06/08/2026'), throwsFormatException);
      expect(() => DateOnly.parse(''), throwsFormatException);
    });

    test('orders and compares by calendar position', () {
      expect(d(2026, 8, 6) < d(2026, 8, 7), isTrue);
      expect(d(2026, 8, 6) <= d(2026, 8, 6), isTrue);
      expect(d(2026, 9, 1) > d(2026, 8, 31), isTrue);
      expect(d(2027, 1, 1) > d(2026, 12, 31), isTrue);

      final List<DateOnly> dates = <DateOnly>[
        d(2026, 8, 9),
        d(2025, 1, 1),
        d(2026, 8, 6),
      ]..sort();
      expect(dates, <DateOnly>[d(2025, 1, 1), d(2026, 8, 6), d(2026, 8, 9)]);
    });

    test('is a value: same day means equal', () {
      expect(d(2026, 8, 6), d(2026, 8, 6));
      expect(d(2026, 8, 6).hashCode, d(2026, 8, 6).hashCode);
      // Which is what lets the streak engine keep completed days in a Set.
      expect(<DateOnly>{d(2026, 8, 6), d(2026, 8, 6)}.length, 1);
    });
  });

  group('Weekday', () {
    test('maps to and from ISO numbers', () {
      expect(Weekday.fromIso(1), Weekday.monday);
      expect(Weekday.fromIso(7), Weekday.sunday);
      expect(Weekday.monday.isoValue, 1);
    });

    test('refuses numbers outside 1..7 instead of clamping', () {
      expect(() => Weekday.fromIso(0), throwsRangeError);
      expect(() => Weekday.fromIso(8), throwsRangeError);
    });

    test('all holds the seven days', () {
      expect(Weekday.all.length, 7);
    });
  });
}
