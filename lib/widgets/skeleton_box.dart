import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Shader-free shimmering skeleton placeholder driven by animated gradient alignment.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = OrbitTokens.radiusCardArt,
    this.circular = false,
  });

  final double width;
  final double height;
  final double borderRadius;
  final bool circular;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(
      widget.circular ? OrbitTokens.radiusArtistArt : widget.borderRadius,
    );

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: OrbitTokens.surface3,
          borderRadius: radius,
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final slide = _controller.value * 3.0 - 1.5;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment(slide - 1.0, -0.2),
                end: Alignment(slide + 1.0, 0.2),
                colors: const [
                  OrbitTokens.surface2,
                  OrbitTokens.surface3,
                  OrbitTokens.surface2,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}
