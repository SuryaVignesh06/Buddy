import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/haptics.dart';
import '../core/springs.dart';
import '../core/tokens.dart';
import '../core/typography.dart';

/// Coloured 3-layer glowing sine wave seek bar driven by a single [Ticker].
class WaveSeekBar extends StatefulWidget {
  const WaveSeekBar({
    super.key,
    required this.progress,
    required this.durationSeconds,
    required this.isPlaying,
    required this.onSeek,
    this.bpm = 120,
    this.showTimes = true,
  });

  final double progress;
  final int durationSeconds;
  final bool isPlaying;
  final ValueChanged<double> onSeek;
  final int bpm;
  final bool showTimes;

  static String formatSeconds(int seconds) {
    final s = seconds.clamp(0, 35999);
    final mins = s ~/ 60;
    final rem = s % 60;
    return '$mins:${rem.toString().padLeft(2, '0')}';
  }

  @override
  State<WaveSeekBar> createState() => _WaveSeekBarState();
}

class _WaveSeekBarState extends State<WaveSeekBar>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final AnimationController _ampController;
  late final AnimationController _thumbScaleController;
  late final AnimationController _lagProgressController;
  late final _WaveNotifier _notifier;

  bool _dragging = false;
  double _targetProgress = 0.0;
  double _dragVelocitySpike = 0.0;
  int _lastHapticBucket = -1;
  double _lastDragX = 0.0;
  int _lastDragMs = 0;

  @override
  void initState() {
    super.initState();
    _targetProgress = widget.progress.clamp(0.0, 1.0);
    _ampController = AnimationController.unbounded(
      vsync: this,
      value: widget.isPlaying ? 10.0 : 0.0,
    );
    _thumbScaleController = AnimationController.unbounded(
      vsync: this,
      value: 1.0,
    );
    _lagProgressController = AnimationController.unbounded(
      vsync: this,
      value: _targetProgress,
    );

    _notifier = _WaveNotifier(
      progress: _targetProgress,
      amplitude: _ampController.value,
      thumbScale: 1.0,
      isPlaying: widget.isPlaying,
      bpm: widget.bpm,
    );

    _ampController.addListener(_syncFromControllers);
    _thumbScaleController.addListener(_syncFromControllers);
    _lagProgressController.addListener(_syncFromControllers);

    _ticker = createTicker(_onTick)..start();
  }

  void _syncFromControllers() {
    _notifier.update(
      progress: _lagProgressController.value.clamp(0.0, 1.0),
      amplitude: (_ampController.value + _dragVelocitySpike).clamp(0.0, 26.0),
      thumbScale: _thumbScaleController.value.clamp(0.8, 1.55),
    );
  }

  void _onTick(Duration elapsed) {
    final sec = elapsed.inMicroseconds / 1e6;
    if (_dragVelocitySpike > 0.01) {
      _dragVelocitySpike *= 0.88;
    } else {
      _dragVelocitySpike = 0.0;
    }
    _notifier.tick(
      timeSeconds: sec,
      amplitude: (_ampController.value + _dragVelocitySpike).clamp(0.0, 26.0),
    );
  }

  void _animateAmplitude() {
    final target = _dragging ? 16.0 : (widget.isPlaying ? 10.0 : 0.0);
    if (MediaQuery.disableAnimationsOf(context)) {
      _ampController.value = target;
      return;
    }
    _ampController.animateWith(
      Springs.simulate(
        Springs.liquid,
        start: _ampController.value,
        end: target,
      ),
    );
  }

  void _animateThumbScale(double target) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _thumbScaleController.value = target;
      return;
    }
    _thumbScaleController.animateWith(
      Springs.simulate(
        Springs.bouncy,
        start: _thumbScaleController.value,
        end: target,
      ),
    );
  }

  void _animateThumbProgress(double target, {double velocity = 0.0}) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _lagProgressController.value = target;
      return;
    }
    _lagProgressController.animateWith(
      Springs.simulate(
        Springs.snappy,
        start: _lagProgressController.value,
        end: target,
        velocity: velocity,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant WaveSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _notifier.isPlaying = widget.isPlaying;
    _notifier.bpm = widget.bpm;
    if (oldWidget.isPlaying != widget.isPlaying && !_dragging) {
      _animateAmplitude();
    }
    if (!_dragging && (widget.progress - _targetProgress).abs() > 0.001) {
      _targetProgress = widget.progress.clamp(0.0, 1.0);
      _lagProgressController.value = _targetProgress;
      _notifier.update(
        progress: _targetProgress,
        amplitude: (_ampController.value + _dragVelocitySpike).clamp(0.0, 26.0),
        thumbScale: _thumbScaleController.value.clamp(0.8, 1.55),
      );
    }
  }

  void _seekFromLocalX(double localX, double width) {
    if (width <= 0) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final dtMs = (nowMs - _lastDragMs).clamp(8, 200);
    final dx = (localX - _lastDragX).abs();
    _lastDragX = localX;
    _lastDragMs = nowMs;

    final speed = dx / dtMs; // px per ms
    _dragVelocitySpike = (speed * 7.5).clamp(0.0, 9.0);

    final next = (localX / width).clamp(0.0, 1.0);
    final bucket = (next * 20).floor(); // every 5%
    if (bucket != _lastHapticBucket) {
      _lastHapticBucket = bucket;
      OrbitHaptics.selection();
    }
    _targetProgress = next;
    _animateThumbProgress(next);
    widget.onSeek(next);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ampController.dispose();
    _thumbScaleController.dispose();
    _lagProgressController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayProgress =
        _dragging ? _targetProgress : widget.progress.clamp(0.0, 1.0);
    final elapsed = (displayProgress * widget.durationSeconds).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bubbleThumbX =
                (displayProgress * width).clamp(24.0, (width - 24.0).clamp(24.0, width));

            return Semantics(
              slider: true,
              label: 'Wave playback seek bar',
              value: WaveSeekBar.formatSeconds(elapsed),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  _lastDragX = details.localPosition.dx;
                  _lastDragMs = DateTime.now().millisecondsSinceEpoch;
                  setState(() => _dragging = true);
                  _animateAmplitude();
                  _animateThumbScale(1.4); // 20 px -> 28 px
                  _seekFromLocalX(details.localPosition.dx, width);
                },
                onHorizontalDragUpdate: (details) {
                  _seekFromLocalX(details.localPosition.dx, width);
                },
                onHorizontalDragEnd: (_) {
                  setState(() => _dragging = false);
                  _animateAmplitude();
                  _animateThumbScale(1.0);
                },
                onHorizontalDragCancel: () {
                  setState(() => _dragging = false);
                  _animateAmplitude();
                  _animateThumbScale(1.0);
                },
                onTapDown: (details) {
                  _lastDragX = details.localPosition.dx;
                  _lastDragMs = DateTime.now().millisecondsSinceEpoch;
                  _dragVelocitySpike = 5.0;
                  _seekFromLocalX(details.localPosition.dx, width);
                },
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      RepaintBoundary(
                        child: SizedBox.expand(
                          child: CustomPaint(
                            painter: _WaveSeekBarPainter(_notifier),
                          ),
                        ),
                      ),
                      if (_dragging)
                        Positioned(
                          left: (bubbleThumbX - 24)
                              .clamp(0.0, (width - 48).clamp(0.0, width)),
                          top: -24,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: OrbitTokens.surface2,
                                borderRadius: BorderRadius.circular(
                                  OrbitTokens.radiusChip,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                WaveSeekBar.formatSeconds(elapsed),
                                style: OrbitTypography.caption.copyWith(
                                  color: OrbitTokens.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showTimes)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  WaveSeekBar.formatSeconds(elapsed),
                  style: OrbitTypography.caption.copyWith(
                    color: OrbitTokens.textSecondary,
                  ),
                ),
                Text(
                  WaveSeekBar.formatSeconds(widget.durationSeconds),
                  style: OrbitTypography.caption.copyWith(
                    color: OrbitTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WaveNotifier extends ChangeNotifier {
  _WaveNotifier({
    required this.progress,
    required this.amplitude,
    required this.thumbScale,
    required this.isPlaying,
    required this.bpm,
  });

  double progress;
  double amplitude;
  double thumbScale;
  bool isPlaying;
  int bpm;
  double timeSeconds = 0.0;

  void update({
    required double progress,
    required double amplitude,
    required double thumbScale,
  }) {
    this.progress = progress;
    this.amplitude = amplitude;
    this.thumbScale = thumbScale;
    notifyListeners();
  }

  void tick({
    required double timeSeconds,
    required double amplitude,
  }) {
    this.timeSeconds = timeSeconds;
    this.amplitude = amplitude;
    notifyListeners();
  }
}

class _WaveSeekBarPainter extends CustomPainter {
  _WaveSeekBarPainter(this.state) : super(repaint: state);

  final _WaveNotifier state;

  // Precomputed Paint & Path objects to prevent per-frame allocations
  final Paint _unplayedPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.30)
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final Paint _playedBasePaint = Paint()
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final Paint _layerPaint = Paint()
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke
    ..blendMode = BlendMode.plus;

  final Paint _saveLayerPaint = Paint();
  final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
  final Paint _thumbFillPaint = Paint();
  final Paint _thumbRingPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  final Path _wavePath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final p = state.progress.clamp(0.0, 1.0);
    final thumbX = p * size.width;

    // 1. Unplayed baseline: 3 px, white 30%, rounded caps
    canvas.drawLine(
      Offset(thumbX, cy),
      Offset(size.width, cy),
      _unplayedPaint,
    );

    // 2. Played baseline: 3 px, gradient white -> emberLight
    if (thumbX > 0.5) {
      final playedRect = Rect.fromLTWH(0, cy - 2, thumbX, 4);
      _playedBasePaint.shader = const LinearGradient(
        colors: [Colors.white, OrbitTokens.emberLight],
      ).createShader(playedRect);
      canvas.drawLine(Offset(0, cy), Offset(thumbX, cy), _playedBasePaint);
    }

    // 3. Waves over the played portion with one saveLayer limited to the bar's rect
    final beatMod = state.isPlaying
        ? 1.0 +
            0.15 *
                math.sin(
                  2.0 * math.pi * (state.bpm / 60.0) * state.timeSeconds,
                )
        : 1.0;
    final effectiveAmp = state.amplitude * beatMod;

    if (thumbX > 4.0 && effectiveAmp > 0.15) {
      final barRect = Offset.zero & size;
      canvas.saveLayer(barRect, _saveLayerPaint);

      _drawSineLayer(
        canvas,
        thumbX: thumbX,
        cy: cy,
        amplitude: effectiveAmp,
        cycles: 2.2,
        phase: state.timeSeconds * 1.2,
        color: OrbitTokens.flameRed,
      );
      _drawSineLayer(
        canvas,
        thumbX: thumbX,
        cy: cy,
        amplitude: effectiveAmp * 0.92,
        cycles: 3.1,
        phase: -state.timeSeconds * 0.9 + 1.1,
        color: OrbitTokens.amber,
      );
      _drawSineLayer(
        canvas,
        thumbX: thumbX,
        cy: cy,
        amplitude: effectiveAmp * 0.85,
        cycles: 4.0,
        phase: state.timeSeconds * 1.6 + 2.3,
        color: OrbitTokens.pinkRed.withValues(alpha: 0.80),
      );

      canvas.restore();
    }

    // 4. Thumb: 20 px (scales to 28 px on drag), radial orange -> flameRed,
    //    3 px white ring, outer glow flameRed @ 55% blur 16
    final thumbRadius = 10.0 * state.thumbScale;
    final thumbCenter = Offset(thumbX, cy);
    final thumbRect = Rect.fromCircle(center: thumbCenter, radius: thumbRadius);

    _glowPaint.color = OrbitTokens.flameRed.withValues(alpha: 0.55);
    canvas.drawCircle(thumbCenter, thumbRadius * 1.12, _glowPaint);

    _thumbFillPaint.shader = const RadialGradient(
      center: Alignment(-0.3, -0.3),
      colors: [OrbitTokens.orange, OrbitTokens.flameRed],
    ).createShader(thumbRect);
    canvas.drawCircle(thumbCenter, thumbRadius, _thumbFillPaint);
    canvas.drawCircle(thumbCenter, thumbRadius, _thumbRingPaint);
  }

  void _drawSineLayer(
    Canvas canvas, {
    required double thumbX,
    required double cy,
    required double amplitude,
    required double cycles,
    required double phase,
    required Color color,
  }) {
    _wavePath.reset();
    final steps = (thumbX / 3.0).ceil().clamp(16, 120);
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * thumbX;
      // Warped envelope peaking at ~65% of played length (0.65^1.61 ~= 0.50)
      final u = math.pow(t, 1.61).toDouble();
      final env = math.pow(math.sin(math.pi * u).clamp(0.0, 1.0), 1.5).toDouble();
      final y = cy +
          amplitude *
              env *
              math.sin(2.0 * math.pi * cycles * t + phase);
      if (i == 0) {
        _wavePath.moveTo(x, y);
      } else {
        _wavePath.lineTo(x, y);
      }
    }
    _layerPaint.color = color;
    canvas.drawPath(_wavePath, _layerPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveSeekBarPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

/// Splash wave line drawing the 3 glowing sine layers under Dot (replaces EqBars).
class SplashWaveLine extends StatelessWidget {
  const SplashWaveLine({
    super.key,
    required this.phase,
    required this.amplitudeFactor,
    this.width = 160.0,
    this.height = 38.0,
  });

  final double phase;
  final double amplitudeFactor;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SplashWavePainter(
            phase: phase,
            amplitudeFactor: amplitudeFactor,
          ),
        ),
      ),
    );
  }
}

class _SplashWavePainter extends CustomPainter {
  _SplashWavePainter({
    required this.phase,
    required this.amplitudeFactor,
  });

  final double phase;
  final double amplitudeFactor;

  final Paint _basePaint = Paint()
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withValues(alpha: 0.25);

  final Paint _wavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..blendMode = BlendMode.plus;

  final Paint _savePaint = Paint();
  final Path _path = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), _basePaint);

    final amp = (size.height * 0.40) * amplitudeFactor.clamp(0.0, 1.2);
    if (amp <= 0.1) return;

    canvas.saveLayer(Offset.zero & size, _savePaint);
    _draw(canvas, size, cy, amp, 2.2, phase * 1.2, OrbitTokens.flameRed);
    _draw(canvas, size, cy, amp * 0.9, 3.1, -phase * 0.9 + 1.1, OrbitTokens.amber);
    _draw(
      canvas,
      size,
      cy,
      amp * 0.85,
      4.0,
      phase * 1.6 + 2.2,
      OrbitTokens.pinkRed.withValues(alpha: 0.8),
    );
    canvas.restore();
  }

  void _draw(
    Canvas canvas,
    Size size,
    double cy,
    double amp,
    double cycles,
    double ph,
    Color color,
  ) {
    _path.reset();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * size.width;
      final env = math.pow(math.sin(math.pi * t).clamp(0.0, 1.0), 1.4).toDouble();
      final y = cy + amp * env * math.sin(2.0 * math.pi * cycles * t + ph);
      if (i == 0) {
        _path.moveTo(x, y);
      } else {
        _path.lineTo(x, y);
      }
    }
    _wavePaint.color = color;
    canvas.drawPath(_path, _wavePaint);
  }

  @override
  bool shouldRepaint(covariant _SplashWavePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.amplitudeFactor != amplitudeFactor;
  }
}

