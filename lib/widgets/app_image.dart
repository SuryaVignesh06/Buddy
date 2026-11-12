import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../data/art_repository.dart';
import 'generated_art.dart';

/// Primary artwork widget backed by [CachedNetworkImage], animated alignment
/// shimmer placeholder, [Hero] transition tag, and [GeneratedArt] fallback.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.id,
    this.imageUrl,
    required this.seed,
    required this.primaryColor,
    required this.secondaryColor,
    this.width,
    this.height,
    this.borderRadius = OrbitTokens.radiusCardArt,
    this.circular = false,
    this.fit = BoxFit.cover,
    this.heroTag,
    this.brightness = 1.0,
    this.badgeIcon,
  });

  final String id;
  final String? imageUrl;
  final int seed;
  final Color primaryColor;
  final Color secondaryColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool circular;
  final BoxFit fit;
  final String? heroTag;
  final double brightness;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      circular ? OrbitTokens.radiusArtistArt : borderRadius,
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logicalW = width ?? height ?? 160.0;
    final cacheWidth = (logicalW * dpr).round().clamp(48, 1200);

    Widget content;
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      content = _buildFallback();
    } else {
      content = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 350),
        fadeOutDuration: const Duration(milliseconds: 180),
        memCacheWidth: cacheWidth,
        filterQuality: FilterQuality.medium,
        placeholder: (context, _) => _ShimmerPlaceholder(
          seedId: id,
          width: width,
          height: height,
          radius: radius,
        ),
        errorWidget: (context, _, _) => _buildFallback(),
      );
    }

    if (brightness < 0.99) {
      content = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: (1.0 - brightness).clamp(0.0, 0.6)),
          BlendMode.darken,
        ),
        child: content,
      );
    }

    if (badgeIcon != null) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          Positioned(
            right: 6,
            bottom: 6,
            child: Icon(
              badgeIcon,
              size: 16,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      );
    }

    final clipped = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: content,
      ),
    );

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(tag: heroTag!, child: clipped);
    }
    return clipped;
  }

  Widget _buildFallback() {
    return GeneratedArt(
      seed: seed,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      size: width == height ? width : null,
      borderRadius: borderRadius,
      circular: circular,
      brightness: brightness,
      badgeIcon: badgeIcon,
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder({
    required this.seedId,
    required this.width,
    required this.height,
    required this.radius,
  });

  final String seedId;
  final double? width;
  final double? height;
  final BorderRadius radius;

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
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
    final baseColor = ArtRepository.seededPlaceholderColor(widget.seedId);
    final highlightColor = Color.lerp(baseColor, Colors.white, 0.14)!;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final slide = _controller.value * 3.0 - 1.5;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.radius,
              gradient: LinearGradient(
                begin: Alignment(slide - 1.0, -0.25),
                end: Alignment(slide + 1.0, 0.25),
                colors: [baseColor, highlightColor, baseColor],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}
