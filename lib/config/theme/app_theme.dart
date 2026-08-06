import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'habit_palette.dart';
import '../../domain/entities/habit_color_slot.dart';

/// Builds the app's light and dark themes.
///
/// Both are derived from the same neutral tokens in [AppColors] so the two
/// modes stay structurally identical and only the surfaces swap. The seed color
/// is the first habit palette slot, which keeps Material's generated accents in
/// the same family as the habit colors instead of clashing with them.
abstract final class AppTheme {
  /// The theme used when the device is in light mode.
  static ThemeData get light => _build(Brightness.light);

  /// The theme used when the device is in dark mode.
  static ThemeData get dark => _build(Brightness.dark);

  /// Assembles a theme for the given [brightness].
  ///
  /// Kept private and shared so a token added to one mode cannot be forgotten
  /// in the other — the commonest way themes drift apart.
  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: HabitPalette.of(HabitColorSlot.blue, brightness),
      brightness: brightness,
    ).copyWith(
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    );

    final Color textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      dividerColor: isDark ? AppColors.darkGridline : AppColors.lightGridline,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // A hairline ring instead of a shadow: cards sit on a plane that is
          // only slightly different, so an outline separates them more
          // honestly than elevation does.
          side: BorderSide(
            color: isDark ? AppColors.darkGridline : AppColors.lightGridline,
          ),
        ),
      ),
      textTheme: _baseTypography(
        isDark,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      listTileTheme: ListTileThemeData(
        textColor: textPrimary,
        subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 13),
      ),
    );
  }

  /// Picks the Material text theme whose default ink suits [isDark].
  ///
  /// The colors are overridden right after, but starting from the matching
  /// variant means anything not explicitly re-colored still lands readable.
  static TextTheme _baseTypography(bool isDark) {
    final Typography typography = Typography.material2021(
      platform: TargetPlatform.iOS,
    );
    return isDark ? typography.white : typography.black;
  }
}
