import 'dart:async';
import 'dart:io';

// FirebaseException is declared in firebase_core and re-exported here; a
// direct firebase_core import would be flagged as redundant.
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/failures/failure.dart';

/// Raised when an operation needs a signed-in user and there is none.
///
/// Its own type rather than a `StateError`, so the mapper can recognize it
/// without pattern-matching on a message string.
final class NotAuthenticatedException implements Exception {
  /// Creates the exception.
  const NotAuthenticatedException();

  @override
  String toString() => 'NotAuthenticatedException: no signed-in user';
}

/// Turns whatever infrastructure threw into a domain [Failure].
///
/// The single place in the app where a `FirebaseException` is allowed to be
/// mentioned. Above this line nothing knows Firebase exists, which is what
/// makes the persistence choice reversible (`ARCHITECTURE.md` §5, §6).
abstract final class FailureMapper {
  /// Maps [error] to a [Failure], keeping the original as the failure's cause.
  ///
  /// Unrecognized errors become [UnknownFailure] rather than being rethrown:
  /// a repository whose contract is `Either<Failure, T>` must not be able to
  /// throw, or every caller would need a try/catch on top of the fold.
  static Failure from(Object error, [StackTrace? stackTrace]) {
    return switch (error) {
      NotAuthenticatedException() => PermissionFailure(cause: error),
      FirebaseAuthException() => _fromAuthCode(error),
      FirebaseException() => _fromFirestoreCode(error),
      TimeoutException() => NetworkFailure(cause: error),
      SocketException() => NetworkFailure(cause: error),
      // A FormatException here means a stored document no longer matches what
      // the mappers expect. Not "unknown" in spirit, but the sealed set of
      // failures has no better member and inventing one would change §5.
      FormatException() => UnknownFailure(cause: error),
      _ => UnknownFailure(cause: error),
    };
  }

  /// Maps a Firestore error code.
  static Failure _fromFirestoreCode(FirebaseException error) => switch (error
      .code) {
    'permission-denied' => PermissionFailure(cause: error),
    'unauthenticated' => PermissionFailure(cause: error),
    'not-found' => NotFoundFailure(cause: error),
    // 'unavailable' is what Firestore reports when it cannot reach the
    // backend. With offline persistence on it is usually invisible — the
    // write is queued — so reaching here means a read that had no cache.
    'unavailable' => NetworkFailure(cause: error),
    'deadline-exceeded' => NetworkFailure(cause: error),
    'aborted' => NetworkFailure(cause: error),
    _ => UnknownFailure(cause: error),
  };

  /// Maps a Firebase Auth error code.
  static Failure _fromAuthCode(FirebaseAuthException error) => switch (error
      .code) {
    'network-request-failed' => NetworkFailure(cause: error),
    'user-not-found' => NotFoundFailure(cause: error),
    'operation-not-allowed' => PermissionFailure(cause: error),
    _ => UnknownFailure(cause: error),
  };
}
