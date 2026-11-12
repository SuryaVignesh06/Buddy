import 'dart:async';

import 'package:flutter/material.dart';

import '../core/haptics.dart';
import '../core/orbit_state.dart';
import '../core/springs.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../data/mock.dart';
import 'app_image.dart';
import 'dot_logo.dart';
import 'like_button.dart';
import 'play_button.dart';
import 'wave_seek_bar.dart';

/// Glass Now Playing card with full-bleed artwork, dark gradient overlay,
/// device/cast bar, marquee title with Dot glyph, [WaveSeekBar], and five
/// translucent glass transport circles.
class GlassPlayerCard extends StatelessWidget {
  const GlassPlayerCard({
    super.key,
    required this.track,
    required this.orbit,
    required this.onDevicesTap,
    this.artScale = 1.0,
    this.enableHero = true,
  });

  final OrbitTrack track;
  final OrbitController orbit;
  final VoidCallback onDevicesTap;
  final double artScale;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Full-bleed artwork background inside card (scales to 0.9 on pause)
            Positioned.fill(
              child: Transform.scale(
                scale: artScale,
                child: AppImage(
                  id: track.id,
                  imageUrl: track.imageUrl,
                  seed: track.seed,
                  primaryColor: track.dominantColor,
                  secondaryColor: track.secondaryColor,
                  fit: BoxFit.cover,
                  borderRadius: 32,
                  heroTag: enableHero ? 'now_playing_art' : null,
                ),
              ),
            ),

            // Vertical dark gradient (10% top -> 78% bottom) for crisp readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.34),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Subtle glass top specular rim
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.transparent,
                        OrbitTokens.flame.withValues(alpha: 0.12),
                      ],
                      stops: const [0.0, 0.28, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Foreground 5 rows
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row 1: device glyph + "This phone" on left; cast icon on right
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Audio device: This phone',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onDevicesTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius:
                                  BorderRadius.circular(OrbitTokens.radiusChip),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.smartphone_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'This phone',
                                  style: OrbitTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Semantics(
                        button: true,
                        label: 'Cast audio',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onDevicesTap,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.24),
                              ),
                            ),
                            child: const Icon(
                              Icons.cast_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: MediaQuery.sizeOf(context).width < 345 ? 124 : 150,
                  ),

                  // Row 2: small Dot glyph + centered marquee title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const DotLogo(
                        size: 22,
                        headphones: true,
                        beatPulse: 0.65,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _MarqueeText(
                          text: '${track.title} — ${track.artistName}',
                          style: OrbitTypography.h3.copyWith(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Row 3: WaveSeekBar (height 56)
                  ValueListenableBuilder<double>(
                    valueListenable: orbit.progress,
                    builder: (context, prog, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: orbit.isPlaying,
                        builder: (context, playing, _) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              WaveSeekBar(
                                progress: prog,
                                durationSeconds: track.durationSeconds,
                                isPlaying: playing,
                                bpm: track.bpm,
                                showTimes: false,
                                onSeek: orbit.seekTo,
                              ),
                              const SizedBox(height: 4),
                              // Row 4: times
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    WaveSeekBar.formatSeconds(
                                      (prog * track.durationSeconds).round(),
                                    ),
                                    style: OrbitTypography.caption.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  Text(
                                    WaveSeekBar.formatSeconds(
                                      track.durationSeconds,
                                    ),
                                    style: OrbitTypography.caption.copyWith(
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Row 5: Five translucent glass circles (52 px; Play is 68 px)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 292;
                      final circleSize = compact ? 44.0 : 52.0;
                      final playSize = compact ? 60.0 : 68.0;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: orbit.isShuffled,
                            builder: (context, shuffled, _) {
                              return _GlassControlCircle(
                                size: circleSize,
                                icon: Icons.shuffle_rounded,
                                label: 'Shuffle',
                                active: shuffled,
                                onTap: orbit.toggleShuffle,
                              );
                            },
                          ),
                          _GlassControlCircle(
                            size: circleSize,
                            icon: Icons.skip_previous_rounded,
                            label: 'Previous track',
                            iconSize: 26,
                            onTap: orbit.previousTrack,
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: orbit.isPlaying,
                            builder: (context, playing, _) {
                              return PlayButton(
                                isPlaying: playing,
                                size: playSize,
                                glassMode: true,
                                iconColor: Colors.white,
                                onPressed: orbit.togglePlay,
                              );
                            },
                          ),
                          _GlassControlCircle(
                            size: circleSize,
                            icon: Icons.skip_next_rounded,
                            label: 'Next track',
                            iconSize: 26,
                            onTap: () => orbit.nextTrack(),
                          ),
                          ValueListenableBuilder<Set<String>>(
                            valueListenable: orbit.likedTrackIds,
                            builder: (context, likedIds, _) {
                              final liked = likedIds.contains(track.id);
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _GlassCircleShell(
                                    size: circleSize,
                                    onTap: () => orbit.toggleTrackLike(track),
                                    child: LikeButton(
                                      liked: liked,
                                      size: 22,
                                      touchSize: circleSize,
                                      activeColor: OrbitTokens.orange,
                                      inactiveColor: Colors.white,
                                      onTap: () => orbit.toggleTrackLike(track),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  AnimatedOpacity(
                                    opacity: liked ? 1.0 : 0.0,
                                    duration: OrbitTokens.durPress,
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: OrbitTokens.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCircleShell extends StatefulWidget {
  const _GlassCircleShell({
    required this.size,
    required this.child,
    required this.onTap,
  });

  final double size;
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_GlassCircleShell> createState() => _GlassCircleShellState();
}

class _GlassCircleShellState extends State<_GlassCircleShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  void _setPressed(bool down) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _scaleController.animateWith(
      Springs.simulate(
        down ? Springs.snappy : Springs.liquid,
        start: _scaleController.value,
        end: down ? 0.90 : 1.0,
        velocity: down ? 0.0 : 2.0,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        OrbitHaptics.selection();
        widget.onTap();
      },
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) => Transform.scale(
          scale: _scaleController.value.clamp(0.84, 1.12),
          child: child,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.36),
              width: 1.0,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _GlassControlCircle extends StatelessWidget {
  const _GlassControlCircle({
    required this.size,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.iconSize = 22.0,
  });

  final double size;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlassCircleShell(
            size: size,
            onTap: onTap,
            child: Icon(
              icon,
              size: iconSize,
              color: active ? OrbitTokens.orange : Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedOpacity(
            opacity: active ? 1.0 : 0.0,
            duration: OrbitTokens.durPress,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: OrbitTokens.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Looped marquee auto-scroll text when overflowing, with edge alpha fade.
class _MarqueeText extends StatefulWidget {
  const _MarqueeText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  final ScrollController _scrollController = ScrollController();
  Timer? _loopTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleLoop());
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _loopTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleLoop());
    }
  }

  void _scheduleLoop() {
    _loopTimer?.cancel();
    if (_disposed || !mounted) return;
    _loopTimer = Timer(const Duration(milliseconds: 1400), () async {
      if (_disposed || !mounted || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 2.0) return;

      final duration = Duration(
        milliseconds: (maxExtent * 28).round().clamp(1400, 7000),
      );
      try {
        await _scrollController.animateTo(
          maxExtent,
          duration: duration,
          curve: Curves.linear,
        );
        if (_disposed || !mounted) return;
        _loopTimer = Timer(const Duration(milliseconds: 900), () async {
          if (_disposed || !mounted || !_scrollController.hasClients) return;
          try {
            await _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
            );
            _scheduleLoop();
          } catch (_) {}
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _loopTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.06, 0.94, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
        ),
      ),
    );
  }
}
