import 'package:flutter/material.dart';

import '../core/springs.dart';
import '../core/tokens.dart';

/// Circular play/pause trigger with 220 ms icon morph, spring press bounce,
/// and expanding flame ring ripple on press.
class PlayButton extends StatefulWidget {
  const PlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 40.0,
    this.backgroundColor = OrbitTokens.accent,
    this.iconColor = OrbitTokens.bg,
    this.semanticLabel,
    this.glassMode = false,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final String? semanticLabel;
  final bool glassMode;

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> with TickerProviderStateMixin {
  late final AnimationController _glyphController;
  late final AnimationController _scaleController;
  late final AnimationController _rippleController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _glyphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.isPlaying ? 1.0 : 0.0,
    );
    _scaleController = AnimationController.unbounded(vsync: this, value: 1.0);
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
  }

  @override
  void didUpdateWidget(covariant PlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _glyphController.forward();
      } else {
        _glyphController.reverse();
      }
    }
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    _pressed = pressed;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scaleController.value = pressed ? 0.94 : 1.0;
      return;
    }
    _scaleController.animateWith(
      Springs.simulate(
        pressed ? Springs.snappy : Springs.liquid,
        start: _scaleController.value,
        end: pressed ? 0.94 : 1.0,
        velocity: pressed ? 0.0 : 2.0,
      ),
    );
  }

  void _handleTap() {
    if (!MediaQuery.disableAnimationsOf(context)) {
      _rippleController.forward(from: 0.0);
    }
    widget.onPressed();
  }

  @override
  void dispose() {
    _glyphController.dispose();
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetSize = widget.size < OrbitTokens.minTouchTarget
        ? OrbitTokens.minTouchTarget
        : widget.size;

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? (widget.isPlaying ? 'Pause' : 'Play'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: SizedBox.square(
          dimension: targetSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Expanding ripple ring on press
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, _) {
                  final v = _rippleController.value;
                  if (v <= 0.0 || v >= 1.0) return const SizedBox.shrink();
                  final eased = Curves.easeOutCubic.transform(v);
                  final ringSize = widget.size * (1.0 + 0.55 * eased);
                  final alpha = (1.0 - eased) * 0.65;
                  return IgnorePointer(
                    child: Container(
                      width: ringSize,
                      height: ringSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (widget.glassMode
                                  ? OrbitTokens.orange
                                  : widget.backgroundColor)
                              .withValues(alpha: alpha),
                          width: 2.2 * (1.0 - eased * 0.6),
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _scaleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleController.value.clamp(0.86, 1.1),
                    child: child,
                  );
                },
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: widget.glassMode
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.22),
                              Colors.white.withValues(alpha: 0.10),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: OrbitTokens.flameRed.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          gradient: widget.backgroundColor == OrbitTokens.accent
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    OrbitTokens.orange,
                                    OrbitTokens.flameRed,
                                  ],
                                )
                              : null,
                          color: widget.backgroundColor == OrbitTokens.accent
                              ? null
                              : widget.backgroundColor,
                          shape: BoxShape.circle,
                          boxShadow: widget.size >= 56
                              ? [
                                  BoxShadow(
                                    color: OrbitTokens.flameRed
                                        .withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : null,
                        ),
                  child: Center(
                    child: AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: _glyphController,
                      size: widget.size * 0.46,
                      color: widget.iconColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
