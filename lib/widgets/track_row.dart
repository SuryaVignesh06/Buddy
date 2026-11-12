import 'package:flutter/material.dart';

import '../core/haptics.dart';
import '../core/springs.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../data/mock.dart';
import 'app_image.dart';
import 'glass_surface.dart';
import 'like_button.dart';
import 'wave_seek_bar.dart';

/// Track row supporting Tier B glass surface, real artwork, MiniWaveGlyph,
/// particle LikeButton, swipe-right to queue, and swipe-left to like.
class TrackRow extends StatefulWidget {
  const TrackRow({
    super.key,
    required this.track,
    required this.onTap,
    required this.onQueue,
    required this.onToggleLike,
    this.index,
    this.isActive = false,
    this.isPlaying = false,
    this.isLiked = false,
    this.onMoreTap,
    this.showArtwork = true,
  });

  final OrbitTrack track;
  final VoidCallback onTap;
  final VoidCallback onQueue;
  final VoidCallback onToggleLike;
  final int? index;
  final bool isActive;
  final bool isPlaying;
  final bool isLiked;
  final VoidCallback? onMoreTap;
  final bool showArtwork;

  @override
  State<TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<TrackRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swipeController;
  bool _dragging = false;
  bool _triggeredThreshold = false;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController.unbounded(vsync: this, value: 0.0);
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _dragging = true;
    _swipeController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final next = (_swipeController.value + details.delta.dx).clamp(-92.0, 92.0);
    if (next.abs() >= 56.0 && !_triggeredThreshold) {
      _triggeredThreshold = true;
      OrbitHaptics.selection();
    } else if (next.abs() < 56.0) {
      _triggeredThreshold = false;
    }
    _swipeController.value = next;
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final dx = _swipeController.value;
    if (dx >= 56.0) {
      widget.onQueue();
    } else if (dx <= -56.0) {
      widget.onToggleLike();
    }
    _triggeredThreshold = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      _swipeController.value = 0.0;
    } else {
      _swipeController.animateWith(
        Springs.simulate(Springs.liquid, start: dx, end: 0.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.track.title} by ${widget.track.artistName}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: () {
          _dragging = false;
          _swipeController.value = 0.0;
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OrbitTokens.screenPadding,
            vertical: 3,
          ),
          child: AnimatedBuilder(
            animation: _swipeController,
            builder: (context, child) {
              final dx = _swipeController.value;
              final isQueueReveal = dx > 4;
              final isLikeReveal = dx < -4;

              return Stack(
                children: [
                  if (isQueueReveal || isLikeReveal)
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OrbitTokens.space16,
                        ),
                        decoration: BoxDecoration(
                          color: isQueueReveal
                              ? OrbitTokens.orange.withValues(alpha: 0.24)
                              : OrbitTokens.flameRed.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: isQueueReveal
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          children: [
                            if (isQueueReveal) ...[
                              const Icon(
                                Icons.queue_music_rounded,
                                color: OrbitTokens.orange,
                                size: 20,
                              ),
                              const SizedBox(width: OrbitTokens.space8),
                              Text(
                                'Add to queue',
                                style: OrbitTypography.caption.copyWith(
                                  color: OrbitTokens.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ] else ...[
                              Text(
                                widget.isLiked ? 'Unlike' : 'Like',
                                style: OrbitTypography.caption.copyWith(
                                  color: OrbitTokens.amber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: OrbitTokens.space8),
                              Icon(
                                widget.isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: OrbitTokens.amber,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(_dragging || dx.abs() > 0.2 ? dx : 0.0, 0),
                    child: child,
                  ),
                ],
              );
            },
            child: GlassSurface(
              radius: 12,
              intensity: widget.isActive ? 0.95 : 0.42,
              tint: widget.isActive ? OrbitTokens.orange : null,
              enableHoverLift: false,
              padding: const EdgeInsets.symmetric(
                horizontal: OrbitTokens.space12,
                vertical: 6,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    if (widget.index != null)
                      SizedBox(
                        width: 26,
                        child: widget.isActive
                            ? MiniWaveGlyph(
                                active: widget.isPlaying,
                                width: 16,
                                height: 14,
                                color: OrbitTokens.orange,
                              )
                            : Text(
                                '${widget.index}',
                                style: OrbitTypography.bodyS.copyWith(
                                  color: OrbitTokens.textSecondary,
                                ),
                              ),
                      ),
                    if (widget.showArtwork) ...[
                      AppImage(
                        id: widget.track.id,
                        imageUrl: widget.track.imageUrl,
                        seed: widget.track.seed,
                        primaryColor: widget.track.dominantColor,
                        secondaryColor: widget.track.secondaryColor,
                        width: 44,
                        height: 44,
                        borderRadius: 6,
                      ),
                      const SizedBox(width: OrbitTokens.space12),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (widget.isActive && widget.index == null) ...[
                                MiniWaveGlyph(
                                  active: widget.isPlaying,
                                  width: 14,
                                  height: 12,
                                  color: OrbitTokens.orange,
                                ),
                                const SizedBox(width: OrbitTokens.space8),
                              ],
                              Expanded(
                                child: Text(
                                  widget.track.title,
                                  style: OrbitTypography.h3.copyWith(
                                    color: widget.isActive
                                        ? OrbitTokens.orange
                                        : OrbitTokens.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.track.artistName} • ${widget.track.formattedDuration}',
                            style: OrbitTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    LikeButton(
                      liked: widget.isLiked,
                      onTap: widget.onToggleLike,
                      size: 18,
                      touchSize: 40,
                      activeColor: OrbitTokens.flame,
                      inactiveColor: OrbitTokens.textSecondary,
                    ),
                    Semantics(
                      button: true,
                      label: 'More options for ${widget.track.title}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onMoreTap ?? widget.onQueue,
                        child: const SizedBox(
                          width: 40,
                          height: OrbitTokens.minTouchTarget,
                          child: Center(
                            child: Icon(
                              Icons.more_horiz_rounded,
                              color: OrbitTokens.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
