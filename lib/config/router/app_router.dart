import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/l10n/l10n_extensions.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';
import '../../presentation/screens/shell/placeholder_screen.dart';

/// Builds the app's route table.
///
/// Declared as a function rather than a top-level constant because the auth
/// guard added in the final phase needs the session stream injected here, and a
/// `const` router could not take it.
abstract final class AppRouter {
  /// Path of the analytics tab. Its screen arrives in phase 6.
  static const String analyticsPath = '/analytics';

  /// Path of the settings tab.
  static const String settingsPath = '/settings';

  /// Path of the profile tab. Its screen arrives with the account, phase 7.
  static const String profilePath = '/profile';

  /// Creates the router used by the root `MaterialApp`.
  static GoRouter create() {
    return GoRouter(
      initialLocation: HomeScreen.routePath,
      routes: <RouteBase>[
        // A *stateful* shell, not a plain one: each tab keeps its own navigation
        // stack and scroll offset, so switching away from a scrolled habit list
        // and back does not reset it.
        StatefulShellRoute.indexedStack(
          builder:
              (
                BuildContext context,
                GoRouterState state,
                StatefulNavigationShell shell,
              ) => AppShell(navigationShell: shell),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: HomeScreen.routePath,
                  name: HomeScreen.routeName,
                  builder:
                      (BuildContext context, GoRouterState state) =>
                          const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: analyticsPath,
                  builder:
                      (BuildContext context, GoRouterState state) =>
                          PlaceholderScreen(
                            title: context.l10n.navAnalytics,
                            icon: Icons.bar_chart_rounded,
                          ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: settingsPath,
                  builder:
                      (BuildContext context, GoRouterState state) =>
                          PlaceholderScreen(
                            title: context.l10n.navSettings,
                            icon: Icons.settings_rounded,
                          ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: profilePath,
                  builder:
                      (BuildContext context, GoRouterState state) =>
                          PlaceholderScreen(
                            title: context.l10n.navProfile,
                            icon: Icons.person_rounded,
                          ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
