import 'package:flutter/material.dart';

/// Royal Violet SaaS palette
abstract final class AppColors {
  static const Color primary = Color(0xFF4C1D95);
  static const Color primaryAccent = Color(0xFF7C3AED);
  static const Color lightAccent = Color(0xFF8B5CF6);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color primaryContainer = Color(0xFFEDE9FE);
  static const Color onPrimaryContainer = Color(0xFF4C1D95);

  static const Color secondary = Color(0xFF7C3AED);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFEDE9FE);
  static const Color onSecondaryContainer = Color(0xFF4C1D95);

  static const Color tertiary = lightAccent;
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFF5F3FF);
  static const Color onTertiaryContainer = Color(0xFF4C1D95);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F3FF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEDE9FE);

  static const Color onSurface = Color(0xFF1F1535);
  static const Color onSurfaceVariant = Color(0xFF6B7280);

  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF450A0A);

  static const Color outline = border;
  static const Color outlineVariant = Color(0xFFE9E5F5);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F3FF);
  static const Color surfaceContainer = Color(0xFFF5F3FF);
  static const Color surfaceContainerHigh = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFEDE9FE);
  static const Color surfaceAlt = Color(0xFFF5F3FF);

  static const Color success = Color(0xFF065F46);
  static const Color warning = Color(0xFF92400E);
  static const Color danger = error;
  static const Color statusActive = success;
  static const Color statusExpired = error;
  static const Color statusPending = warning;
  static const Color statusInactive = Color(0xFF9CA3AF);

  static const Color textPrimary = Color(0xFF1F1535);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  static const Color bottomNavSelected = primary;
  static const Color bottomNavUnselected = Color(0xFF9CA3AF);

  /// Status chips (background, on-background text)
  static const Color successChipBg = Color(0xFFD1FAE5);
  static const Color successChipText = Color(0xFF065F46);
  static const Color pendingChipBg = Color(0xFFFEF3C7);
  static const Color pendingChipText = Color(0xFF92400E);
  static const Color processingChipBg = Color(0xFFDBEAFE);
  static const Color processingChipText = Color(0xFF1E40AF);
  static const Color outForDeliveryChipBg = Color(0xFFEDE9FE);
  static const Color outForDeliveryChipText = Color(0xFF4C1D95);
  static const Color deliveredChipBg = Color(0xFFD1FAE5);
  static const Color deliveredChipText = Color(0xFF065F46);

  static const Color cookingChipBg = processingChipBg;
  static const Color cookingChipText = processingChipText;

  static const Color shimmerBase = Color(0xFFEDE9FE);
  static const Color shimmerHighlight = Color(0xFFF5F3FF);

  static const Color primaryLight = lightAccent;
  static const Color inverseSurface = textPrimary;
  static const Color onInverseSurface = surface;
  static const Color inversePrimary = primaryContainer;

  static const Color trendUp = Color(0xFF16A34A);
  static const Color trendDown = Color(0xFFDC2626);
}
