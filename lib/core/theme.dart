import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';
import 'typography.dart';

/// Application theme for Orbit.
/// Material 3 is explicitly disabled where it fights custom surfaces & motion.
abstract final class OrbitTheme {
  static ThemeData get dark {
    final baseTextTheme = TextTheme(
      displayLarge: OrbitTypography.display,
      headlineLarge: OrbitTypography.h1,
      headlineMedium: OrbitTypography.h2,
      titleMedium: OrbitTypography.h3,
      bodyMedium: OrbitTypography.body,
      bodySmall: OrbitTypography.bodyS,
      labelSmall: OrbitTypography.caption,
      labelLarge: OrbitTypography.chip,
    );

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: OrbitTokens.bg,
      canvasColor: OrbitTokens.bg,
      cardColor: OrbitTokens.surface2,
      dividerColor: OrbitTokens.surface4,
      primaryColor: OrbitTokens.accent,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: OrbitTokens.accent.withValues(alpha: 0.2),
      colorScheme: const ColorScheme.dark(
        primary: OrbitTokens.accent,
        onPrimary: OrbitTokens.bg,
        secondary: OrbitTokens.amber,
        onSecondary: OrbitTokens.bg,
        surface: OrbitTokens.surface1,
        onSurface: OrbitTokens.textPrimary,
        error: OrbitTokens.accentHot,
        onError: OrbitTokens.textPrimary,
      ),
      textTheme: baseTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: OrbitTokens.bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      iconTheme: const IconThemeData(
        color: OrbitTokens.textPrimary,
        size: 24,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(OrbitTokens.surface4),
        radius: const Radius.circular(OrbitTokens.radiusChip),
      ),
    );
  }
}
