import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'config/di/app_bootstrap.dart';
import 'config/di/app_dependencies.dart';
import 'config/l10n/app_locales.dart';
import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/entries_repository.dart';
import 'domain/repositories/habits_repository.dart';
import 'l10n/generated/app_localizations.dart';

/// Application entry point.
///
/// Async because Firebase and the anonymous sign-in have to complete before
/// the first frame; a habit tapped in the first second must land under a real
/// uid like every other one.
Future<void> main() async {
  final AppDependencies dependencies = await AppBootstrap.run();
  runApp(HabitTrackerApp(dependencies: dependencies));
}

/// Root widget: wires the repositories, the theme, the languages and the
/// router together.
class HabitTrackerApp extends StatefulWidget {
  /// Creates the root widget over an already-built dependency graph.
  ///
  /// Injected rather than built here so tests can mount the app over fakes
  /// without Firebase anywhere in sight.
  const HabitTrackerApp({required this.dependencies, super.key});

  /// The repositories the widget tree may use.
  final AppDependencies dependencies;

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
    // Repositories are provided above MaterialApp so every route can reach
    // them. Blocs are not created here: each screen owns its own, per §7.
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<AuthRepository>.value(
          value: widget.dependencies.authRepository,
        ),
        RepositoryProvider<HabitsRepository>.value(
          value: widget.dependencies.habitsRepository,
        ),
        RepositoryProvider<EntriesRepository>.value(
          value: widget.dependencies.entriesRepository,
        ),
      ],
      child: MaterialApp.router(
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
        // No `locale` override either: the app follows the device language
        // until the settings screen can offer a switch and persist it.
        routerConfig: _router,
      ),
    );
  }
}
