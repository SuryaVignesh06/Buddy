import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/haptics.dart';
import '../core/orbit_state.dart';
import '../core/springs.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import '../data/mock.dart';
import 'app_image.dart';
import 'glass_lens.dart';

/// Controller managing the long-press Peek glass card (Tier A blur sigma=24)
/// with drag-to-action or release-to-dismiss.
class PeekOverlayController {
  PeekOverlayController._({
    required this.entry,
    required this.orbit,
    required this.playlist,
    required this.onOpenDetail,
  });

  final OverlayEntry entry;
  final OrbitController orbit;
  final OrbitPlaylist playlist;
  final VoidCallback onOpenDetail;

  final ValueNotifier<int?> hoveredAction = ValueNotifier<int?>(null);
  final List<GlobalKey> _actionKeys = List.generate(3, (_) => GlobalKey());
  bool _disposed = false;

  static PeekOverlayController show({
    required BuildContext context,
    required OrbitController controller,
    required OrbitPlaylist playlist,
    required VoidCallback onOpenDetail,
  }) {
    controller.setBackdropSuppressed(true);

    late final PeekOverlayController handle;
    final entry = OverlayEntry(
      builder: (_) => _PeekOverlayView(controller: handle),
    );
    handle = PeekOverlayController._(
      entry: entry,
      orbit: controller,
      playlist: playlist,
      onOpenDetail: onOpenDetail,
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return handle;
  }

  void updatePointer(Offset globalPos) {
    if (_disposed) return;
    int? nextHover;
    for (var i = 0; i < _actionKeys.length; i++) {
      final box =
          _actionKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.inflate(6).contains(globalPos)) {
        nextHover = i;
        break;
      }
    }
    if (hoveredAction.value != nextHover) {
      if (nextHover != null) OrbitHaptics.selection();
      hoveredAction.value = nextHover;
    }
  }

  void releaseAt(Offset globalPos) {
    updatePointer(globalPos);
    final action = hoveredAction.value;
    if (action == 0) {
      orbit.playPlaylist(playlist);
    } else if (action == 1) {
      orbit.addPlaylistToQueue(playlist);
    } else if (action == 2) {
      orbit.togglePlaylistSaved(playlist);
    }
    dismissImmediate();
  }

  void dismissImmediate() {
    if (_disposed) return;
    _disposed = true;
    orbit.setBackdropSuppressed(false);
    entry.remove();
    hoveredAction.dispose();
  }
}

class _PeekOverlayView extends StatefulWidget {
  const _PeekOverlayView({required this.controller});

  final PeekOverlayController controller;

  @override
  State<_PeekOverlayView> createState() => _PeekOverlayViewState();
}

class _PeekOverlayViewState extends State<_PeekOverlayView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController.unbounded(vsync: this, value: 0.88);
    _enterController.animateWith(
      Springs.simulate(Springs.bouncy, start: 0.88, end: 1.0),
    );
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlist = widget.controller.playlist;
    final previewTracks =
        widget.controller.orbit.tracksForPlaylist(playlist).take(5).toList();
    final isSaved = widget.controller.orbit.isPlaylistSaved(playlist.id);
    final maxH = MediaQuery.sizeOf(context).height * 0.82;

    return Material(
      color: Colors.black.withValues(alpha: 0.66),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.controller.dismissImmediate,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: OrbitTokens.space20),
            child: GestureDetector(
              onTap: () {},
              child: AnimatedBuilder(
                animation: _enterController,
                builder: (context, child) {
                  final scale = _enterController.value.clamp(0.84, 1.08);
                  return Transform.scale(scale: scale, child: child);
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 360, maxHeight: maxH),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(OrbitTokens.radiusSheet),
                    child: BackdropFilter(
                      filter: ImageFilter.compose(
                        outer: const ColorFilter.matrix(
                          GlassLens.liquidColorMatrix,
                        ),
                        inner: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(OrbitTokens.space20),
                        decoration: BoxDecoration(
                          color: OrbitTokens.surface1.withValues(alpha: 0.78),
                          borderRadius:
                              BorderRadius.circular(OrbitTokens.radiusSheet),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                          boxShadow: OrbitTokens.softElevation,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AppImage(
                                    id: playlist.id,
                                    imageUrl: playlist.imageUrl,
                                    seed: playlist.seed,
                                    primaryColor: playlist.dominantColor,
                                    secondaryColor: playlist.secondaryColor,
                                    width: 56,
                                    height: 56,
                                    borderRadius: OrbitTokens.radiusCardArt,
                                  ),
                                  const SizedBox(width: OrbitTokens.space12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playlist.title,
                                          style: OrbitTypography.h3,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${playlist.creator} • ${playlist.durationLabel}',
                                          style: OrbitTypography.caption,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: OrbitTokens.space16),
                              Text(
                                '5-TRACK PREVIEW',
                                style: OrbitTypography.nav.copyWith(
                                  color: OrbitTokens.orange,
                                ),
                              ),
                              const SizedBox(height: OrbitTokens.space8),
                              ...List.generate(previewTracks.length, (i) {
                                final track = previewTracks[i];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        child: Text(
                                          '${i + 1}',
                                          style: OrbitTypography.caption,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          track.title,
                                          style: OrbitTypography.body,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: OrbitTokens.space8),
                                      Text(
                                        track.formattedDuration,
                                        style: OrbitTypography.caption,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: OrbitTokens.space16),
                              ValueListenableBuilder<int?>(
                                valueListenable:
                                    widget.controller.hoveredAction,
                                builder: (context, hovered, _) {
                                  return Row(
                                    children: [
                                      _PeekActionButton(
                                        key: widget.controller._actionKeys[0],
                                        icon: Icons.play_arrow_rounded,
                                        label: 'Play',
                                        active: hovered == 0,
                                      ),
                                      const SizedBox(width: OrbitTokens.space8),
                                      _PeekActionButton(
                                        key: widget.controller._actionKeys[1],
                                        icon: Icons.queue_music_rounded,
                                        label: 'Queue',
                                        active: hovered == 1,
                                      ),
                                      const SizedBox(width: OrbitTokens.space8),
                                      _PeekActionButton(
                                        key: widget.controller._actionKeys[2],
                                        icon: isSaved
                                            ? Icons.bookmark_rounded
                                            : Icons.bookmark_border_rounded,
                                        label: isSaved ? 'Saved' : 'Save',
                                        active: hovered == 2,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: OrbitTokens.space12),
                              Center(
                                child: Text(
                                  'Drag onto an action or release to dismiss',
                                  style: OrbitTypography.caption.copyWith(
                                    color: OrbitTokens.textMuted,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeekActionButton extends StatelessWidget {
  const _PeekActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: OrbitTokens.durPress,
        height: 44,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [OrbitTokens.flameRed, OrbitTokens.orange],
                )
              : null,
          color: active ? null : OrbitTokens.surface3,
          borderRadius: BorderRadius.circular(OrbitTokens.radiusChip),
          border: Border.all(
            color: active
                ? OrbitTokens.emberLight
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? OrbitTokens.bg : OrbitTokens.textPrimary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: OrbitTypography.chip.copyWith(
                  color: active ? OrbitTokens.bg : OrbitTokens.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
