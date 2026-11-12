import 'package:flutter/material.dart';

/// Design tokens for the Orbit app.
/// Pure black field, orange/amber accent glow, white rim light.
abstract final class OrbitTokens {
  // ── Colour Tokens ──────────────────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color bg = black;
  static const Color surface1 = Color(0xFF0E0E0E);
  static const Color surface2 = Color(0xFF151515);
  static const Color surface3 = Color(0xFF1F1F1F);
  static const Color surface4 = Color(0xFF2A2A2A);

  // Orbit v2 flame palette
  static const Color flameRed = Color(0xFFFF2D00);
  static const Color flame = Color(0xFFFF4D00);
  static const Color orange = Color(0xFFFF7A00);
  static const Color amber = Color(0xFFFFB000);
  static const Color crimson = Color(0xFFB81800);
  static const Color ember = Color(0xFF5C0F00);
  static const Color emberLight = Color(0xFFFFD27A);
  static const Color pinkRed = Color(0xFFFF2E63); // only for wave accents

  // Semantic aliases
  static const Color accent = orange;
  static const Color accentHot = flame;
  static const Color burnt = crimson;

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF7A7A7A);

  static const Color glassTint = Color(0x14FFFFFF); // #FFFFFF @ 8%
  static const Color glassRimStart = Color(0x8CFFFFFF); // #FFFFFF @ 55%
  static const Color glassRimMid = Color(0x0FFFFFFF); // #FFFFFF @ 6%
  static const Color glassRimEnd = Color(0x33FFFFFF); // #FFFFFF @ 20%
  static const Color pillBorder = Color(0x0FFFFFFF); // #FFFFFF @ 6%

  // Dot mascot eye gradient colours
  static const Color dotEyeTop = Color(0xFF3B6FE0);
  static const Color dotEyeBottom = Color(0xFF1D3E99);

  // Signature heroGlow radial gradient
  static const RadialGradient heroGlow = RadialGradient(
    colors: [emberLight, amber, orange, flameRed, black],
    stops: [0.0, 0.22, 0.48, 0.76, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [flameRed, flame, orange],
  );

  // ── Spacing Scale (4, 8, 12, 16, 20, 24, 32) ───────────────────────────────
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  static const double screenPadding = 16.0;
  static const double sectionGap = 28.0;

  // ── Layout Constants ───────────────────────────────────────────────────────
  static const double headerHeight = 60.0;
  static const double navPillHeight = 68.0;
  static const double navBottomMargin = 14.0;
  static const double miniPlayerHeight = 60.0;
  static const double miniPlayerGap = 10.0;
  static const double minTouchTarget = 48.0;

  // ── Radii ──────────────────────────────────────────────────────────────────
  static const double radiusCardArt = 8.0;
  static const double radiusQuickTile = 6.0;
  static const double radiusChip = 999.0;
  static const double radiusArtistArt = 999.0;
  static const double radiusSheet = 28.0;
  static const double radiusNavPill = 40.0;
  static const double radiusMiniPlayer = 16.0;

  // ── Elevation Shadow ───────────────────────────────────────────────────────
  static const List<BoxShadow> softElevation = [
    BoxShadow(
      color: Colors.black54,
      blurRadius: 24.0,
      offset: Offset(0, 12),
    ),
  ];

  // ── Motion Durations & Curves ──────────────────────────────────────────────
  static const Duration durPress = Duration(milliseconds: 90);
  static const Duration durChip = Duration(milliseconds: 180);
  static const Duration durRoute = Duration(milliseconds: 280);
  static const Duration durHero = Duration(milliseconds: 420);
  static const Duration durSpring = Duration(milliseconds: 600);
  static const Duration durSkeleton = Duration(milliseconds: 600);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveRoute = Curves.easeInOutCubicEmphasized;
}
