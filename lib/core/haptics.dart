import 'package:flutter/services.dart';

/// Centralised tactile feedback helpers for Orbit interactions.
abstract final class OrbitHaptics {
  /// Subtle tick for chip changes, nav snaps, and seek scrubbing snaps.
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Light impact for splash bounce, button presses, and swipe reveals.
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for long-press peek activation or play/pause primary triggers.
  static void medium() {
    HapticFeedback.mediumImpact();
  }
}
