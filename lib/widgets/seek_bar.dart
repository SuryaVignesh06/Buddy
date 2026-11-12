import 'package:flutter/material.dart';

import '../core/haptics.dart';
import '../core/tokens.dart';
import '../core/typography.dart';

/// Custom 4 px progress slider with drag-revealed 12 px thumb and floating time bubble.
class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.progress,
    required this.durationSeconds,
    required this.onSeek,
  });

  final double progress;
  final int durationSeconds;
  final ValueChanged<double> onSeek;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  bool _dragging = false;
  double _dragValue = 0.0;
  int _lastHapticBucket = -1;

  String _formatSeconds(int seconds) {
    final s = seconds.clamp(0, 35999);
    final mins = s ~/ 60;
    final rem = s % 60;
    return '$mins:${rem.toString().padLeft(2, '0')}';
  }

  void _updateFromLocalX(double localX, double width) {
    final next = (localX / width).clamp(0.0, 1.0);
    final bucket = (next * 20).floor();
    if (bucket != _lastHapticBucket) {
      _lastHapticBucket = bucket;
      OrbitHaptics.selection();
    }
    setState(() => _dragValue = next);
    widget.onSeek(next);
  }

  @override
  Widget build(BuildContext context) {
    final displayProgress = _dragging ? _dragValue : widget.progress.clamp(0.0, 1.0);
    final elapsed = (displayProgress * widget.durationSeconds).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final thumbX = (displayProgress * width).clamp(6.0, width - 6.0);

            return Semantics(
              slider: true,
              label: 'Playback position',
              value: _formatSeconds(elapsed),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  setState(() {
                    _dragging = true;
                    _dragValue = widget.progress;
                  });
                  _updateFromLocalX(details.localPosition.dx, width);
                },
                onHorizontalDragUpdate: (details) {
                  _updateFromLocalX(details.localPosition.dx, width);
                },
                onHorizontalDragEnd: (_) {
                  setState(() => _dragging = false);
                },
                onTapDown: (details) {
                  _updateFromLocalX(details.localPosition.dx, width);
                },
                child: SizedBox(
                  height: 36,
                  width: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      // Floating time bubble above thumb while dragging
                      if (_dragging)
                        Positioned(
                          left: (thumbX - 24).clamp(0.0, (width - 48).clamp(0.0, width)),
                          top: -26,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: OrbitTokens.surface3,
                              borderRadius:
                                  BorderRadius.circular(OrbitTokens.radiusChip),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Text(
                              _formatSeconds(elapsed),
                              style: OrbitTypography.caption.copyWith(
                                color: OrbitTokens.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      // 4 px track (surface4)
                      Container(
                        height: 4,
                        width: width,
                        decoration: BoxDecoration(
                          color: OrbitTokens.surface4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Played portion (white)
                      Container(
                        height: 4,
                        width: width * displayProgress,
                        decoration: BoxDecoration(
                          color: _dragging
                              ? OrbitTokens.accent
                              : OrbitTokens.textPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // 12 px thumb revealed on drag
                      AnimatedPositioned(
                        duration: _dragging
                            ? Duration.zero
                            : OrbitTokens.durPress,
                        left: thumbX - 6,
                        child: AnimatedScale(
                          scale: _dragging ? 1.0 : 0.0,
                          duration: OrbitTokens.durPress,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: OrbitTokens.textPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                ),
                              ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatSeconds(elapsed),
              style: OrbitTypography.caption.copyWith(
                color: OrbitTokens.textSecondary,
              ),
            ),
            Text(
              _formatSeconds(widget.durationSeconds),
              style: OrbitTypography.caption.copyWith(
                color: OrbitTokens.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
