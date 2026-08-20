import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/infrastructure/datasources/firestore_entries_datasource.dart';
import 'package:habit_tracker/infrastructure/datasources/firestore_habits_datasource.dart';
import 'package:habit_tracker/infrastructure/datasources/firestore_paths.dart';
import 'package:habit_tracker/infrastructure/errors/failure_mapper.dart';
import 'package:mocktail/mocktail.dart';

import '../../domain/fixtures.dart';

/// Stands in for Firestore. Never actually reached by these tests: both of
/// them assert on behaviour that happens *before* the first call to it.
class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('document paths', () {
    // These strings are the security model. `firestore.rules` grants access to
    // users/{uid}/** and nothing else, so a path built one segment differently
    // does not show up as wrong data — it shows up as permission-denied, in
    // production, and nowhere before that.
    test('everything lives under the owning user', () {
      expect(FirestorePaths.habitsOf('user-1'), 'users/user-1/habits');
      expect(FirestorePaths.entriesOf('user-1'), 'users/user-1/entries');
    });

    test('documents hang off their collection', () {
      expect(
        FirestorePaths.habit('user-1', 'habit-1'),
        'users/user-1/habits/habit-1',
      );
      expect(
        FirestorePaths.entry('user-1', 'habit-1_2026-08-06'),
        'users/user-1/entries/habit-1_2026-08-06',
      );
    });

    test('entries are flat, not nested under a habit', () {
      // ARCHITECTURE.md 6.3. Nesting would force a collection group query for
      // "every habit's entries today", which is the home screen's only read.
      expect(FirestorePaths.entriesOf('user-1'), isNot(contains('/habits/')));
    });
  });

  group('signed out', () {
    test('the habits datasource refuses rather than returning nothing', () {
      // An empty result would be indistinguishable, to the UI, from a user who
      // simply has no habits — and the UI would happily render "no habits yet"
      // over somebody's real data.
      final FirestoreHabitsDatasource datasource = FirestoreHabitsDatasource(
        firestore: _MockFirestore(),
        currentUserId: () => null,
      );

      expect(
        () => datasource.findHabit('habit-1'),
        throwsA(isA<NotAuthenticatedException>()),
      );
      expect(
        () => datasource.watchHabits(),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });

    test('the entries datasource refuses too', () {
      final FirestoreEntriesDatasource datasource = FirestoreEntriesDatasource(
        firestore: _MockFirestore(),
        currentUserId: () => null,
      );

      expect(
        () => datasource.entriesForHabit('habit-1'),
        throwsA(isA<NotAuthenticatedException>()),
      );
      expect(
        () => datasource.watchEntriesOn(d(2026, 8, 6)),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });
  });
}
