import 'package:flutter/material.dart';

import '../../../config/theme/app_dimens.dart';
import '../../l10n/l10n_extensions.dart';

/// Stands in for a tab whose phase has not been built.
///
/// A real screen with the real chrome rather than a blank `Container`, so the
/// navigation bar can be used and reviewed now while Analytics, Settings and
/// Profile wait for phases 6 and 7. It says "coming soon" in both languages
/// instead of looking broken.
class PlaceholderScreen extends StatelessWidget {
  /// [title] is the already-localized tab name.
  const PlaceholderScreen({required this.title, required this.icon, super.key});

  /// Heading shown in the app bar.
  final String title;

  /// The tab's glyph, repeated large in the body.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        titleTextStyle: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.comingSoon,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
