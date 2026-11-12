import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../data/mock.dart';
import 'app_image.dart';
import 'glass_surface.dart';
import 'pressable_scale.dart';

/// Circular artist card with Tier B glass frame (6 px padding), real circular
/// artwork, and glass caption plate.
class ArtistCard extends StatelessWidget {
  const ArtistCard({
    super.key,
    required this.artist,
    required this.onTap,
    this.diameter = 132.0,
  });

  final OrbitArtist artist;
  final VoidCallback onTap;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final innerDiameter = (diameter - 12.0).clamp(56.0, diameter);

    return OrbitPressable(
      onTap: onTap,
      semanticLabel: '${artist.name}, Artist',
      child: SizedBox(
        width: diameter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GlassSurface(
                circular: true,
                padding: const EdgeInsets.all(6),
                tint: artist.dominantColor,
                intensity: 0.9,
                child: AppImage(
                  id: artist.id,
                  imageUrl: artist.imageUrl,
                  seed: artist.seed,
                  primaryColor: artist.dominantColor,
                  secondaryColor: artist.secondaryColor,
                  width: innerDiameter,
                  height: innerDiameter,
                  circular: true,
                  heroTag: 'art-${artist.id}',
                ),
              ),
            ),
            const SizedBox(height: OrbitTokens.space8),
            GlassSurface(
              radius: 10,
              intensity: 0.55,
              enableHoverLift: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    artist.name,
                    style: OrbitTypography.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Artist',
                    style: OrbitTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
