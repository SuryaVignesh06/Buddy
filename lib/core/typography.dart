import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Orbit typography tokens based on Figtree (with Poppins fallback).
abstract final class OrbitTypography {
  static const List<String> _fallback = ['Poppins', 'sans-serif'];

  static TextStyle _figtree({
    required double size,
    required FontWeight weight,
    required double height,
    required double letterSpacing,
    Color color = OrbitTokens.textPrimary,
  }) {
    return GoogleFonts.figtree(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    ).copyWith(fontFamilyFallback: _fallback);
  }

  /// 34 / 800 / 1.1 / -0.8 — "Ready to Vibe?" hero
  static TextStyle get display => _figtree(
        size: 34,
        weight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.8,
      );

  /// 28 / 800 / 1.15 / -0.5 — Screen titles, album title
  static TextStyle get h1 => _figtree(
        size: 28,
        weight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.5,
      );

  /// 22 / 700 / 1.2 / -0.3 — Section headers ("Made for you")
  static TextStyle get h2 => _figtree(
        size: 22,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
      );

  /// 16 / 700 / 1.25 / -0.1 — Card titles, track titles
  static TextStyle get h3 => _figtree(
        size: 16,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.1,
      );

  /// 14 / 500 / 1.35 / 0 — Subtitles, list rows
  static TextStyle get body => _figtree(
        size: 14,
        weight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0,
      );

  /// 13 / 500 / 1.3 / 0 — Secondary text
  static TextStyle get bodyS => _figtree(
        size: 13,
        weight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0,
        color: OrbitTokens.textSecondary,
      );

  /// 12 / 500 / 1.3 / 0.1 — Artist under card, durations
  static TextStyle get caption => _figtree(
        size: 12,
        weight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.1,
        color: OrbitTokens.textSecondary,
      );

  /// 13 / 700 / 1 / 0 — Filter chips
  static TextStyle get chip => _figtree(
        size: 13,
        weight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0,
      );

  /// 11 / 700 / 1 / 0.2 — Nav labels
  static TextStyle get nav => _figtree(
        size: 11,
        weight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0.2,
      );

  /// Derived token: QuickTile title (14 / 700, from Section 6.1)
  static TextStyle get quickTile => body.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.1,
      );

  /// Derived token: Now Playing title (22 / 800, from Section 6.5)
  static TextStyle get playerTitle => h1.copyWith(
        fontSize: 22,
        height: 1.2,
        letterSpacing: -0.3,
      );

  /// Derived token: Splash wordmark "orbit" (26 / 800, from Section 4)
  static TextStyle get splashWordmark => h1.copyWith(
        fontSize: 26,
        height: 1.1,
        letterSpacing: -0.4,
      );
}
