import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Builds the app's light and dark themes from the *Serene Habit* tokens.
///
/// Both modes come out of one private builder so a token added to one cannot be
/// forgotten in the other — the commonest way two themes drift into looking
/// like two different apps.
///
/// The color scheme is written out slot by slot rather than generated with
/// `ColorScheme.fromSeed`. Seeding would let Material invent its own steps and
/// quietly override the design's, which defeats having a token file at all.
abstract final class AppTheme {
  /// The theme used when the device is in light mode.
  static ThemeData get light => _build(Brightness.light);

  /// The theme used when the device is in dark mode.
  static ThemeData get dark => _build(Brightness.dark);

  /// Assembles a theme for the given [brightness].
  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme = isDark ? _darkScheme : _lightScheme;
    final Color ink = scheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      dividerColor: scheme.outlineVariant,
      textTheme: AppTypography.build(ink),

      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor: scheme.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.build(scheme.primary).displaySmall,
      ),

      // Cards carry the design's ambient shadow rather than a border: the plane
      // behind them is tinted and they are white, so the depth reads without an
      // outline. Flutter needs `shadowColor` plus `elevation` for this, and the
      // exact blur from the design is applied by the card widget itself, which
      // can use a BoxShadow.
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: scheme.primary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return AppTypography.build(
            selected ? scheme.onSurface : scheme.onSurfaceVariant,
          ).labelMedium!;
        }),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // Ghost style with a 1px accent border, per the design's secondary button.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          side: BorderSide(color: scheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // Pill-shaped, low-saturation background — the frequency chip.
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.lightSurfaceContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelStyle: AppTypography.build(scheme.onSurfaceVariant).labelMedium!,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark
                ? AppColors.darkSurfaceContainerHigh
                : AppColors.lightOnSurface,
        contentTextStyle:
            AppTypography.build(
              isDark ? AppColors.darkOnSurface : AppColors.lightBackground,
            ).bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  /// Light slots, straight from the token file.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.lightPrimary,
    onPrimary: AppColors.lightOnPrimary,
    primaryContainer: AppColors.lightPrimaryContainer,
    onPrimaryContainer: AppColors.lightOnPrimaryContainer,
    secondary: AppColors.lightSecondary,
    onSecondary: AppColors.lightOnSecondary,
    tertiary: AppColors.lightTertiary,
    onTertiary: AppColors.lightOnTertiary,
    tertiaryContainer: AppColors.lightTertiaryContainer,
    error: AppColors.lightError,
    onError: AppColors.lightOnError,
    errorContainer: AppColors.lightErrorContainer,
    onErrorContainer: AppColors.lightOnErrorContainer,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    surfaceContainerLow: AppColors.lightSurfaceContainerLow,
    surfaceContainer: AppColors.lightSurfaceContainer,
    surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutlineVariant,
  );

  /// Dark slots, derived as documented in [AppColors].
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    primaryContainer: AppColors.darkPrimaryContainer,
    onPrimaryContainer: AppColors.darkOnPrimaryContainer,
    secondary: AppColors.darkSecondary,
    onSecondary: AppColors.darkOnSecondary,
    tertiary: AppColors.darkTertiary,
    onTertiary: AppColors.darkOnTertiary,
    tertiaryContainer: AppColors.darkTertiaryContainer,
    error: AppColors.darkError,
    onError: AppColors.darkOnError,
    errorContainer: AppColors.darkErrorContainer,
    onErrorContainer: AppColors.darkOnErrorContainer,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    surfaceContainerLow: AppColors.darkSurfaceContainerLow,
    surfaceContainer: AppColors.darkSurfaceContainer,
    surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
  );

  /// The card shadow from the design's elevation level 1.
  ///
  /// Returned as a list so a widget can hand it straight to a `BoxDecoration`.
  /// Suppressed in dark mode: a black shadow on a dark plane is invisible, and
  /// separation there comes from the surface being lighter than the background.
  static List<BoxShadow> cardShadow(Brightness brightness) {
    if (brightness == Brightness.dark) return const <BoxShadow>[];
    return <BoxShadow>[
      BoxShadow(
        color: const Color(
          0xFF000000,
        ).withValues(alpha: AppElevation.cardOpacity),
        blurRadius: AppElevation.cardBlur,
        offset: const Offset(0, AppElevation.cardOffsetY),
      ),
    ];
  }
}
