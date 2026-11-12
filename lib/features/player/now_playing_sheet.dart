import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/orbit_state.dart';
import '../../core/springs.dart';
import '../../core/tokens.dart';
import '../../core/typography.dart';
import '../../data/mock.dart';
import '../../widgets/app_image.dart';
import '../../widgets/glass_player_card.dart';
import '../../widgets/glass_surface.dart';

/// Opens the full-screen Now Playing sheet, morphing out of [originRect]
/// (the MiniPlayer bounds) with [Springs.liquid].
Future<void> openNowPlayingSheet(
  BuildContext context, {
  Rect? originRect,
}) async {
  final orbit = OrbitScope.read(context);
  orbit.setBackdropSuppressed(true);
  try {
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NowPlayingSheet(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final size = MediaQuery.sizeOf(context);
          final startRect = originRect ??
              Rect.fromLTWH(
                16,
                size.height - 150,
                size.width - 32,
                OrbitTokens.miniPlayerHeight,
              );
          final endRect = Offset.zero & size;
          final springVal = animation.status == AnimationStatus.reverse
              ? Curves.easeInCubic.transform(animation.value)
              : _LiquidOvershootCurve().transform(animation.value);

          final rect = Rect.lerp(startRect, endRect, springVal.clamp(0.0, 1.05))!;
          final radius = lerpDouble(OrbitTokens.radiusMiniPlayer, 0.0, springVal.clamp(0.0, 1.0))!;
          final opacity = (animation.value * 2.2).clamp(0.0, 1.0);

          return Stack(
            children: [
              Positioned(
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Opacity(opacity: opacity, child: child),
                ),
              ),
            ],
          );
        },
      ),
    );
  } finally {
    orbit.setBackdropSuppressed(false);
  }
}

class _LiquidOvershootCurve extends Curve {
  @override
  double transformInternal(double t) {
    // Normalised Springs.liquid curve (~14% gentle settle, clamped for Rect interpolation)
    final sim = Springs.simulate(Springs.liquid, start: 0.0, end: 1.0);
    return sim.x(t * 0.72).clamp(0.0, 1.04);
  }
}

class NowPlayingSheet extends StatefulWidget {
  const NowPlayingSheet({super.key});

  @override
  State<NowPlayingSheet> createState() => _NowPlayingSheetState();
}