/// 2 px mini wave progress line for [MiniPlayer].
class MiniWaveProgress extends StatefulWidget {
  const MiniWaveProgress({
    super.key,
    required this.progress,
    required this.isPlaying,
  });

  final double progress;
  final bool isPlaying;

  @override
  State<MiniWaveProgress> createState() => _MiniWaveProgressState();
}

class _MiniWaveProgressState extends State<MiniWaveProgress>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _phase = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (widget.isPlaying) {
        _phase.value = elapsed.inMicroseconds / 1e6;
      }
    });
    if (widget.isPlaying) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant MiniWaveProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.isPlaying && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: CustomPaint(
          painter: _MiniWavePainter(
            phaseListenable: _phase,
            progress: widget.progress,
            isPlaying: widget.isPlaying,
          ),
        ),
      ),
    );
  }
}

class _MiniWavePainter extends CustomPainter {
  _MiniWavePainter({
    required this.phaseListenable,
    required this.progress,
    required this.isPlaying,
  }) : super(repaint: phaseListenable);

  final ValueNotifier<double> phaseListenable;
  final double progress;
  final bool isPlaying;

  final Paint _bgPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.16)
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final Paint _fgPaint = Paint()
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final Path _path = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), _bgPaint);

    final endX = (progress.clamp(0.0, 1.0) * size.width);
    if (endX <= 1.0) return;

    _fgPaint.shader = const LinearGradient(
      colors: [OrbitTokens.flameRed, OrbitTokens.orange, OrbitTokens.amber],
    ).createShader(Rect.fromLTWH(0, 0, endX, size.height));

    if (!isPlaying) {
      canvas.drawLine(Offset(0, cy), Offset(endX, cy), _fgPaint);
      return;
    }

    _path.reset();
    final ph = phaseListenable.value * 4.0;
    const steps = 36;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * endX;
      final env = math.sin(math.pi * t);
      final y = cy + 1.8 * env * math.sin(t * math.pi * 6.0 + ph);
      if (i == 0) {
        _path.moveTo(x, y);
      } else {
        _path.lineTo(x, y);
      }
    }
    canvas.drawPath(_path, _fgPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }
}

