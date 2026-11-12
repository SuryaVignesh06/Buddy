import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../core/debug.dart';
import '../../core/haptics.dart';
import '../../core/orbit_state.dart';
import '../../core/springs.dart';
import '../../core/tokens.dart';
import '../../core/typography.dart';
import '../../data/art_repository.dart';
import '../../widgets/liquid_backdrop.dart';
import '../../widgets/ripple_rings.dart';
import '../../widgets/wave_seek_bar.dart';
import '../shell/app_shell.dart';
import 'dot_painter.dart';

typedef SplashScene = SplashPage;

/// Cinematic 3.2 s splash animation driven by one [AnimationController]:
/// - 0.2–1.0 s: Dot falls with gravity, +-6 deg tilt, vertical motion trail
/// - 1.0–1.25 s: Impact squash (1.18 x 0.82), flameRed shockwave, background glow flare, haptic
/// - 1.25–2.3 s: Listening with happy eyes, 120 BPM head bob, 3 ripple rings, WaveLine, "orbit"
/// - 2.3–2.9 s: Circular reveal into Home; Dot Hero-flies to top-left slot with bouncy spring
/// - 2.9–3.2 s: Home content staggers in & nav pill springs up
/// Navigates via `pushReplacement` (`PageRouteBuilder`, 700 ms) on `AnimationStatus.completed`.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Duration _totalDuration = Duration(milliseconds: 3200);
  static const Cubic _gravityCurve = Cubic(0.55, 0.0, 1.0, 0.45);
  static const double _revealStartT = 0.71875; // 2300 ms / 3200 ms
  static final SpringSimulation _flySpring =
      Springs.simulate(Springs.bouncy, start: 0.0, end: 1.0);

  late final AnimationController _controller;
  final GlobalKey _dotSlotKey = GlobalKey();
  final GlobalKey _finalDotSlotKey = GlobalKey();
  final ValueNotifier<double> _splashScroll = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _splashPlaying = ValueNotifier<bool>(true);
  final ValueNotifier<Color> _splashHue =
      ValueNotifier<Color>(OrbitTokens.flameRed);

  bool _impactHapticFired = false;
  bool _navigated = false;
  bool _imagesReady = false;
  bool _waitingForImages = false;
  Rect? _targetDotRect;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    )
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);

    // Start immediately in initState
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureTargetSlot();
      _startPrecache();
    });
  }

  void _startPrecache() {
    final orbit = OrbitScope.maybeOf(context);
    final urls = orbit?.initialPrecacheUrls ?? const <String>[];
    if (urls.isEmpty) {
      _imagesReady = true;
      return;
    }

    unawaited(
      ArtRepository.instance
          .precacheInitialImages(context, urls: urls)
          .whenComplete(() {
        if (!mounted) return;
        _imagesReady = true;
        if (_waitingForImages && !_navigated) {
          _waitingForImages = false;
          _controller.forward();
        }
      }),
    );
  }

  void _measureTargetSlot() {
    final box = _dotSlotKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final pos = box.localToGlobal(Offset.zero);
      _targetDotRect = pos & box.size;
    }
  }

  void _onTick() {
    final t = _controller.value;

    // Gate circular reveal at 2.3 s until first 12 images precache (or 3 s timeout)
    if (t >= _revealStartT && !_imagesReady && !_waitingForImages && !_navigated) {
      _waitingForImages = true;
      _controller.stop();
      return;
    }

    if (t >= _revealStartT && _targetDotRect == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _measureTargetSlot();
      });
    }

    // Light haptic on impact beat (1.0 s -> 0.3125)
    if (!_impactHapticFired && t >= 0.3125) {
      _impactHapticFired = true;
      OrbitHaptics.light();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_navigated && mounted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 700),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => AppShell(
          dotSlotKey: _finalDotSlotKey,
          entryProgress: 1.0,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  void _skipSplash() {
    if (_navigated) return;
    OrbitHaptics.selection();
    _imagesReady = true;
    _waitingForImages = false;
    _controller.forward(from: 0.99);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    _splashScroll.dispose();
    _splashPlaying.dispose();
    _splashHue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final orbit = OrbitScope.maybeOf(context);
    final userReduced =
        !kForceSplash && (orbit?.userReducedMotion.value ?? false);

    return Scaffold(
      backgroundColor: OrbitTokens.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipSplash,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;

            if (userReduced) {
              return Stack(
                children: [
                  AppShell(dotSlotKey: _dotSlotKey, entryProgress: 1.0),
                  IgnorePointer(
                    child: Opacity(
                      opacity: (1.0 - t).clamp(0.0, 1.0),
                      child: Container(color: OrbitTokens.black),
                    ),
                  ),
                ],
              );
            }

            // 2.9–3.2 s: Home content staggers in & nav pill springs up
            final homeEntry =
                const Interval(0.90625, 1.0, curve: Curves.easeOutCubic)
                    .transform(t);

            // 2.3–2.9 s: Circular reveal from Dot's centre into Home
            final revealT =
                const Interval(_revealStartT, 0.90625, curve: Curves.easeInOutCubic)
                    .transform(t);

            // 1.0–1.25 s: Background glow flares on impact
            final impactWindow =
                const Interval(0.3125, 0.390625).transform(t);
            final backdropFlare = impactWindow > 0.0 && impactWindow < 1.0
                ? math.sin(impactWindow * math.pi)
                : 0.0;

            final targetRect = _targetDotRect ??
                Rect.fromLTWH(
                  OrbitTokens.screenPadding,
                  safeTop + 14.0,
                  36.0,
                  36.0,
                );

            return Stack(
              children: [
                // Vibrant orange-red animated background shared across splash & home
                Positioned.fill(
                  child: LiquidBackdrop(
                    scrollOffset: _splashScroll,
                    isPlaying: _splashPlaying,
                    trackHue: _splashHue,
                    flare: backdropFlare,
                  ),
                ),

                // Splash stage elements (rings, wave line, wordmark)
                if (t < 0.90625)
                  Opacity(
                    opacity: (1.0 - revealT * 1.15).clamp(0.0, 1.0),
                    child: _buildSplashStage(size, t),
                  ),

                // Revealed Home via circular ClipPath from Dot's centre
                if (t >= _revealStartT)
                  ClipPath(
                    clipper: _CircularRevealClipper(
                      center: Offset(size.width / 2, size.height / 2),
                      fraction: revealT,
                    ),
                    child: AppShell(
                      dotSlotKey: _dotSlotKey,
                      entryProgress: homeEntry,
                      enableDotHero: false,
                    ),
                  ),

                // Animated Dot mascot driven directly by CustomPaint(DotPainter)
                _buildAnimatedDot(size, t, targetRect),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSplashStage(Size size, double t) {
    // 1.0–1.25 s: flameRed shockwave ring
    final shockwaveT = const Interval(0.3125, 0.42).transform(t);
    // 1.25–2.3 s: listening window [0.390625 .. 0.71875]
    final listenT = const Interval(0.390625, 0.71875).transform(t);
    final ringT = const Interval(0.390625, 0.71875).transform(t);

    // Wave amplitude rises with the beat during listening
    final waveAppear =
        const Interval(0.390625, 0.47, curve: Curves.easeOutBack).transform(t);
    final waveFadeOut =
        1.0 - const Interval(0.68, 0.75, curve: Curves.easeIn).transform(t);
    final beatBoost =
        0.75 + 0.35 * (0.5 - 0.5 * math.cos(listenT * math.pi * 4.0));
    final waveAmp = (waveAppear * waveFadeOut * beatBoost).clamp(0.0, 1.2);

    // "orbit" fades in during listening
    final wordmarkOpacity =
        const Interval(0.43, 0.56, curve: Curves.easeOut).transform(t) *
            (1.0 - const Interval(0.68, 0.76).transform(t));

    return Stack(
      alignment: Alignment.center,
      children: [
        if (shockwaveT > 0.0 || ringT > 0.0)
          RippleRings(
            progress: ringT,
            shockwaveProgress: shockwaveT,
            size: math.min(size.width, 380),
            ringCount: 3,
            baseRadius: 48,
            maxSpread: 145,
          ),
        if (waveAmp > 0.01 && t < 0.76)
          Transform.translate(
            offset: const Offset(0, 78),
            child: SplashWaveLine(
              phase: listenT * 4.2,
              amplitudeFactor: waveAmp,
              width: 170,
              height: 36,
            ),
          ),
        if (wordmarkOpacity > 0.01)
          Transform.translate(
            offset: const Offset(0, 128),
            child: Opacity(
              opacity: wordmarkOpacity.clamp(0.0, 1.0),
              child: Text(
                'orbit',
                style: OrbitTypography.splashWordmark.copyWith(
                  color: OrbitTokens.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedDot(Size size, double t, Rect targetRect) {
    final screenCenter = Offset(size.width / 2, size.height / 2);
    const baseSize = 96.0;

    // 0.2–1.0 s [0.0625 .. 0.3125]: fall with gravity
    final fallT =
        const Interval(0.0625, 0.3125, curve: _gravityCurve).transform(t);
    // 1.0–1.25 s [0.3125 .. 0.390625]: impact squash + spring rebound
    final impactT = const Interval(0.3125, 0.390625).transform(t);
    // 1.25–2.3 s [0.390625 .. 0.71875]: listening
    final listenT = const Interval(0.390625, 0.71875).transform(t);
    // 2.3–2.5 s [0.71875 .. 0.78125]: pop before fly
    final scaleUpT =
        const Interval(0.71875, 0.78125, curve: Curves.easeOutCubic)
            .transform(t);
    // 2.5–2.9 s [0.78125 .. 0.90625]: bouncy spring fly to top-left Home slot
    final rawFlyT = const Interval(0.78125, 0.90625).transform(t);
    final flyT = rawFlyT <= 0.0
        ? 0.0
        : rawFlyT >= 1.0
            ? 1.0
            : _flySpring.x(rawFlyT * 0.65).clamp(0.0, 1.12);

    double dx = screenCenter.dx;
    double dy = screenCenter.dy;

    if (t < 0.0625) {
      dy = -size.height * 0.65;
    } else if (t < 0.3125) {
      dy = (-size.height * 0.65) * (1.0 - fallT) + screenCenter.dy * fallT;
    } else if (t < 0.390625) {
      // Impact spring rebound using Springs.liquid waveform
      final rebound = math.sin(impactT * math.pi) *
          (1.0 - Curves.easeOut.transform(impactT) * 0.35);
      dy = screenCenter.dy - 26.0 * rebound;
    } else if (t >= 0.78125) {
      final targetCenter = targetRect.center;
      dx = screenCenter.dx + (targetCenter.dx - screenCenter.dx) * flyT;
      dy = screenCenter.dy + (targetCenter.dy - screenCenter.dy) * flyT;
    }

    double currentSize = baseSize;
    if (t >= 0.71875 && t < 0.78125) {
      currentSize = baseSize * (1.0 + 0.45 * scaleUpT);
    } else if (t >= 0.78125) {
      final startSize = baseSize * 1.45;
      currentSize =
          (startSize + (targetRect.width - startSize) * flyT.clamp(0.0, 1.0));
    }

    // Impact squash: 1.18 x 0.82 -> spring rebound
    double squash = 0.0;
    if (impactT > 0.0 && impactT < 1.0) {
      squash = math.sin(impactT * math.pi) * (1.0 - impactT * 0.35);
    }

    // Tilt +-6 deg during fall; 120 BPM head bob during listening
    double rotationDeg = 0.0;
    if (t >= 0.0625 && t < 0.3125) {
      rotationDeg = math.sin(fallT * math.pi * 2.0) * 6.0;
    } else if (t >= 0.390625 && t < 0.71875) {
      rotationDeg = math.sin(listenT * math.pi * 4.0) * 4.5;
    }

    // 120 BPM ear cup pulse
    double beatPulse = 0.0;
    if (t >= 0.390625 && t < 0.71875) {
      beatPulse =
          (0.5 - 0.5 * math.cos(listenT * math.pi * 4.0)).clamp(0.0, 1.0);
    }

    final eyeLook = t < 0.3125 ? 0.9 * (1.0 - fallT * 0.4) : 0.0;
    final happyEyes =
        const Interval(0.40, 0.52, curve: Curves.easeOut).transform(t) *
            (1.0 - rawFlyT);

    double blink = 0.0;
    if (t >= 0.54 && t <= 0.60) {
      blink = math.sin(((t - 0.54) / 0.06) * math.pi);
    }

    final showStreak = t >= 0.07 && t < 0.32;
    final streakOpacity = showStreak
        ? (math.sin(fallT * math.pi) * 0.55).clamp(0.0, 0.55)
        : 0.0;

    final headphoneOpacity = (1.0 - rawFlyT * 1.4).clamp(0.0, 1.0);

    // Once Dot lands on Home's slot (t >= 0.90625), Home's own Dot renders there
    if (t >= 0.90625) return const SizedBox.shrink();

    return Stack(
      children: [
        if (streakOpacity > 0.01)
          Positioned(
            left: dx - 22,
            top: dy - 135,
            width: 44,
            height: 135,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withValues(alpha: streakOpacity),
                      OrbitTokens.flame.withValues(alpha: streakOpacity * 0.5),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        Positioned(
          left: dx - currentSize / 2,
          top: dy - currentSize / 2,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: rotationDeg * math.pi / 180.0,
              child: Hero(
                tag: 'orbit-dot-logo',
                child: SizedBox.square(
                  dimension: currentSize,
                  child: CustomPaint(
                    painter: DotPainter(
                      headphones: headphoneOpacity > 0.02,
                      headphoneOpacity: headphoneOpacity,
                      blink: blink,
                      squash: squash,
                      eyeLook: eyeLook,
                      beatPulse: beatPulse,
                      happyEyes: happyEyes,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircularRevealClipper extends CustomClipper<Path> {
  const _CircularRevealClipper({
    required this.center,
    required this.fraction,
  });

  final Offset center;
  final double fraction;

  @override
  Path getClip(Size size) {
    final maxRadius = math.sqrt(
      math.pow(math.max(center.dx, size.width - center.dx), 2) +
          math.pow(math.max(center.dy, size.height - center.dy), 2),
    );
    final radius = maxRadius * fraction.clamp(0.0, 1.0);
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }
}
