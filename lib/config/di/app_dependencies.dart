import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/entries_repository.dart';
import '../../domain/repositories/habits_repository.dart';
import '../../infrastructure/datasources/firestore_entries_datasource.dart';
import '../../infrastructure/datasources/firestore_habits_datasource.dart';
import '../../infrastructure/repositories/entries_repository_impl.dart';
import '../../infrastructure/repositories/firebase_auth_repository.dart';
import '../../infrastructure/repositories/habits_repository_impl.dart';

/// Everything the widget tree is allowed to depend on.
///
/// The composition root: the only place that names both a concrete Firestore
/// datasource and the domain contract it satisfies. Above this line the app
/// sees three interfaces and cannot tell what is behind them — which is what
/// makes the persistence choice in §6 reversible rather than load-bearing.
///
/// A plain object rather than a service locator: the dependencies are three,
/// they are known at startup, and a locator would let any widget reach for
/// anything from anywhere.
final class AppDependencies {
  /// Builds the holder from ready-made repositories.
  ///
  /// Used directly by tests, which pass fakes; production goes through
  /// [AppDependencies.firebase].
  const AppDependencies({
    required this.authRepository,
    required this.habitsRepository,
    required this.entriesRepository,
  });

  /// Wires the real Firestore-backed stack.
  ///
  /// The datasources take a *callback* for the uid rather than the value:
  /// the session can change while the app runs — anonymous today, a real
  /// account after the final phase — and a captured uid would keep writing to
  /// the previous user's tree.
  factory AppDependencies.firebase({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) {
    final FirebaseAuthRepository authRepository = FirebaseAuthRepository(auth);
    String? currentUserId() => authRepository.currentUserId;

    return AppDependencies(
      authRepository: authRepository,
      habitsRepository: HabitsRepositoryImpl(
        FirestoreHabitsDatasource(
          firestore: firestore,
          currentUserId: currentUserId,
        ),
      ),
      entriesRepository: EntriesRepositoryImpl(
        FirestoreEntriesDatasource(
          firestore: firestore,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  /// Session.
  final AuthRepository authRepository;

  /// Habits.
  final HabitsRepository habitsRepository;

  /// Check-ins.
  final EntriesRepository entriesRepository;
}
