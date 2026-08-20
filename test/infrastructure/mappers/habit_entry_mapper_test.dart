import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/entities/habit_entry.dart';
import 'package:habit_tracker/infrastructure/mappers/habit_entry_mapper.dart';
import 'package:habit_tracker/infrastructure/models/habit_entry_dto.dart';

import '../../domain/fixtures.dart';

void main() {
  /// A check-in recorded late on a August evening, in UTC.
  final HabitEntry entry = HabitEntry(
    habitId: 'habit-1',
    date: d(2026, 8, 6),
    completedAt: DateTime.utc(2026, 8, 6, 21, 15),
  );

  test('round-trips through a document map', () {
    final HabitEntry restored = HabitEntryMapper.toEntity(
      HabitEntryDto.fromMap(HabitEntryMapper.toDto(entry).toMap()),
    );

    expect(restored, entry);
    expect(restored.completedAt, entry.completedAt);
  });

  test('stores the day as a string and the instant as a timestamp', () {
    // The two halves of ARCHITECTURE.md 3.3: the day drives every rule and has
    // no timezone, the instant is audit data and must keep one.
    final Map<String, dynamic> map = HabitEntryMapper.toDto(entry).toMap();

    expect(map['date'], '2026-08-06');
    expect(map['habitId'], 'habit-1');
    expect(map['completedAt'], isA<Timestamp>());
  });

  test('builds the deterministic document id', () {
    // Idempotency lives in this id: checking the same day twice addresses the
    // same document, so it cannot produce two entries.
    expect(HabitEntryMapper.toDto(entry).documentId, 'habit-1_2026-08-06');
    expect(
      HabitEntryDto.documentIdFor('habit-1', '2026-08-06'),
      'habit-1_2026-08-06',
    );
  });

  test(
    'keeps completedAt in UTC even if it was stored as a local DateTime',
    () {
      final HabitEntryDto dto = HabitEntryDto.fromMap(<String, dynamic>{
        'habitId': 'habit-1',
        'date': '2026-08-06',
        'completedAt': DateTime(2026, 8, 6, 21, 15),
      });

      expect(HabitEntryMapper.toEntity(dto).completedAt.isUtc, isTrue);
    },
  );

  test('a malformed document throws', () {
    expect(
      () => HabitEntryDto.fromMap(<String, dynamic>{'habitId': 'habit-1'}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => HabitEntryMapper.toEntity(
        HabitEntryDto(
          habitId: 'habit-1',
          date: 'yesterday',
          completedAt: DateTime.utc(2026),
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
