import 'package:habit_tracker/config/di/app_dependencies.dart';
import 'package:habit_tracker/domain/repositories/auth_repository.dart';
import 'package:habit_tracker/domain/repositories/entries_repository.dart';
import 'package:habit_tracker/domain/repositories/habits_repository.dart';
import 'package:habit_tracker/infrastructure/repositories/entries_repository_impl.dart';
import 'package:habit_tracker/infrastructure/repositories/habits_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import 'in_memory_datasources.dart';

/// A stand-in for `AuthRepository`.
class MockAuthRepository extends Mock implements AuthRepository {}

/// A stand-in for `HabitsRepository`.
class MockHabitsRepository extends Mock implements HabitsRepository {}

/// A stand-in for `EntriesRepository`.
class MockEntriesRepository extends Mock implements EntriesRepository {}

/// A dependency graph made entirely of mocks.
///
/// For tests that never let the app read anything. Mounting the whole app over
/// mocks is possible at all because the root widget takes its dependencies as a
/// parameter — which is the reason it does.
AppDependencies testDependencies({
  AuthRepository? auth,
  HabitsRepository? habits,
  EntriesRepository? entries,
}) => AppDependencies(
  authRepository: auth ?? MockAuthRepository(),
  habitsRepository: habits ?? MockHabitsRepository(),
  entriesRepository: entries ?? MockEntriesRepository(),
);

/// A dependency graph over storage that actually works, in memory.
///
/// The **real** repository implementations on top of in-memory datasources, so a
/// widget test exercises the same code path production does — including the
/// completion rule refusing a write. Mocks would let a test assert that the
/// screen renders whatever it was handed, which proves much less.
final class InMemoryDependencies {
  /// Wires the graph. Call [dispose] when the test ends.
  InMemoryDependencies()
    : habitsDatasource = InMemoryHabitsDatasource(),
      entriesDatasource = InMemoryEntriesDatasource() {
    dependencies = AppDependencies(
      authRepository: MockAuthRepository(),
      habitsRepository: HabitsRepositoryImpl(habitsDatasource),
      entriesRepository: EntriesRepositoryImpl(entriesDatasource),
    );
  }

  /// The habit store, exposed so a test can seed it.
  final InMemoryHabitsDatasource habitsDatasource;

  /// The entry store, exposed so a test can seed it.
  final InMemoryEntriesDatasource entriesDatasource;

  /// What the app under test receives.
  late final AppDependencies dependencies;

  /// Pushes the current contents into both streams.
  ///
  /// Needed after seeding: the datasources are broadcast controllers with no
  /// replay, so a subscriber that arrives later hears nothing until something is
  /// emitted. Production has Firestore doing this; here the test says when.
  void emit() {
    habitsDatasource.emit();
    entriesDatasource.emit();
  }

  /// Closes both controllers.
  Future<void> dispose() async {
    await habitsDatasource.dispose();
    await entriesDatasource.dispose();
  }
}