class _NowPlayingSheetState extends State<NowPlayingSheet>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _dismissController;
  late final AnimationController _artScaleController;
  bool _isDismissDragging = false;
  bool? _lastPlayingState;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController.unbounded(vsync: this, value: 0.0);
    _artScaleController = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dismissController.dispose();
    _artScaleController.dispose();
    super.dispose();
  }

  void _updateArtScale(bool isPlaying) {
    if (_lastPlayingState == isPlaying) return;
    _lastPlayingState = isPlaying;
    final target = isPlaying ? 1.0 : 0.9;
    if (!mounted || MediaQuery.disableAnimationsOf(context)) {
      _artScaleController.value = target;
      return;
    }
    _artScaleController.animateWith(
      Springs.simulate(
        Springs.bouncy,
        start: _artScaleController.value,
        end: target,
      ),
    );
  }

  void _openLyricsSheet(OrbitTrack track, OrbitController orbit) {
    OrbitHaptics.light();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FullscreenLyricsSheet(
        track: track,
        orbit: orbit,
      ),
    );
  }

  void _openQueueSheet(OrbitController orbit) {
    OrbitHaptics.light();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OrbitTokens.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OrbitTokens.radiusSheet),
        ),
      ),
      builder: (ctx) => _QueueSheet(orbit: orbit),
    );
  }

  void _openDevicesSheet(OrbitController orbit) {
    OrbitHaptics.light();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: OrbitTokens.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OrbitTokens.radiusSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OrbitTokens.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connect to a device', style: OrbitTypography.h2),
              const SizedBox(height: OrbitTokens.space12),
              _DeviceRow(
                icon: Icons.smartphone_rounded,
                title: 'This phone',
                subtitle: 'Orbit Spatial Audio',
                active: true,
                onTap: () => Navigator.pop(ctx),
              ),
              _DeviceRow(
                icon: Icons.headphones_rounded,
                title: 'Dot Pods Pro',
                subtitle: 'Ready to connect',
                active: false,
                onTap: () {
                  orbit.showToast('Switched audio to Dot Pods Pro');
                  Navigator.pop(ctx);
                },
              ),
              _DeviceRow(
                icon: Icons.speaker_rounded,
                title: 'Studio Monitor Amber',
                subtitle: 'Living Room • AirPlay',
                active: false,
                onTap: () {
                  orbit.showToast('Switched audio to Studio Monitor Amber');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDragStart(DragStartDetails details) {
    if (_scrollController.hasClients && _scrollController.offset > 2.0) return;
    _isDismissDragging = true;
    _dismissController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDismissDragging) return;
    final next = (_dismissController.value + details.delta.dy).clamp(0.0, 280.0);
    _dismissController.value = next;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDismissDragging) return;
    _isDismissDragging = false;
    final vy = details.primaryVelocity ?? 0.0;
    if (_dismissController.value > 110.0 || vy > 650.0) {
      Navigator.of(context).maybePop();
    } else {
      _dismissController.animateWith(
        Springs.simulate(
          Springs.liquid,
          start: _dismissController.value,
          end: 0.0,
          velocity: vy * 0.1,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orbit = OrbitScope.of(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: OrbitTokens.black,
      body: ValueListenableBuilder<OrbitTrack>(
        valueListenable: orbit.currentTrack,
        builder: (context, track, _) {
          return ValueListenableBuilder<Color>(
            valueListenable: orbit.activeArtColor,
            builder: (context, artColor, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: orbit.isPlaying,
                builder: (context, playing, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateArtScale(playing);
                  });

                  return AnimatedBuilder(
                    animation: Listenable.merge(
                      [_dismissController, _artScaleController],
                    ),
                    builder: (context, child) {
                      final dragY = _dismissController.value.clamp(0.0, 320.0);
                      final dragScale =
                          (1.0 - (dragY / 280.0) * 0.08).clamp(0.92, 1.0);
                      return Transform.translate(
                        offset: Offset(0, dragY),
                        child: Transform.scale(
                          scale: dragScale,
                          child: child,
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        // Full-bleed dark blurred artwork backdrop
                        Positioned.fill(
                          child: AppImage(
                            id: '${track.id}_bg',
                            imageUrl: track.imageUrl,
                            seed: track.seed,
                            primaryColor: track.dominantColor,
                            secondaryColor: track.secondaryColor,
                            fit: BoxFit.cover,
                            borderRadius: 0,
                          ),
                        ),

                        // Dark gradient + blurred flame glow behind GlassPlayerCard
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color.lerp(
                                      artColor,
                                      OrbitTokens.black,
                                      0.55,
                                    )!
                                        .withValues(alpha: 0.78),
                                    OrbitTokens.black.withValues(alpha: 0.90),
                                    OrbitTokens.black,
                                  ],
                                  stops: const [0.0, 0.58, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Centered ambient flame glow behind the card
                        Positioned(
                          top: safeTop + 64,
                          left: 0,
                          right: 0,
                          height: 360,
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                width: 320,
                                height: 320,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      OrbitTokens.flame.withValues(alpha: 0.42),
                                      OrbitTokens.flameRed
                                          .withValues(alpha: 0.20),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.52, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Scrollable sheet body with top-handle drag & overscroll dismiss
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollUpdateNotification &&
                                notification.depth == 0) {
                              final pixels = notification.metrics.pixels;
                              if (pixels < -12.0 &&
                                  (notification.dragDetails != null)) {
                                _dismissController.value =
                                    (-pixels - 12.0).clamp(0.0, 280.0);
                              } else if (pixels >= 0 &&
                                  _dismissController.value > 0 &&
                                  !_isDismissDragging) {
                                _dismissController.value = 0.0;
                              }
                            } else if (notification is ScrollEndNotification &&
                                notification.depth == 0 &&
                                _dismissController.value > 0 &&
                                !_isDismissDragging) {
                              if (_dismissController.value > 90.0) {
                                Navigator.of(context).maybePop();
                              } else {
                                _dismissController.animateWith(
                                  Springs.simulate(
                                    Springs.liquid,
                                    start: _dismissController.value,
                                    end: 0.0,
                                  ),
                                );
                              }
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: EdgeInsets.fromLTRB(
                              OrbitTokens.space20,
                              safeTop + OrbitTokens.space8,
                              OrbitTokens.space20,
                              safeBottom + OrbitTokens.space24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onVerticalDragStart: _handleDragStart,
                                  onVerticalDragUpdate: _handleDragUpdate,
                                  onVerticalDragEnd: _handleDragEnd,
                                  child: Column(
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 38,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.36),
                                            borderRadius: BorderRadius.circular(
                                              OrbitTokens.radiusChip,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: OrbitTokens.space8),

                                      // Top bar
                                      Row(
                                        children: [
                                          GlassIconButton(
                                            icon: Icons
                                                .keyboard_arrow_down_rounded,
                                            label: 'Collapse Now Playing',
                                            buttonSize: 40,
                                            iconSize: 28,
                                            onTap: () => Navigator.of(context)
                                                .maybePop(),
                                          ),
                                          Expanded(
                                            child: ValueListenableBuilder<String>(
                                              valueListenable:
                                                  orbit.currentSourceLabel,
                                              builder: (context, source, _) {
                                                return Column(
                                                  children: [
                                                    Text(
                                                      'PLAYING FROM',
                                                      style: OrbitTypography.nav
                                                          .copyWith(
                                                        color: OrbitTokens
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      source,
                                                      style: OrbitTypography.h3,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                          GlassIconButton(
                                            icon: Icons.more_horiz_rounded,
                                            label: 'Track options',
                                            buttonSize: 40,
                                            onTap: () =>
                                                orbit.addToQueue(track),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: OrbitTokens.space16),

                                // Main GlassPlayerCard with WaveSeekBar
                                AnimatedBuilder(
                                  animation: _artScaleController,
                                  builder: (context, _) {
                                    return GlassPlayerCard(
                                      track: track,
                                      orbit: orbit,
                                      artScale: _artScaleController.value
                                          .clamp(0.85, 1.06),
                                      onDevicesTap: () =>
                                          _openDevicesSheet(orbit),
                                    );
                                  },
                                ),
                                const SizedBox(height: OrbitTokens.space16),

                                // Bottom utility row: Devices, Repeat (with orange dot), Queue
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GlassIconButton(
                                      icon: Icons.speaker_group_outlined,
                                      label: 'Devices',
                                      buttonSize: 42,
                                      onTap: () => _openDevicesSheet(orbit),
                                    ),
                                    ValueListenableBuilder<int>(
                                      valueListenable: orbit.repeatMode,
                                      builder: (context, mode, _) {
                                        final active = mode > 0;
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GlassIconButton(
                                              icon: mode == 2
                                                  ? Icons.repeat_one_rounded
                                                  : Icons.repeat_rounded,
                                              label: 'Repeat mode',
                                              buttonSize: 42,
                                              iconColor: active
                                                  ? OrbitTokens.orange
                                                  : OrbitTokens.textPrimary,
                                              tint: active
                                                  ? OrbitTokens.orange
                                                  : null,
                                              onTap: orbit.cycleRepeat,
                                            ),
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
                                        );
                                      },
                                    ),
                                    GlassIconButton(
                                      icon: Icons.queue_music_rounded,
                                      label: 'Up next queue',
                                      buttonSize: 42,
                                      onTap: () => _openQueueSheet(orbit),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: OrbitTokens.space16),

                                // Lyrics peek card
                                GlassSurface(
                                  radius: 20,
                                  tint: artColor,
                                  intensity: 0.95,
                                  onTap: () => _openLyricsSheet(track, orbit),
                                  padding:
                                      const EdgeInsets.all(OrbitTokens.space16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('Lyrics', style: OrbitTypography.h3),
                                          const Spacer(),
                                          const Icon(
                                            Icons.open_in_full_rounded,
                                            size: 18,
                                            color: OrbitTokens.textPrimary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: OrbitTokens.space8),
                                      Text(
                                        track.lyrics.isNotEmpty
                                            ? track.lyrics.first.text
                                            : 'Instrumental transmission in high-resolution amber spatial audio.',
                                        style: OrbitTypography.h2.copyWith(
                                          color: OrbitTokens.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FullscreenLyricsSheet extends StatelessWidget {
  const _FullscreenLyricsSheet({
    required this.track,
    required this.orbit,
  });

  final OrbitTrack track;
  final OrbitController orbit;

  @override
  Widget build(BuildContext context) {
    final lines = track.lyrics.isNotEmpty
        ? track.lyrics
        : const [
            LyricLine(timestampSeconds: 0, text: 'Instrumental soundscape'),
            LyricLine(
              timestampSeconds: 45,
              text: 'Recorded live in warm analog spatial stereo',
            ),
          ];

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: BoxDecoration(
        color: Color.lerp(track.dominantColor, OrbitTokens.surface1, 0.65),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(OrbitTokens.radiusSheet),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: OrbitTokens.space12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: OrbitTokens.space20,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title, style: OrbitTypography.h3),
                        Text(track.artistName, style: OrbitTypography.caption),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: OrbitTokens.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: orbit.progress,
                builder: (context, progress, _) {
                  final currentSeconds =
                      (progress * track.durationSeconds).round();
                  var activeIndex = 0;
                  for (var i = 0; i < lines.length; i++) {
                    if (currentSeconds >= lines[i].timestampSeconds) {
                      activeIndex = i;
                    }
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(OrbitTokens.space24),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: OrbitTokens.space20),
                    itemBuilder: (context, i) {
                      final isActive = i == activeIndex;
                      return GestureDetector(
                        onTap: () {
                          OrbitHaptics.selection();
                          orbit.seekTo(
                            lines[i].timestampSeconds / track.durationSeconds,
                          );
                        },
                        child: AnimatedDefaultTextStyle(
                          duration: OrbitTokens.durChip,
                          style: OrbitTypography.h2.copyWith(
                            color: isActive
                                ? OrbitTokens.textPrimary
                                : Colors.white.withValues(alpha: 0.45),
                          ),
                          child: Text(lines[i].text),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet({required this.orbit});

  final OrbitController orbit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.35,
        builder: (context, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  OrbitTokens.space20,
                  OrbitTokens.space20,
                  OrbitTokens.space20,
                  OrbitTokens.space8,
                ),
                child: Text('Next in Orbit', style: OrbitTypography.h2),
              ),
              Expanded(
                child: ValueListenableBuilder<List<OrbitTrack>>(
                  valueListenable: orbit.queue,
                  builder: (context, items, _) {
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final track = items[i];
                        return ListTile(
                          leading: AppImage(
                            id: track.id,
                            imageUrl: track.imageUrl,
                            seed: track.seed,
                            primaryColor: track.dominantColor,
                            secondaryColor: track.secondaryColor,
                            width: 44,
                            height: 44,
                            borderRadius: 4,
                          ),
                          title: Text(
                            track.title,
                            style: OrbitTypography.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            track.artistName,
                            style: OrbitTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            track.formattedDuration,
                            style: OrbitTypography.caption,
                          ),
                          onTap: () {
                            orbit.playTrack(track);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: active ? OrbitTokens.orange : OrbitTokens.textSecondary,
      ),
      title: Text(
        title,
        style: OrbitTypography.h3.copyWith(
          color: active ? OrbitTokens.orange : OrbitTokens.textPrimary,
        ),
      ),
      subtitle: Text(subtitle, style: OrbitTypography.caption),
      trailing: active
          ? const Icon(Icons.check_circle_rounded, color: OrbitTokens.orange)
          : null,
      onTap: onTap,
    );
  }
}
