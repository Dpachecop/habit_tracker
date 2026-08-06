import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/failures/failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../errors/guard.dart';

/// Session handling on Firebase Auth.
///
/// The app signs in anonymously on first launch so that every document has a
/// real owner from day one, long before there is a login screen. The final
/// phase upgrades that same account with `linkWithCredential`, which keeps the
/// uid — and therefore every habit and every entry already recorded
/// (`ARCHITECTURE.md` §6.2).
final class FirebaseAuthRepository implements AuthRepository {
  /// Wraps a [FirebaseAuth] instance.
  const FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<String?> watchUserId() =>
      _auth.authStateChanges().map((User? user) => user?.uid);

  @override
  Future<Either<Failure, String>> signInAnonymously() =>
      Guard.futureEither(() async {
        // Idempotent on purpose: startup calls this unconditionally, and a
        // second anonymous sign-in would abandon the previous uid along with
        // everything stored under it.
        final User? existing = _auth.currentUser;
        if (existing != null) return Right<Failure, String>(existing.uid);

        final UserCredential credential = await _auth.signInAnonymously();
        final User? user = credential.user;
        if (user == null) {
          return const Left<Failure, String>(UnknownFailure());
        }
        return Right<Failure, String>(user.uid);
      });
}
