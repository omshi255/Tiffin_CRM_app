import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static const double cardRadius = 14;
  static const double inputRadius = 10;

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
      outlineVariant: AppColors.border,
      shadow: AppColors.shadow,
      scrim: AppColors.scrim,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.surfaceAlt,
      inversePrimary: AppColors.primaryContainer,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surfaceAlt,
      surfaceContainer: AppColors.surfaceAlt,
      surfaceContainerHigh: AppColors.surfaceAlt,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
    );
    final baseTextTheme = GoogleFonts.interTextTheme();
    final headingTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.copyWith(
        displayLarge: headingTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700),
        displayMedium: headingTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
        displaySmall: headingTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        headlineLarge: headingTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        headlineMedium: headingTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineSmall: headingTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: headingTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: headingTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: headingTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
        bodySmall: baseTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        labelSmall: baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: headingTextTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: AppColors.shadow.withValues(alpha: 0.06),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(inputRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(inputRadius),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
