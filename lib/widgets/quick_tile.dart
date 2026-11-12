import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../data/mock.dart';
import 'app_image.dart';
import 'glass_surface.dart';
import 'pressable_scale.dart';
import 'wave_seek_bar.dart';

/// Quick-access grid tile with Tier B glass surface, inner-rimmed square art,
/// bold h3 title, and animated mini wave glyph when playing.
class QuickTile extends StatelessWidget {
  const QuickTile({
    super.key,
    required this.playlist,
    required this.onTap,
    this.isPlaying = false,
  });

  final OrbitPlaylist playlist;
  final VoidCallback onTap;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return OrbitPressable(
      onTap: onTap,
      pressedScale: 0.94,
      semanticLabel: 'Quick access ${playlist.title}',
      child: GlassSurface(
        radius: 10,
        intensity: isPlaying ? 1.15 : 0.9,
        tint: isPlaying ? OrbitTokens.orange : playlist.dominantColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Row(
            children: [
              // Artwork square with 1 px white 25% inner rim
              Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: AppImage(
                    id: playlist.id,
                    imageUrl: playlist.imageUrl,
                    seed: playlist.seed,
                    primaryColor: playlist.dominantColor,
                    secondaryColor: playlist.secondaryColor,
                    width: 48,
                    height: 48,
                    borderRadius: 6,
                  ),
                ),
              ),
              const SizedBox(width: OrbitTokens.space4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: OrbitTokens.space4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          playlist.title,
                          style: OrbitTypography.quickTile.copyWith(
                            color: isPlaying
                                ? OrbitTokens.orange
                                : OrbitTokens.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPlaying) ...[
                        const SizedBox(width: 4),
                        const MiniWaveGlyph(
                          active: true,
                          width: 16,
                          height: 12,
                          color: OrbitTokens.orange,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
