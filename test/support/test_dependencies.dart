import 'package:habit_tracker/config/di/app_dependencies.dart';
import 'package:habit_tracker/domain/repositories/auth_repository.dart';
import 'package:habit_tracker/domain/repositories/entries_repository.dart';
import 'package:habit_tracker/domain/repositories/habits_repository.dart';
import 'package:mocktail/mocktail.dart';

/// A stand-in for `AuthRepository`.
class MockAuthRepository extends Mock implements AuthRepository {}

/// A stand-in for `HabitsRepository`.
class MockHabitsRepository extends Mock implements HabitsRepository {}

/// A stand-in for `EntriesRepository`.
class MockEntriesRepository extends Mock implements EntriesRepository {}

/// A dependency graph made entirely of mocks.
///
/// Lets a widget test mount the whole app without Firebase being initialized
/// anywhere. That the root widget takes its dependencies as a parameter is what
/// makes this possible at all — and the reason it does.
AppDependencies testDependencies({
  AuthRepository? auth,
  HabitsRepository? habits,
  EntriesRepository? entries,
}) => AppDependencies(
  authRepository: auth ?? MockAuthRepository(),
  habitsRepository: habits ?? MockHabitsRepository(),
  entriesRepository: entries ?? MockEntriesRepository(),
);
