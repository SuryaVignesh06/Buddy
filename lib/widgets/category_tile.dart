import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../data/mock.dart';
import 'app_image.dart';
import 'glass_surface.dart';
import 'pressable_scale.dart';

/// 100 px tall Search browse category tile with Tier B glass tint and 25°-rotated real artwork.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.onTap,
  });

  final OrbitCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OrbitPressable(
      onTap: onTap,
      semanticLabel: '${category.title} category',
      child: GlassSurface(
        radius: 12,
        tint: category.gradientStart,
        intensity: 1.05,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                category.gradientStart.withValues(alpha: 0.46),
                category.gradientEnd.withValues(alpha: 0.34),
              ],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -8,
                child: Transform.rotate(
                  angle: 25.0 * math.pi / 180.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(OrbitTokens.radiusQuickTile),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 12,
                          offset: Offset(-2, 4),
                        ),
                      ],
                    ),
                    child: AppImage(
                      id: category.id,
                      imageUrl: category.imageUrl,
                      seed: category.artSeed,
                      primaryColor: category.gradientStart,
                      secondaryColor: category.gradientEnd,
                      width: 66,
                      height: 66,
                      borderRadius: OrbitTokens.radiusQuickTile,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(OrbitTokens.space12),
                child: FractionallySizedBox(
                  widthFactor: 0.78,
                  child: Text(
                    category.title,
                    style: OrbitTypography.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
