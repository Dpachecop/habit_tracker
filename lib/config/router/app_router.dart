import 'package:go_router/go_router.dart';

import '../../presentation/screens/home/home_screen.dart';

/// Builds the app's route table.
///
/// Declared as a function rather than a top-level constant because the auth
/// guard added in the final phase needs the session stream injected here, and a
/// `const` router could not take it.
abstract final class AppRouter {
  /// Creates the router used by the root `MaterialApp`.
  static GoRouter create() {
    return GoRouter(
      initialLocation: HomeScreen.routePath,
      routes: <RouteBase>[
        GoRoute(
          path: HomeScreen.routePath,
          name: HomeScreen.routeName,
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    );
  }
}
