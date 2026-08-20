import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/failures/failure.dart';
import 'package:habit_tracker/infrastructure/errors/failure_mapper.dart';

void main() {
  group('Firestore errors', () {
    /// A Firestore exception with the given code.
    FirebaseException firestoreError(String code) =>
        FirebaseException(plugin: 'cloud_firestore', code: code);

    test('permission-denied and unauthenticated become PermissionFailure', () {
      expect(
        FailureMapper.from(firestoreError('permission-denied')),
        isA<PermissionFailure>(),
      );
      expect(
        FailureMapper.from(firestoreError('unauthenticated')),
        isA<PermissionFailure>(),
      );
    });

    test('unavailable becomes NetworkFailure', () {
      expect(
        FailureMapper.from(firestoreError('unavailable')),
        isA<NetworkFailure>(),
      );
    });

    test('not-found becomes NotFoundFailure', () {
      expect(
        FailureMapper.from(firestoreError('not-found')),
        isA<NotFoundFailure>(),
      );
    });

    test('an unrecognized code becomes UnknownFailure', () {
      expect(
        FailureMapper.from(firestoreError('resource-exhausted')),
        isA<UnknownFailure>(),
      );
    });
  });

  group('auth errors', () {
    test('a lost network becomes NetworkFailure', () {
      expect(
        FailureMapper.from(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        isA<NetworkFailure>(),
      );
    });

    test('being signed out becomes PermissionFailure', () {
      // The datasources throw this when asked for a collection with no uid.
      expect(
        FailureMapper.from(const NotAuthenticatedException()),
        isA<PermissionFailure>(),
      );
    });
  });

  group('everything else', () {
    test('timeouts and socket errors become NetworkFailure', () {
      expect(
        FailureMapper.from(TimeoutException('slow')),
        isA<NetworkFailure>(),
      );
      expect(
        FailureMapper.from(const SocketException('down')),
        isA<NetworkFailure>(),
      );
    });

    test('a corrupt document becomes UnknownFailure', () {
      expect(
        FailureMapper.from(const FormatException('bad date')),
        isA<UnknownFailure>(),
      );
    });

    test('anything unrecognized still maps rather than escaping', () {
      // The contract is Either<Failure, T>. If this ever rethrew, every caller
      // would need a try/catch on top of the fold.
      expect(FailureMapper.from(Exception('who knows')), isA<UnknownFailure>());
      expect(FailureMapper.from('a bare string'), isA<UnknownFailure>());
    });

    test('the original error is kept as the cause for the log', () {
      final Exception original = Exception('boom');
      expect(FailureMapper.from(original).cause, same(original));
    });
  });

  test('every failure it produces carries a code from FailureCodes', () {
    final List<Object> errors = <Object>[
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
      const NotAuthenticatedException(),
      const FormatException('x'),
      Exception('x'),
    ];
    const Set<String> known = <String>{
      FailureCodes.network,
      FailureCodes.notFound,
      FailureCodes.permission,
      FailureCodes.cache,
      FailureCodes.unknown,
    };

    for (final Object error in errors) {
      expect(known, contains(FailureMapper.from(error).code));
    }
  });
}
