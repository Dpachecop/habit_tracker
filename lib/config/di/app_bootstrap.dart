import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'app_dependencies.dart';

/// Everything that has to happen before the first frame.
///
/// Kept out of `main.dart` so the sequence is testable and readable on its own:
/// initialize Firebase, turn on the offline cache, make sure there is a signed-
/// in user, then build the dependency graph.
abstract final class AppBootstrap {
  /// Runs startup and returns the wired dependencies.
  ///
  /// Throws if Firebase cannot start. That is deliberate — an app that silently
  /// carries on without persistence would look like it is saving habits and
  /// lose every one of them.
  static Future<AppDependencies> run() async {
    WidgetsFlutterBinding.ensureInitialized();

    // No `options:` argument, and that is a deliberate coupling decision.
    //
    // `flutterfire configure` also writes `lib/firebase_options.dart`, but the
    // three generated config files are gitignored — the repository is public
    // and they identify the project. Importing the Dart one would make
    // `flutter analyze` and `flutter test` fail on a fresh clone over a file
    // that is not in the repository.
    //
    // Going without it costs nothing here: this app targets android and ios,
    // where the native SDKs read google-services.json and
    // GoogleService-Info.plist themselves at build time. Only a real device
    // build needs them, which was already true. A web target would be the one
    // case that forces DefaultFirebaseOptions back in.
    await Firebase.initializeApp();

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    // The whole offline story of §6.1, in one setting: writes made without a
    // network are queued locally and replayed on reconnect, and reads come
    // from the cache. It is the reason this app needs no sync engine.
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    final AppDependencies dependencies = AppDependencies.firebase(
      auth: FirebaseAuth.instance,
      firestore: firestore,
    );

    // Anonymous sign-in before the first frame: every document is written
    // under a real uid from the very first tap, so the login screen built in
    // the last phase has nothing to migrate (§6.2).
    await dependencies.authRepository.signInAnonymously();

    return dependencies;
  }
}
