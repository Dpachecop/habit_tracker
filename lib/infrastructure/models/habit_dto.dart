import 'package:cloud_firestore/cloud_firestore.dart';

/// The wire shape of a habit document, one field per stored key.
///
/// It exists so that the Firestore document format and the domain entity can
/// change independently. `Habit` is free to hold a sealed `HabitSchedule` and a
/// `DateOnly`; the document has to hold strings and numbers, and this is where
/// that translation stops being the entity's problem.
///
/// Dates are stored as `yyyy-MM-dd` strings rather than timestamps: they are
/// calendar days, not instants, and a timestamp would silently reintroduce the
/// timezone that `DateOnly` exists to remove. As a bonus they sort and range
/// query lexicographically, which is exactly what the reports need.
final class HabitDto {
  /// Builds a DTO from already-decoded values.
  const HabitDto({
    required this.id,
    required this.name,
    required this.category,
    required this.colorSlot,
    required this.scheduleHistory,
    required this.rangeStart,
    required this.createdAt,
    required this.updatedAt,
    this.rangeEnd,
    this.timeWindowStartMinute,
    this.timeWindowEndMinute,
    this.isArchived = false,
  });

  /// Reads a document.
  ///
  /// Throws [FormatException] on a missing or mistyped field instead of
  /// defaulting: a habit with no schedule history is not a habit with an empty
  /// one, and quietly inventing values would corrupt streaks rather than
  /// surface the problem. The repository turns the throw into a `Failure`.
  factory HabitDto.fromMap(String id, Map<String, dynamic> data) {
    return HabitDto(
      id: id,
      name: _string(data, 'name'),
      category: _string(data, 'category'),
      colorSlot: _string(data, 'colorSlot'),
      scheduleHistory:
          _list(data, 'scheduleHistory')
              .map(
                (Object? entry) =>
                    Map<String, dynamic>.from(entry! as Map<Object?, Object?>),
              )
              .toList(),
      rangeStart: _string(data, 'rangeStart'),
      rangeEnd: data['rangeEnd'] as String?,
      timeWindowStartMinute: (data['timeWindowStartMinute'] as num?)?.toInt(),
      timeWindowEndMinute: (data['timeWindowEndMinute'] as num?)?.toInt(),
      createdAt: _timestamp(data, 'createdAt'),
      updatedAt: _timestamp(data, 'updatedAt'),
      isArchived: data['isArchived'] as bool? ?? false,
    );
  }

  /// Reads a snapshot, using its id as the habit id.
  ///
  /// The id is never duplicated inside the document — one copy cannot disagree
  /// with itself.
  factory HabitDto.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      throw FormatException('Habit ${snapshot.id} has no data');
    }
    return HabitDto.fromMap(snapshot.id, data);
  }

  /// Document id.
  final String id;

  /// Habit name as typed by the user.
  final String name;

  /// `HabitCategory.name`.
  final String category;

  /// `HabitColorSlot.name`.
  final String colorSlot;

  /// Ordered schedule versions, each a raw map — see `HabitMapper`.
  final List<Map<String, dynamic>> scheduleHistory;

  /// First day of the range, `yyyy-MM-dd`.
  final String rangeStart;

  /// Last day of the range, `yyyy-MM-dd`, or null when open-ended.
  final String? rangeEnd;

  /// Start of the daily time window, in minutes past midnight; null = all day.
  final int? timeWindowStartMinute;

  /// End of the daily time window, in minutes past midnight; null = all day.
  final int? timeWindowEndMinute;

  /// Creation instant.
  final DateTime createdAt;

  /// Last modification instant.
  final DateTime updatedAt;

  /// Whether the habit was archived.
  final bool isArchived;

  /// The document body. The id is deliberately not included.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'category': category,
    'colorSlot': colorSlot,
    'scheduleHistory': scheduleHistory,
    'rangeStart': rangeStart,
    'rangeEnd': rangeEnd,
    'timeWindowStartMinute': timeWindowStartMinute,
    'timeWindowEndMinute': timeWindowEndMinute,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'isArchived': isArchived,
  };

  /// Reads a required string field.
  static String _string(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! String) {
      throw FormatException('Expected a string at "$key", got $value');
    }
    return value;
  }

  /// Reads a required list field.
  static List<Object?> _list(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is! List) {
      throw FormatException('Expected a list at "$key", got $value');
    }
    return value;
  }

  /// Reads a required instant, accepting the `Timestamp` Firestore returns.
  static DateTime _timestamp(Map<String, dynamic> data, String key) {
    final Object? value = data[key];
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    throw FormatException('Expected a timestamp at "$key", got $value');
  }
}
