import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:habit_tracker/domain/failures/failure.dart';
import 'package:habit_tracker/infrastructure/repositories/firebase_auth_repository.dart';

void main() {
  test('signs in anonymously and reports the uid', () async {
    final MockFirebaseAuth auth = MockFirebaseAuth();
    final FirebaseAuthRepository repository = FirebaseAuthRepository(auth);

    final Either<Failure, String> result = await repository.signInAnonymously();

    expect(result.isRight(), isTrue);
    expect(repository.currentUserId, isNotNull);
  });

  test('signing in twice keeps the same uid', () async {
    // Startup calls this unconditionally on every launch. A second anonymous
    // account would abandon the first uid and everything stored under it.
    final MockFirebaseAuth auth = MockFirebaseAuth();
    final FirebaseAuthRepository repository = FirebaseAuthRepository(auth);

    final String? first =
        (await repository.signInAnonymously()).getRight().toNullable();
    final String? second =
        (await repository.signInAnonymously()).getRight().toNullable();

    expect(first, isNotNull);
    expect(second, first);
  });

  test('reports no user before the first sign-in', () {
    expect(FirebaseAuthRepository(MockFirebaseAuth()).currentUserId, isNull);
  });

  test('emits the uid when the session starts', () async {
    final MockFirebaseAuth auth = MockFirebaseAuth();
    final FirebaseAuthRepository repository = FirebaseAuthRepository(auth);

    final Future<String?> signedIn = repository.watchUserId().firstWhere(
      (String? uid) => uid != null,
    );
    await repository.signInAnonymously();

    expect(await signedIn, isNotNull);
  });
}
