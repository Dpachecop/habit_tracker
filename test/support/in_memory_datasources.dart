import 'dart:async';

import 'package:habit_tracker/domain/datasources/entries_datasource.dart';
import 'package:habit_tracker/domain/datasources/habits_datasource.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_entry.dart';

/// In-memory datasources for the repository tests.
///
/// Mocks would work, but the repositories are being tested for *behaviour* that
/// depends on what a query returns — the completion rule reads the period's
/// entries and decides from them. Stubbing that per test would encode the
/// expected answer in the test itself, which is the one thing the test must
/// not do. These fakes store and query for real.
///
/// [failWith] turns any call into a throw, which is how the error-translation
/// tests reach the `Left` branch.
class InMemoryHabitsDatasource implements HabitsDatasource {
  /// Stored habits by id.
  final Map<String, Habit> habits = <String, Habit>{};

  /// When set, every method throws this instead of doing its job.
  Object? failWith;

  final StreamController<List<Habit>> _controller =
      StreamController<List<Habit>>.broadcast();

  /// Emits the current list to any listener.
  void _publish() => _controller.add(habits.values.toList());

  @override
  Stream<List<Habit>> watchHabits({bool includeArchived = false}) {
    final Object? error = failWith;
    if (error != null) return Stream<List<Habit>>.error(error);
    return _controller.stream.map(
      (List<Habit> all) =>
          all
              .where((Habit habit) => includeArchived || !habit.isArchived)
              .toList(),
    );
  }

  @override
  Future<Habit?> findHabit(String id) async {
    _throwIfFailing();
    return habits[id];
  }

  @override
  Future<void> upsertHabit(Habit habit) async {
    _throwIfFailing();
    habits[habit.id] = habit;
    _publish();
  }

  @override
  Future<void> archiveHabit(String id) async {
    _throwIfFailing();
    final Habit? habit = habits[id];
    if (habit != null) habits[id] = habit.copyWith(isArchived: true);
    _publish();
  }

  @override
  Future<void> restoreHabit(String id) async {
    _throwIfFailing();
    final Habit? habit = habits[id];
    if (habit != null) habits[id] = habit.copyWith(isArchived: false);
    _publish();
  }

  /// Pushes the current list into [watchHabits] listeners.
  void emit() => _publish();

  /// Releases the broadcast controller.
  Future<void> dispose() => _controller.close();

  void _throwIfFailing() {
    final Object? error = failWith;
    if (error != null) throw error;
  }
}

/// In-memory counterpart for check-ins. See [InMemoryHabitsDatasource].
class InMemoryEntriesDatasource implements EntriesDatasource {
  /// Stored entries, keyed by document id so writes are idempotent exactly as
  /// they are in Firestore.
  final Map<String, HabitEntry> entries = <String, HabitEntry>{};

  /// When set, every method throws this instead of doing its job.
  Object? failWith;

  /// How many writes have been attempted — lets a test assert that a refused
  /// completion wrote *nothing*.
  int writeCount = 0;

  @override
  Stream<List<HabitEntry>> watchEntriesOn(DateOnly date) {
    final Object? error = failWith;
    if (error != null) return Stream<List<HabitEntry>>.error(error);
    return Stream<List<HabitEntry>>.value(
      entries.values.where((HabitEntry entry) => entry.date == date).toList(),
    );
  }

  @override
  Stream<List<HabitEntry>> watchEntriesForHabit(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  }) {
    final Object? error = failWith;
    if (error != null) return Stream<List<HabitEntry>>.error(error);
    return Stream<List<HabitEntry>>.value(_query(habitId, from, to));
  }

  @override
  Future<List<HabitEntry>> entriesForHabit(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  }) async {
    _throwIfFailing();
    return _query(habitId, from, to);
  }

  @override
  Future<void> putEntry(HabitEntry entry) async {
    _throwIfFailing();
    writeCount++;
    entries['${entry.habitId}_${entry.date.toIso8601()}'] = entry;
  }

  @override
  Future<void> deleteEntry(String habitId, DateOnly date) async {
    _throwIfFailing();
    entries.remove('${habitId}_${date.toIso8601()}');
  }

  /// Applies the habit filter and the optional date window.
  List<HabitEntry> _query(String habitId, DateOnly? from, DateOnly? to) =>
      entries.values
          .where(
            (HabitEntry entry) =>
                entry.habitId == habitId &&
                (from == null || entry.date >= from) &&
                (to == null || entry.date <= to),
          )
          .toList()
        ..sort((HabitEntry a, HabitEntry b) => a.date.compareTo(b.date));

  void _throwIfFailing() {
    final Object? error = failWith;
    if (error != null) throw error;
  }
}
