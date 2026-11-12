import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/springs.dart';
import '../core/tokens.dart';

/// Saturated orange-red animated background driven by a single [Ticker] and
/// repainted via `CustomPainter(repaint:)` inside a [RepaintBoundary].
class LiquidBackdrop extends StatefulWidget {
  const LiquidBackdrop({
    super.key,
    required this.scrollOffset,
    required this.isPlaying,
    required this.trackHue,
    this.bpm = 120,
    this.flare = 0.0,
    this.paused = false,
  });

  final ValueListenable<double> scrollOffset;
  final ValueListenable<bool> isPlaying;
  final ValueListenable<Color> trackHue;
  final int bpm;
  final double flare;
  final bool paused;

  @override
  State<LiquidBackdrop> createState() => _LiquidBackdropState();
}

class _LiquidBackdropState extends State<LiquidBackdrop>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final _BackdropNotifier _notifier;

  Color _fromColor = OrbitTokens.flameRed;
  Color _toColor = OrbitTokens.flameRed;
  Duration _colorTransitionStart = Duration.zero;
  Duration _lastElapsed = Duration.zero;
  double _breathPhase = 0.0;

  @override
  void initState() {
    super.initState();
    _toColor = Color.lerp(OrbitTokens.flameRed, widget.trackHue.value, 0.35)!;
    _fromColor = _toColor;
    _notifier = _BackdropNotifier(
      scrollOffset: widget.scrollOffset,
      blobAColor: _toColor,
      flare: widget.flare,
    );

    widget.trackHue.addListener(_onTrackHueChanged);
    widget.isPlaying.addListener(_onPlayingChanged);

    _ticker = createTicker(_onTick);
    if (!widget.paused) {
      _ticker.start();
    }
  }

  void _onTrackHueChanged() {
    _fromColor = _notifier.blobAColor;
    _toColor = Color.lerp(OrbitTokens.flameRed, widget.trackHue.value, 0.35)!;
    _colorTransitionStart = _lastElapsed;
  }

  void _onPlayingChanged() {
    // Ticker keeps running for slow drift even when paused; breath smoothly settles.
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final tSec = elapsed.inMicroseconds / 1e6;

    // 900 ms cross-fade for track-linked Blob A hue
    final colorAge = (elapsed - _colorTransitionStart).inMilliseconds;
    final colorT = (colorAge / 900.0).clamp(0.0, 1.0);
    final easedColorT = Curves.easeInOutCubic.transform(colorT);
    final currentBlobA = Color.lerp(_fromColor, _toColor, easedColorT)!;

    // Music-linked BPM breath (1.0 <-> 1.06 while playing; smoothly relaxes when paused)
    if (widget.isPlaying.value && dt > 0 && dt < 0.25) {
      final beatsPerSec = (widget.bpm / 60.0).clamp(0.8, 3.5);
      _breathPhase += dt * beatsPerSec * math.pi * 2.0;
    }
    final targetBreath = widget.isPlaying.value
        ? 0.5 - 0.5 * math.cos(_breathPhase)
        : 0.0;
    final breath = _notifier.breath + (targetBreath - _notifier.breath) * 0.14;

    _notifier.update(
      timeSeconds: tSec,
      breath: breath,
      blobAColor: currentBlobA,
      flare: widget.flare,
    );
  }

  @override
  void didUpdateWidget(covariant LiquidBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flare != widget.flare) {
      _notifier.update(
        timeSeconds: _notifier.timeSeconds,
        breath: _notifier.breath,
        blobAColor: _notifier.blobAColor,
        flare: widget.flare,
      );
    }
    if (widget.paused && _ticker.isActive) {
      _ticker.stop();
    } else if (!widget.paused && !_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    widget.trackHue.removeListener(_onTrackHueChanged);
    widget.isPlaying.removeListener(_onPlayingChanged);
    _ticker.dispose();
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: SizedBox.expand(
          child: CustomPaint(
            isComplex: true,
            willChange: !widget.paused,
            painter: _LiquidBackdropPainter(_notifier),
          ),
        ),
      ),
    );
  }
}

class _BackdropNotifier extends ChangeNotifier {
  _BackdropNotifier({
    required this.scrollOffset,
    required this.blobAColor,
    required this.flare,
  }) {
    scrollOffset.addListener(notifyListeners);
  }

  final ValueListenable<double> scrollOffset;
  double timeSeconds = 0.0;
  double breath = 0.0;
  Color blobAColor;
  double flare;

  void update({
    required double timeSeconds,
    required double breath,
    required Color blobAColor,
    required double flare,
  }) {
    this.timeSeconds = timeSeconds;
    this.breath = breath;
    this.blobAColor = blobAColor;
    this.flare = flare;
    notifyListeners();
  }

  @override
  void dispose() {
    scrollOffset.removeListener(notifyListeners);
    super.dispose();
  }
}

