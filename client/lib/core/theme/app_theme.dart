import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static const double cardRadius = 16;
  static const double inputRadius = 12;
  static const double buttonRadius = 12;

  static TextStyle get _appBarTitleStyle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
      );

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.outlineVariant,
      shadow: AppColors.shadow,
      scrim: AppColors.scrim,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.onInverseSurface,
      inversePrimary: AppColors.inversePrimary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
    );
    final textTheme = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        displayMedium: textTheme.displayMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        displaySmall: textTheme.displaySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: textTheme.headlineLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineSmall: textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        titleLarge: textTheme.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleSmall: textTheme.titleSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        bodySmall: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        labelLarge: textTheme.labelLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        labelMedium: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        labelSmall: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        titleTextStyle: _appBarTitleStyle,
        iconTheme: const IconThemeData(color: AppColors.onPrimary, size: 24),
        actionsIconTheme: const IconThemeData(color: AppColors.onPrimary, size: 24),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: AppColors.shadow.withValues(alpha: 0.04),
        color: AppColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(inputRadius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryAccent),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.bottomNavSelected,
        unselectedItemColor: AppColors.bottomNavUnselected,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppColors.surface,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryAccent;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAccent.withValues(alpha: 0.45);
          }
          return null;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColors.border),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainer,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceContainerHighest,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: AppColors.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.border),
        showCheckmark: false,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
      ),
    );
  }
}
