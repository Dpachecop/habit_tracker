import 'package:cloud_firestore/cloud_firestore.dart';

/// The wire shape of a check-in document.
///
/// The document id is `{habitId}_{yyyy-MM-dd}` and both parts are *also* stored
/// as fields. That duplication is deliberate: Firestore cannot query on a
/// substring of the id, and the home screen needs "every entry on this date"
/// while the reports need "this habit's entries in this range"
/// (`ARCHITECTURE.md` §6.3). The id gives idempotency, the fields give queries.
final class HabitEntryDto {
  /// Builds a DTO from already-decoded values.
  const HabitEntryDto({
    required this.habitId,
    required this.date,
    required this.completedAt,
  });

  /// Reads a document. Throws [FormatException] on a malformed one.
  factory HabitEntryDto.fromMap(Map<String, dynamic> data) {
    final Object? habitId = data['habitId'];
    final Object? date = data['date'];
    final Object? completedAt = data['completedAt'];
    if (habitId is! String || date is! String) {
      throw FormatException('Malformed entry: $data');
    }
    return HabitEntryDto(
      habitId: habitId,
      date: date,
      completedAt: switch (completedAt) {
        final Timestamp value => value.toDate().toUtc(),
        final DateTime value => value.toUtc(),
        _ => throw FormatException('Malformed entry timestamp: $completedAt'),
      },
    );
  }

  /// Reads a snapshot.
  factory HabitEntryDto.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      throw FormatException('Entry ${snapshot.id} has no data');
    }
    return HabitEntryDto.fromMap(data);
  }

  /// The habit this check-in belongs to.
  final String habitId;

  /// The completed day, `yyyy-MM-dd`.
  final String date;

  /// When it was recorded, UTC.
  final DateTime completedAt;

  /// The deterministic document id.
  String get documentId => documentIdFor(habitId, date);

  /// The document body.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'habitId': habitId,
    'date': date,
    'completedAt': Timestamp.fromDate(completedAt),
  };

  /// Builds the document id from its parts.
  ///
  /// Static so the datasource can address a document for deletion without
  /// having to read it first.
  static String documentIdFor(String habitId, String date) =>
      '${habitId}_$date';
}
