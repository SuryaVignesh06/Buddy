import 'package:flutter/material.dart';

import '../core/haptics.dart';
import '../core/orbit_state.dart';
import '../core/springs.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../data/mock.dart';
import 'app_image.dart';
import 'glass_surface.dart';
import 'peek_overlay.dart';

/// Playlist / album card with Tier B glass frame (6 px padding, rim, top specular),
/// glass caption plate, spring press rebound, and long-press Peek.
class AlbumCard extends StatefulWidget {
  const AlbumCard({
    super.key,
    required this.playlist,
    required this.onTap,
    this.width = 148.0,
    this.heroTagPrefix = 'album',
  });

  final OrbitPlaylist playlist;
  final VoidCallback onTap;
  final double width;
  final String heroTagPrefix;

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  bool _pressed = false;
  PeekOverlayController? _peekController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    _pressed = pressed;
    setState(() {});
    if (MediaQuery.disableAnimationsOf(context)) {
      _pressController.value = pressed ? 0.94 : 1.0;
      return;
    }
    _pressController.animateWith(
      Springs.simulate(
        pressed ? Springs.snappy : Springs.liquid,
        start: _pressController.value,
        end: pressed ? 0.94 : 1.0,
        velocity: pressed ? 0.0 : 1.6,
      ),
    );
  }

  void _openPeek(Offset globalPosition) {
    OrbitHaptics.medium();
    final orbit = OrbitScope.read(context);
    _peekController = PeekOverlayController.show(
      context: context,
      controller: orbit,
      playlist: widget.playlist,
      onOpenDetail: widget.onTap,
    );
  }

  void _updatePeek(Offset globalPosition) {
    _peekController?.updatePointer(globalPosition);
  }

  void _closePeek(Offset globalPosition) {
    _peekController?.releaseAt(globalPosition);
    _peekController = null;
  }

  @override
  void dispose() {
    _pressController.dispose();
    _peekController?.dismissImmediate();
    _peekController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outerW = widget.width;
    final artSize = (outerW - 12.0).clamp(64.0, outerW);
    final heroTag = widget.heroTagPrefix.isEmpty
        ? 'art-${widget.playlist.id}'
        : '${widget.heroTagPrefix}_art-${widget.playlist.id}';

    return Semantics(
      button: true,
      label: '${widget.playlist.title}, ${widget.playlist.subtitle}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onLongPressStart: (details) {
          _setPressed(true);
          _openPeek(details.globalPosition);
        },
        onLongPressMoveUpdate: (details) {
          _updatePeek(details.globalPosition);
        },
        onLongPressEnd: (details) {
          _setPressed(false);
          _closePeek(details.globalPosition);
        },
        onLongPressCancel: () {
          _setPressed(false);
          _peekController?.dismissImmediate();
          _peekController = null;
        },
        child: AnimatedBuilder(
          animation: _pressController,
          builder: (context, child) {
            return Transform.scale(
              scale: _pressController.value.clamp(0.88, 1.07),
              child: child,
            );
          },
          child: SizedBox(
            width: outerW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glass frame (6 px padding, rim, top specular)
                GlassSurface(
                  radius: 14,
                  padding: const EdgeInsets.all(6),
                  tint: widget.playlist.dominantColor,
                  intensity: 0.9,
                  child: AppImage(
                    id: widget.playlist.id,
                    imageUrl: widget.playlist.imageUrl,
                    seed: widget.playlist.seed,
                    primaryColor: widget.playlist.dominantColor,
                    secondaryColor: widget.playlist.secondaryColor,
                    width: artSize,
                    height: artSize,
                    borderRadius: OrbitTokens.radiusCardArt,
                    heroTag: heroTag,
                    brightness: _pressed ? 0.9 : 1.0,
                  ),
                ),
                const SizedBox(height: OrbitTokens.space8),
                // Glass caption plate
                GlassSurface(
                  radius: 10,
                  intensity: 0.55,
                  enableHoverLift: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.playlist.title,
                        style: OrbitTypography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.playlist.subtitle,
                        style: OrbitTypography.caption,
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
      ),
    );
  }
}
