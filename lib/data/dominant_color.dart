import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Extracts a vibrant dominant colour from any [ImageProvider] without third-party packages.
/// Decodes to 16x16 via `ui.instantiateImageCodec(targetWidth: 16)`, weights pixels by
/// saturation * brightness, and caches the winning colour per image id.
abstract final class DominantColor {
  static final Map<String, Color> _cache = <String, Color>{};

  static Color? cached(String key) => _cache[key];

  static Future<Color> of(
    ImageProvider provider, {
    String? cacheKey,
    Color fallback = OrbitTokens.flameRed,
  }) async {
    final key = cacheKey ?? '${provider.runtimeType}_${provider.hashCode}';
    final existing = _cache[key];
    if (existing != null) return existing;

    try {
      final uiImage = await _resolveUiImage(provider)
          .timeout(const Duration(seconds: 4));
      if (uiImage == null) return fallback;

      final pngBytes = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      uiImage.dispose();
      if (pngBytes == null) return fallback;

      final codec = await ui.instantiateImageCodec(
        pngBytes.buffer.asUint8List(),
        targetWidth: 16,
        targetHeight: 16,
      );
      final frame = await codec.getNextFrame();
      final scaledImage = frame.image;
      final rgba = await scaledImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      scaledImage.dispose();
      codec.dispose();

      if (rgba == null) return fallback;
      final pixels = rgba.buffer.asUint8List();

      Color? winner;
      double bestScore = -1.0;

      // Quantize mildly in 12 hue buckets + keep highest weighted representative
      final bucketScores = List<double>.filled(12, 0.0);
      final bucketBestColor = List<Color?>.filled(12, null);
      final bucketBestWeight = List<double>.filled(12, -1.0);

      for (var i = 0; i + 3 < pixels.length; i += 4) {
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        final a = pixels[i + 3];
        if (a < 128) continue;

        final color = Color.fromARGB(255, r, g, b);
        final hsv = HSVColor.fromColor(color);
        final saturation = hsv.saturation;
        final brightness = hsv.value;
        // Weight by saturation * brightness, penalizing near-white/near-black extremes
        if (brightness < 0.12) continue;
        final weight = saturation * brightness;
        final bucket = ((hsv.hue / 30.0).floor()) % 12;

        bucketScores[bucket] += weight + 0.05;
        if (weight > bucketBestWeight[bucket]) {
          bucketBestWeight[bucket] = weight;
          bucketBestColor[bucket] = color;
        }
      }

      for (var b = 0; b < 12; b++) {
        if (bucketScores[b] > bestScore && bucketBestColor[b] != null) {
          bestScore = bucketScores[b];
          winner = bucketBestColor[b];
        }
      }

      final resolved = winner ?? fallback;
      _cache[key] = resolved;
      return resolved;
    } catch (_) {
      return fallback;
    }
  }

  static Future<ui.Image?> _resolveUiImage(ImageProvider provider) {
    final completer = Completer<ui.Image?>();
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(info.image.clone());
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}
