import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/datasources/habits_datasource.dart';
import '../../domain/entities/habit.dart';
import '../errors/failure_mapper.dart';
import 'firestore_paths.dart';
import '../mappers/habit_mapper.dart';
import '../models/habit_dto.dart';

/// Habits stored under `users/{uid}/habits`.
///
/// The uid arrives through a callback rather than being captured at
/// construction: the anonymous session is created during startup and, from the
/// final phase on, can be replaced by a real account. A datasource holding a
/// stale uid would keep writing to the previous user's tree.
final class FirestoreHabitsDatasource implements HabitsDatasource {
  /// [currentUserId] returns the signed-in uid, or `null` when there is none.
  FirestoreHabitsDatasource({
    required FirebaseFirestore firestore,
    required String? Function() currentUserId,
  }) : _firestore = firestore,
       _currentUserId = currentUserId;

  final FirebaseFirestore _firestore;
  final String? Function() _currentUserId;

  /// The current user's habit collection.
  ///
  /// Throws [NotAuthenticatedException] when signed out, which the repository
  /// turns into a `PermissionFailure`. Returning an empty stream instead would
  /// look to the UI exactly like a user with no habits.
  CollectionReference<Map<String, dynamic>> get _collection {
    final String? uid = _currentUserId();
    if (uid == null) throw const NotAuthenticatedException();
    return _firestore.collection(FirestorePaths.habitsOf(uid));
  }

  @override
  Stream<List<Habit>> watchHabits({bool includeArchived = false}) {
    Query<Map<String, dynamic>> query = _collection;
    if (!includeArchived) {
      query = query.where('isArchived', isEqualTo: false);
    }
    // Ordered here rather than in the UI so every consumer sees the same list
    // and Firestore does the work.
    return query
        .orderBy('createdAt')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.docs
                  .map(
                    (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                        HabitMapper.toEntity(
                          HabitDto.fromMap(doc.id, doc.data()),
                        ),
                  )
                  .toList(),
        );
  }

  @override
  Future<Habit?> findHabit(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection.doc(id).get();
    if (!snapshot.exists) return null;
    return HabitMapper.toEntity(HabitDto.fromSnapshot(snapshot));
  }

  @override
  Future<void> upsertHabit(Habit habit) async {
    // A full overwrite, not a merge: the habit entity is the whole truth, and
    // merging would leave fields from a previous shape lying around.
    await _collection.doc(habit.id).set(HabitMapper.toDto(habit).toMap());
  }

  @override
  Future<void> archiveHabit(String id) async {
    await _collection.doc(id).update(<String, Object?>{
      'isArchived': true,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> restoreHabit(String id) async {
    await _collection.doc(id).update(<String, Object?>{
      'isArchived': false,
      'updatedAt': Timestamp.now(),
    });
  }
}
