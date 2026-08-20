import 'package:fpdart/fpdart.dart';

import '../failures/failure.dart';

/// Session access.
///
/// The app signs in anonymously on first launch so every document has a real
/// owner from day one, long before there is a login screen. The last phase then
/// turns that anonymous account into a real one **keeping the same uid**, so
/// nothing recorded beforehand has to be migrated (`ARCHITECTURE.md` §6.2).
abstract interface class AuthRepository {
  /// The signed-in user's id, or `null` before the first sign-in completes.
  String? get currentUserId;

  /// Emits the user id on every session change, `null` when signed out.
  ///
  /// The router listens to this to decide what to show; a stream keeps that
  /// decision reactive instead of a check made once at startup.
  Stream<String?> watchUserId();

  /// Signs in anonymously, or returns the existing session's id if there
  /// already is one. Safe to call on every launch.
  Future<Either<Failure, String>> signInAnonymously();
}
