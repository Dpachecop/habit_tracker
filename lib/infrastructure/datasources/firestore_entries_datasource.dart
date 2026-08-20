import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/datasources/entries_datasource.dart';
import '../../domain/entities/date_only.dart';
import '../../domain/entities/habit_entry.dart';
import '../errors/failure_mapper.dart';
import 'firestore_paths.dart';
import '../mappers/habit_entry_mapper.dart';
import '../models/habit_entry_dto.dart';

/// Check-ins stored flat under `users/{uid}/entries`.
///
/// Flat rather than nested under each habit, because the two queries the app
/// actually makes pull along different axes: the home screen wants *every*
/// habit's entries for today, the reports want *one* habit's entries over a
/// range (`ARCHITECTURE.md` §6.3). Nesting would force a collection group query
/// for the first one.
///
/// Range queries work because dates are stored as `yyyy-MM-dd`: that format
/// sorts lexicographically in the same order as chronologically, which is the
/// whole reason to prefer it over a timestamp here.
final class FirestoreEntriesDatasource implements EntriesDatasource {
  /// [currentUserId] returns the signed-in uid, or `null` when there is none.
  FirestoreEntriesDatasource({
    required FirebaseFirestore firestore,
    required String? Function() currentUserId,
  }) : _firestore = firestore,
       _currentUserId = currentUserId;

  final FirebaseFirestore _firestore;
  final String? Function() _currentUserId;

  /// The current user's entry collection.
  ///
  /// Throws [NotAuthenticatedException] when signed out.
  CollectionReference<Map<String, dynamic>> get _collection {
    final String? uid = _currentUserId();
    if (uid == null) throw const NotAuthenticatedException();
    return _firestore.collection(FirestorePaths.entriesOf(uid));
  }

  @override
  Stream<List<HabitEntry>> watchEntriesOn(DateOnly date) {
    return _collection
        .where('date', isEqualTo: date.toIso8601())
        .snapshots()
        .map(_toEntities);
  }

  @override
  Stream<List<HabitEntry>> watchEntriesForHabit(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  }) {
    return _habitQuery(
      habitId,
      from: from,
      to: to,
    ).snapshots().map(_toEntities);
  }

  @override
  Future<List<HabitEntry>> entriesForHabit(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _habitQuery(habitId, from: from, to: to).get();
    return _toEntities(snapshot);
  }

  @override
  Future<void> putEntry(HabitEntry entry) async {
    final HabitEntryDto dto = HabitEntryMapper.toDto(entry);
    // The id is derived from habit and day, so checking the same day twice
    // rewrites one document instead of creating a second.
    await _collection.doc(dto.documentId).set(dto.toMap());
  }

  @override
  Future<void> deleteEntry(String habitId, DateOnly date) async {
    await _collection
        .doc(HabitEntryDto.documentIdFor(habitId, date.toIso8601()))
        .delete();
  }

  /// Builds the habit + optional date-window query.
  ///
  /// Needs the composite index on `(habitId asc, date asc)` declared in
  /// `firestore.indexes.json`; Firestore refuses the range filter without it.
  Query<Map<String, dynamic>> _habitQuery(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  }) {
    Query<Map<String, dynamic>> query = _collection.where(
      'habitId',
      isEqualTo: habitId,
    );
    if (from != null) {
      query = query.where('date', isGreaterThanOrEqualTo: from.toIso8601());
    }
    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: to.toIso8601());
    }
    return query.orderBy('date');
  }

  /// Maps a snapshot to entities.
  static List<HabitEntry> _toEntities(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) =>
      snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                HabitEntryMapper.toEntity(HabitEntryDto.fromMap(doc.data())),
          )
          .toList();
}