/// Compact animated wave glyph for the "now playing" QuickTile and active TrackRow.
class MiniWaveGlyph extends StatefulWidget {
  const MiniWaveGlyph({
    super.key,
    this.active = true,
    this.width = 20.0,
    this.height = 14.0,
    this.color = OrbitTokens.orange,
  });

  final bool active;
  final double width;
  final double height;
  final Color color;

  @override
  State<MiniWaveGlyph> createState() => _MiniWaveGlyphState();
}

class _MiniWaveGlyphState extends State<MiniWaveGlyph>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _phase = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (widget.active) {
        _phase.value = elapsed.inMicroseconds / 1e6;
      }
    });
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant MiniWaveGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.active && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: CustomPaint(
          painter: _MiniGlyphPainter(
            phaseListenable: _phase,
            active: widget.active,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _MiniGlyphPainter extends CustomPainter {
  _MiniGlyphPainter({
    required this.phaseListenable,
    required this.active,
    required this.color,
  }) : super(repaint: phaseListenable);

  final ValueNotifier<double> phaseListenable;
  final bool active;
  final Color color;

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  final Path _path = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final amp = active ? size.height * 0.42 : 1.0;
    final ph = phaseListenable.value * 5.2;

    _path.reset();
    const steps = 18;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * size.width;
      final env = math.sin(math.pi * t);
      final y = cy + amp * env * math.sin(t * math.pi * 4.5 + ph);
      if (i == 0) {
        _path.moveTo(x, y);
      } else {
        _path.lineTo(x, y);
      }
    }
    _paint.color = color;
    canvas.drawPath(_path, _paint);
  }

  @override
  bool shouldRepaint(covariant _MiniGlyphPainter oldDelegate) {
    return oldDelegate.active != active || oldDelegate.color != color;
  }
}
