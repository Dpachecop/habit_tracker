import 'package:flutter/material.dart';

import '../../l10n/l10n_extensions.dart';

/// The main panel: the habit list plus the year calendar underneath.
///
/// A placeholder for now — the habit list arrives with `HabitsBloc` in phase 3
/// and the year heatmap in phase 5. It exists already so the router and theme
/// have something real to render and can be verified end to end.
class HomeScreen extends StatelessWidget {
  /// Creates the main panel.
  const HomeScreen({super.key});

  /// Route path this screen is registered under.
  static const String routePath = '/';

  /// Route name used for navigation by name.
  static const String routeName = 'home';

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.homeTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.homeEmpty,
            style: text.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
