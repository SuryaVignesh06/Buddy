import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/orbit_state.dart';
import '../core/springs.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../data/mock.dart';
import 'app_image.dart';
import 'glass_lens.dart';
import 'play_button.dart';
import 'wave_seek_bar.dart';

/// Tier A glass mini player floating above the nav pill.
/// Supports swipe left/right with slight tilt & spring settle, 2 px mini wave
/// progress line, and morphing expansion into [GlassPlayerCard].
class MiniPlayer extends StatefulWidget {
  const MiniPlayer({
    super.key,
    required this.onExpand,
    this.enableBackdropBlur = true,
  });

  final ValueChanged<Rect?> onExpand;
  final bool enableBackdropBlur;

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boxKey = GlobalKey();
  late final AnimationController _dragController;
  int _slideDirection = 1;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController.unbounded(vsync: this, value: 0.0);
  }

  Rect? _measureRect() {
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _springBack({double velocity = 0.0}) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _dragController.value = 0.0;
      return;
    }
    _dragController.animateWith(
      Springs.simulate(
        Springs.liquid,
        start: _dragController.value,
        end: 0.0,
        velocity: velocity,
      ),
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orbit = OrbitScope.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: OrbitTokens.space16),
      child: ValueListenableBuilder<OrbitTrack>(
        valueListenable: orbit.currentTrack,
        builder: (context, track, _) {
          return Semantics(
            button: true,
            label:
                'Mini player: ${track.title} by ${track.artistName}. Tap to open Now Playing, swipe left or right to change tracks.',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onExpand(_measureRect()),
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < -220) {
                  widget.onExpand(_measureRect());
                }
              },
              onHorizontalDragStart: (_) => _dragController.stop(),
              onHorizontalDragUpdate: (details) {
                _dragController.value =
                    (_dragController.value + details.delta.dx).clamp(-76.0, 76.0);
              },
              onHorizontalDragEnd: (details) {
                final vx = details.primaryVelocity ?? 0;
                final dx = _dragController.value;
                if (dx < -34 || vx < -300) {
                  _slideDirection = 1;
                  orbit.nextTrack();
                } else if (dx > 34 || vx > 300) {
                  _slideDirection = -1;
                  orbit.previousTrack();
                }
                _springBack(velocity: vx * 0.15);
              },
              onHorizontalDragCancel: _springBack,
              child: AnimatedBuilder(
                animation: _dragController,
                builder: (context, child) {
                  final dx = _dragController.value;
                  return Transform.translate(
                    offset: Offset(dx * 0.55, 0),
                    child: Transform.rotate(
                      angle: dx * 0.00075,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: _boxKey,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(OrbitTokens.radiusMiniPlayer),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(OrbitTokens.radiusMiniPlayer),
                    child: _maybeBlur(
                      enabled: widget.enableBackdropBlur,
                      child: ValueListenableBuilder<Color>(
                        valueListenable: orbit.activeArtColor,
                        builder: (context, artColor, _) {
                          return Container(
                            height: OrbitTokens.miniPlayerHeight,
                            decoration: BoxDecoration(
                              color:
                                  OrbitTokens.surface1.withValues(alpha: 0.70),
                              borderRadius: BorderRadius.circular(
                                OrbitTokens.radiusMiniPlayer,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.24),
                                width: 1.0,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  artColor.withValues(alpha: 0.28),
                                  Colors.white.withValues(alpha: 0.08),
                                  OrbitTokens.flame.withValues(alpha: 0.08),
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: OrbitTokens.space8,
                                  ),
                                  child: Row(
                                    children: [
                                      AppImage(
                                        id: track.id,
                                        imageUrl: track.imageUrl,
                                        seed: track.seed,
                                        primaryColor: track.dominantColor,
                                        secondaryColor: track.secondaryColor,
                                        width: 44,
                                        height: 44,
                                        borderRadius:
                                            OrbitTokens.radiusQuickTile,
                                        heroTag: 'now_playing_art',
                                      ),
                                      const SizedBox(width: OrbitTokens.space12),
                                      Expanded(
                                        child: AnimatedSwitcher(
                                          duration: OrbitTokens.durChip,
                                          transitionBuilder:
                                              (child, animation) {
                                            final offset = Tween<Offset>(
                                              begin: Offset(
                                                _slideDirection * 0.18,
                                                0,
                                              ),
                                              end: Offset.zero,
                                            ).animate(animation);
                                            return FadeTransition(
                                              opacity: animation,
                                              child: SlideTransition(
                                                position: offset,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: Column(
                                            key: ValueKey<String>(track.id),
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                track.title,
                                                style: OrbitTypography.h3,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                track.artistName,
                                                style: OrbitTypography.caption,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: orbit.isPlaying,
                                        builder: (context, playing, _) {
                                          return PlayButton(
                                            isPlaying: playing,
                                            onPressed: orbit.togglePlay,
                                            size: 40,
                                            backgroundColor: OrbitTokens.accent,
                                            iconColor: OrbitTokens.bg,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // 2 px mini wave progress line along bottom edge
                                Positioned(
                                  left: OrbitTokens.space8,
                                  right: OrbitTokens.space8,
                                  bottom: 1,
                                  child: ValueListenableBuilder<double>(
                                    valueListenable: orbit.progress,
                                    builder: (context, progress, _) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable: orbit.isPlaying,
                                        builder: (context, playing, _) {
                                          return MiniWaveProgress(
                                            progress: progress,
                                            isPlaying: playing,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _maybeBlur({required bool enabled, required Widget child}) {
    if (!enabled) return child;
    return BackdropFilter(
      filter: ImageFilter.compose(
        outer: const ColorFilter.matrix(GlassLens.liquidColorMatrix),
        inner: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      ),
      child: child,
    );
  }
}
