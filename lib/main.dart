import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'config/l10n/app_locales.dart';
import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';

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
      // onGenerateTitle rather than title: the task-switcher label has to be
      // translated too, and it can only be read once localizations exist.
      onGenerateTitle:
          (BuildContext context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Follow the OS for now; a ThemeCubit takes over when settings ship.
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocales.delegates,
      supportedLocales: AppLocales.supported,
      // No `locale` override either: the app follows the device language until
      // the settings screen can offer a switch and somewhere to persist it.
      routerConfig: _router,
    );
  }
}
