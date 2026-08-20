import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n_extensions.dart';

/// The four-tab frame the whole app lives in.
///
/// Built now, in the phase that only fills the first tab, on purpose. The bar
/// changes the geometry of every screen above it — bottom padding, safe areas,
/// where a floating button can sit — and retrofitting it later would mean
/// re-laying-out work that was already finished. Three tabs are placeholders
/// until their phase arrives, which is honest and cheap; a Home built without
/// the bar and then squeezed into it later is neither.
class AppShell extends StatelessWidget {
  /// [navigationShell] comes from go_router's stateful shell, which keeps each
  /// tab's navigation stack and scroll position alive across switches.
  const AppShell({required this.navigationShell, super.key});

  /// The shell go_router hands over.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // `initialLocation: true` when re-tapping the current tab pops it back
        // to its root, which is what every platform's tab bar does.
        onDestinationSelected:
            (int index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: context.l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: context.l10n.navAnalytics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: context.l10n.navSettings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: context.l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
