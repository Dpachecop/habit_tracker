import 'package:flutter/material.dart';

import '../../../../config/theme/app_dimens.dart';
import '../../../../config/theme/app_theme.dart';

/// One labelled block of the habit form.
///
/// The form is long enough that unbroken fields turn into a wall. Each section
/// is a card on the tinted plane, with its heading in the `label-caps` style the
/// design reserves for exactly this — section headers that are not actionable
/// text.
class FormSection extends StatelessWidget {
  /// [error] is shown under the content in the error color when non-null.
  const FormSection({
    required this.title,
    required this.child,
    this.error,
    super.key,
  });

  /// Already-localized heading.
  final String title;

  /// The fields.
  final Widget child;

  /// Validation message, or null when the section is fine.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String? message = error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppTheme.cardShadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: scheme.error,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
