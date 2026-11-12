import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import 'app_image.dart';
import 'glass_surface.dart';

/// Collapsing adaptive-gradient header with clipped 232 px art that shrinks,
/// fades into a pinned app bar, and avoids overlapping scrolled body content.
class AdaptiveHeader extends StatelessWidget {
  const AdaptiveHeader({
    super.key,
    required this.title,
    required this.id,
    this.imageUrl,
    required this.dominantColor,
    required this.secondaryColor,
    required this.artSeed,
    required this.heroTag,
    required this.onBack,
    this.circularArt = false,
  });

  final String title;
  final String id;
  final String? imageUrl;
  final Color dominantColor;
  final Color secondaryColor;
  final int artSeed;
  final String heroTag;
  final VoidCallback onBack;
  final bool circularArt;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    const expandedHeight = 320.0;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      backgroundColor: OrbitTokens.black,
      elevation: 0,
      automaticallyImplyLeading: false,
      expandedHeight: expandedHeight,
      toolbarHeight: OrbitTokens.headerHeight,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: OrbitTokens.space8),
        child: GlassIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Back',
          onTap: onBack,
          buttonSize: 40,
          iconSize: 22,
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final minExtent = safeTop + OrbitTokens.headerHeight;
          final maxExtent = safeTop + expandedHeight;
          final collapseT =
              ((maxExtent - constraints.maxHeight) / (maxExtent - minExtent))
                  .clamp(0.0, 1.0);
          final artScale = (1.0 - collapseT * 0.40).clamp(0.60, 1.0);
          final artOpacity = (1.0 - collapseT * 1.65).clamp(0.0, 1.0);
          final titleOpacity = ((collapseT - 0.58) / 0.35).clamp(0.0, 1.0);

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Per-screen adaptive tint from dominant artwork colour fading to black
                AnimatedContainer(
                  duration: OrbitTokens.durRoute,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        dominantColor.withValues(alpha: 0.55),
                        dominantColor.withValues(alpha: 0.22),
                        OrbitTokens.black,
                      ],
                      stops: const [0.0, 0.58, 1.0],
                    ),
                  ),
                ),

                // Shrinking / fading centered artwork framed in Tier B glass
                Positioned(
                  top: safeTop + 26,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: artOpacity,
                    child: Transform.scale(
                      scale: artScale,
                      child: Center(
                        child: GlassSurface(
                          circular: circularArt,
                          radius: 14,
                          padding: const EdgeInsets.all(6),
                          tint: dominantColor,
                          enableHoverLift: false,
                          child: AppImage(
                            id: id,
                            imageUrl: imageUrl,
                            seed: artSeed,
                            primaryColor: dominantColor,
                            secondaryColor: secondaryColor,
                            width: 220,
                            height: 220,
                            borderRadius: OrbitTokens.radiusCardArt,
                            circular: circularArt,
                            heroTag: heroTag,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Pinned app bar title when collapsed
                Positioned(
                  top: safeTop,
                  left: 68,
                  right: OrbitTokens.space16,
                  height: OrbitTokens.headerHeight,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: titleOpacity,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: OrbitTypography.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
