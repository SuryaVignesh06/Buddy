import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/springs.dart';
import '../core/tokens.dart';

/// Heart / like button that pops to 1.35 and settles with [Springs.bouncy],
/// emitting 6 tiny [OrbitTokens.flame] circle particles (no shaders).
class LikeButton extends StatefulWidget {
  const LikeButton({
    super.key,
    required this.liked,
    required this.onTap,
    this.size = 24.0,
    this.touchSize = OrbitTokens.minTouchTarget,
    this.activeColor = OrbitTokens.flame,
    this.inactiveColor = OrbitTokens.textPrimary,
    this.label,
  });

  final bool liked;
  final VoidCallback onTap;
  final double size;
  final double touchSize;
  final Color activeColor;
  final Color inactiveColor;
  final String? label;

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _burstController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController.unbounded(vsync: this, value: 1.0);
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.liked && widget.liked) {
      _playPopAndBurst();
    } else if (oldWidget.liked && !widget.liked) {
      _playUnpop();
    }
  }

  void _playPopAndBurst() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _scaleController.value = 1.0;
      return;
    }
    _scaleController.value = 1.35;
    _scaleController.animateWith(
      Springs.simulate(Springs.bouncy, start: 1.35, end: 1.0, velocity: -0.6),
    );
    _burstController.forward(from: 0.0);
  }

  void _playUnpop() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _scaleController.value = 0.84;
    _scaleController.animateWith(
      Springs.simulate(Springs.snappy, start: 0.84, end: 1.0),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.liked,
      label: widget.label ?? (widget.liked ? 'Unlike track' : 'Like track'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.touchSize,
          height: widget.touchSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _burstController,
                builder: (context, _) {
                  if (_burstController.value <= 0.0 ||
                      _burstController.value >= 1.0) {
                    return const SizedBox.shrink();
                  }
                  return IgnorePointer(
                    child: CustomPaint(
                      size: Size.square(widget.touchSize),
                      painter: _LikeBurstPainter(_burstController.value),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _scaleController,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _scaleController.value.clamp(0.75, 1.45),
                    child: Icon(
                      widget.liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: widget.size,
                      color: widget.liked
                          ? widget.activeColor
                          : widget.inactiveColor,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikeBurstPainter extends CustomPainter {
  _LikeBurstPainter(this.progress);

  final double progress;

  final Paint _paint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOutCubic.transform(progress);
    final alpha = (1.0 - eased).clamp(0.0, 1.0);
    final radius = (size.shortestSide * 0.22) + eased * (size.shortestSide * 0.38);
    final dotRadius = (3.2 * (1.0 - eased * 0.7)).clamp(0.8, 3.2);

    _paint.color = OrbitTokens.flame.withValues(alpha: alpha);
    for (var i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2.0 - math.pi / 6.0;
      final offset = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawCircle(offset, dotRadius, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LikeBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
