import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';

/// Application entry point.
void main() {
  runApp(const HabitTrackerApp());
}

/// Root widget: wires the theme and the router together.
///
/// Repository and bloc providers get mounted above `MaterialApp.router` from
/// phase 2 onward, once there is anything to inject.
class HabitTrackerApp extends StatefulWidget {
  /// Creates the root widget.
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  /// Built once and held in state.
  ///
  /// Recreating the router on every rebuild would throw away the navigation
  /// stack, so it must not be constructed inline in [build].
  late final GoRouter _router = AppRouter.create();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Follow the OS for now; a ThemeCubit takes over when settings ship.
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