class _LiquidBackdropPainter extends CustomPainter {
  _LiquidBackdropPainter(this.state) : super(repaint: state);

  final _BackdropNotifier state;

  // Precomputed Paint objects (zero allocations inside paint)
  final Paint _bgPaint = Paint()..color = OrbitTokens.black;
  final Paint _blobAPaint = Paint();
  final Paint _blobBPaint = Paint();
  final Paint _blobCPaint = Paint();
  final Paint _fadePaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    canvas.drawRect(fullRect, _bgPaint);

    final scroll = state.scrollOffset.value;
    final positiveScroll = scroll > 0.0 ? scroll : 0.0;
    final overscroll = scroll < 0.0 ? -scroll : 0.0;

    final opacity = (1.0 - (positiveScroll / 560.0).clamp(0.0, 1.0)) *
        (1.0 + state.flare * 0.15).clamp(0.0, 1.0);
    if (opacity <= 0.005) return;

    final translateY = -0.35 * positiveScroll;
    final overscrollStretch =
        1.0 + (overscroll / 150.0).clamp(0.0, 1.0) * 0.15;
    final musicScale = 1.0 + state.breath * 0.06 + state.flare * 0.10;
    final scale = overscrollStretch * musicScale;

    final w = size.width;
    final h = size.height;
    final t = state.timeSeconds;

    canvas.save();
    canvas.translate(0, translateY);

    // Blob A: flameRed (or track-blended) @ 0.85 -> transparent, radius 0.95*width,
    // Lissajous path, amplitude 0.14*width, period 14s
    final omegaA = (2.0 * math.pi) / 14.0;
    final centerA = Offset(
      w * 0.52 + math.sin(t * omegaA) * (w * 0.14),
      h * 0.18 + math.sin(t * omegaA * 2.0 + 0.6) * (w * 0.14 * 0.72),
    );
    final radiusA = w * 0.95 * scale;
    final rectA = Rect.fromCircle(center: centerA, radius: radiusA);
    _blobAPaint.shader = RadialGradient(
      colors: [
        state.blobAColor.withValues(alpha: (0.85 * opacity).clamp(0.0, 1.0)),
        state.blobAColor.withValues(alpha: (0.36 * opacity).clamp(0.0, 1.0)),
        Colors.transparent,
      ],
      stops: const [0.0, 0.48, 1.0],
    ).createShader(rectA);
    canvas.drawCircle(centerA, radiusA, _blobAPaint);

    // Blob B: orange @ 0.65 -> transparent, radius 0.8*width, period 18s, opposite phase
    final omegaB = (2.0 * math.pi) / 18.0;
    final centerB = Offset(
      w * 0.78 - math.sin(t * omegaB + math.pi) * (w * 0.14),
      h * 0.10 - math.cos(t * omegaB * 1.5 + math.pi) * (w * 0.11),
    );
    final radiusB = w * 0.80 * scale;
    final rectB = Rect.fromCircle(center: centerB, radius: radiusB);
    _blobBPaint.shader = RadialGradient(
      colors: [
        OrbitTokens.orange.withValues(alpha: (0.65 * opacity).clamp(0.0, 1.0)),
        OrbitTokens.flame.withValues(alpha: (0.24 * opacity).clamp(0.0, 1.0)),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rectB);
    canvas.drawCircle(centerB, radiusB, _blobBPaint);

    // Blob C: crimson @ 0.7 -> transparent, radius 1.1*width, period 23s, anchored lower-left
    final omegaC = (2.0 * math.pi) / 23.0;
    final centerC = Offset(
      w * 0.14 + math.cos(t * omegaC) * (w * 0.10),
      h * 0.44 + math.sin(t * omegaC * 1.3) * (w * 0.09),
    );
    final radiusC = w * 1.10 * scale;
    final rectC = Rect.fromCircle(center: centerC, radius: radiusC);
    _blobCPaint.shader = RadialGradient(
      colors: [
        OrbitTokens.crimson.withValues(alpha: (0.70 * opacity).clamp(0.0, 1.0)),
        OrbitTokens.ember.withValues(alpha: (0.34 * opacity).clamp(0.0, 1.0)),
        Colors.transparent,
      ],
      stops: const [0.0, 0.52, 1.0],
    ).createShader(rectC);
    canvas.drawCircle(centerC, radiusC, _blobCPaint);

    canvas.restore();

    // Vertical black fade overlay: transparent at top -> black @ 100% at 62% screen height
    _fadePaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Color(0x55000000),
        OrbitTokens.black,
        OrbitTokens.black,
      ],
      stops: [0.0, 0.34, 0.62, 1.0],
    ).createShader(fullRect);
    canvas.drawRect(fullRect, _fadePaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidBackdropPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

/// Helper spring controller for optional splash background rebound if needed.
class BackdropPulse {
  static SpringDescription get spring => Springs.liquid;
}
