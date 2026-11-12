import 'package:flutter/material.dart';

import '../core/springs.dart';

/// Spring-driven press wrapper:
/// presses down to [pressedScale] (0.94) with [Springs.snappy]
/// and rebounds through ~1.03 on release with [Springs.liquid].
class OrbitPressable extends StatefulWidget {
  const OrbitPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onLongPressEnd,
    this.pressedScale = 0.94,
    this.semanticLabel,
    this.isButton = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressEnd;
  final double pressedScale;
  final String? semanticLabel;
  final bool isButton;

  @override
  State<OrbitPressable> createState() => _OrbitPressableState();
}

class _OrbitPressableState extends State<OrbitPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  void _animateTo(double target, {bool release = false}) {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scaleController.value = target;
      return;
    }
    _scaleController.animateWith(
      Springs.simulate(
        release ? Springs.liquid : Springs.snappy,
        start: _scaleController.value,
        end: target,
        velocity: release ? 1.8 : 0.0,
      ),
    );
  }

  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;
    _isPressed = pressed;
    if (pressed) {
      _animateTo(widget.pressedScale);
    } else {
      _animateTo(1.0, release: true);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: widget.isButton,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onLongPressStart: widget.onLongPress != null
            ? (_) {
                _setPressed(true);
                widget.onLongPress?.call();
              }
            : null,
        onLongPressEnd: widget.onLongPressEnd != null
            ? (_) {
                _setPressed(false);
                widget.onLongPressEnd?.call();
              }
            : (_) => _setPressed(false),
        child: AnimatedBuilder(
          animation: _scaleController,
          child: widget.child,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleController.value.clamp(0.86, 1.08),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
