import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/orbit_state.dart';
import '../../core/springs.dart';
import '../../core/tokens.dart';
import '../../core/typography.dart';
import '../../data/mock.dart';
import '../../widgets/app_image.dart';
import '../../widgets/dot_logo.dart';
import '../../widgets/generated_art.dart';
import '../../widgets/glass_surface.dart';

/// Create destination: build a custom Orbit Mix with glass preview & track picker.
class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final TextEditingController _titleController =
      TextEditingController(text: 'Late Night Amber');
  final TextEditingController _descController = TextEditingController();
  final Set<String> _selectedTrackIds = {'trk_01', 'trk_02', 'trk_07', 'trk_11'};
  int _paletteIndex = 0;

  static const List<(String, Color, Color)> _palettes = [
    ('Solar Flare', OrbitTokens.flameRed, OrbitTokens.ember),
    ('Amber Glow', OrbitTokens.amber, OrbitTokens.crimson),
    ('Velvet Rose', OrbitTokens.pinkRed, Color(0xFF400E2A)),
    ('Midnight Indigo', Color(0xFF4E5CF6), Color(0xFF14184D)),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit(OrbitController orbit) {
    final palette = _palettes[_paletteIndex];
    orbit.createPlaylist(
      title: _titleController.text,
      description: _descController.text,
      accentColor: palette.$2,
      secondaryColor: palette.$3,
      trackIds: _selectedTrackIds.toList(),
    );
    orbit.selectTab(2);
  }

  @override
  Widget build(BuildContext context) {
    final orbit = OrbitScope.of(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomReserve = OrbitTokens.navPillHeight +
        OrbitTokens.navBottomMargin +
        OrbitTokens.miniPlayerHeight +
        OrbitTokens.miniPlayerGap +
        OrbitTokens.space24 +
        safeBottom +
        keyboardInset;
    final palette = _palettes[_paletteIndex];

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) {
          orbit.setTabScrollOffset(3, notification.metrics.pixels);
        }
        return false;
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          OrbitTokens.screenPadding,
          safeTop + OrbitTokens.space12,
          OrbitTokens.screenPadding,
          bottomReserve,
        ),
        children: [
          SizedBox(
            height: OrbitTokens.headerHeight,
            child: Row(
              children: [
                const DotLogo(size: 32, headphones: true, beatPulse: 0.4),
                const SizedBox(width: OrbitTokens.space12),
                Expanded(
                  child: Text(
                    'Create Mix',
                    style: OrbitTypography.h1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: OrbitTokens.space8),
          Text(
            'Design a custom playlist with glass cover art and save it straight to Your Library.',
            style: OrbitTypography.body.copyWith(color: OrbitTokens.textSecondary),
          ),
          const SizedBox(height: OrbitTokens.space20),

          // Glass Live cover preview + Title input
          GlassSurface(
            radius: 16,
            tint: palette.$2,
            intensity: 1.0,
            padding: const EdgeInsets.all(OrbitTokens.space16),
            child: Row(
              children: [
                GeneratedArt(
                  seed: _titleController.text.hashCode + _paletteIndex * 19,
                  primaryColor: palette.$2,
                  secondaryColor: palette.$3,
                  size: 84,
                  borderRadius: OrbitTokens.radiusCardArt,
                ),
                const SizedBox(width: OrbitTokens.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => setState(() {}),
                        style: OrbitTypography.h3,
                        cursorColor: OrbitTokens.orange,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Mix name',
                          hintStyle: OrbitTypography.h3.copyWith(
                            color: OrbitTokens.textMuted,
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 12),
                      TextField(
                        controller: _descController,
                        style: OrbitTypography.bodyS.copyWith(
                          color: OrbitTokens.textPrimary,
                        ),
                        cursorColor: OrbitTokens.orange,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Add a mood description (optional)',
                          hintStyle: OrbitTypography.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: OrbitTokens.space20),

          // Palette vibe selector
          Text('Artwork Vibe', style: OrbitTypography.h3),
          const SizedBox(height: OrbitTokens.space12),
          Wrap(
            spacing: OrbitTokens.space8,
            runSpacing: OrbitTokens.space8,
            children: List.generate(_palettes.length, (i) {
              final item = _palettes[i];
              final selected = i == _paletteIndex;
              return Semantics(
                button: true,
                selected: selected,
                label: '${item.$1} artwork palette',
                child: GestureDetector(
                  onTap: () {
                    OrbitHaptics.selection();
                    setState(() => _paletteIndex = i);
                  },
                  child: AnimatedContainer(
                    duration: OrbitTokens.durChip,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [OrbitTokens.flameRed, OrbitTokens.orange],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.14),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(OrbitTokens.radiusChip),
                      border: Border.all(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.$2,
                            border: Border.all(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.$1,
                            style: OrbitTypography.chip.copyWith(
                              color: OrbitTokens.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: OrbitTokens.space24),

          // Primary liquid CTA button
          GestureDetector(
            onTap: () => _submit(orbit),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [OrbitTokens.flameRed, OrbitTokens.orange],
                ),
                borderRadius: BorderRadius.circular(OrbitTokens.radiusChip),
                boxShadow: [
                  BoxShadow(
                    color: OrbitTokens.flameRed.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Create Mix (${_selectedTrackIds.length} tracks)',
                style: OrbitTypography.chip.copyWith(
                  color: OrbitTokens.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: OrbitTokens.sectionGap),

          Text('Pick Tracks', style: OrbitTypography.h2),
          const SizedBox(height: OrbitTokens.space12),
          ValueListenableBuilder<List<OrbitTrack>>(
            valueListenable: orbit.catalogTracks,
            builder: (context, tracks, _) {
              return Column(
                children: List.generate(
                  tracks.take(12).length,
                  (i) {
                    final track = tracks[i];
                    final picked = _selectedTrackIds.contains(track.id);
                    return SpringEntrance(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassSurface(
                          radius: 12,
                          intensity: picked ? 0.95 : 0.55,
                          tint: picked ? OrbitTokens.orange : null,
                          onTap: () {
                            OrbitHaptics.selection();
                            setState(() {
                              if (picked) {
                                _selectedTrackIds.remove(track.id);
                              } else {
                                _selectedTrackIds.add(track.id);
                              }
                            });
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              AppImage(
                                id: track.id,
                                imageUrl: track.imageUrl,
                                seed: track.seed,
                                primaryColor: track.dominantColor,
                                secondaryColor: track.secondaryColor,
                                width: 44,
                                height: 44,
                                borderRadius: 6,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track.title,
                                      style: OrbitTypography.h3,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      track.artistName,
                                      style: OrbitTypography.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                picked
                                    ? Icons.check_circle_rounded
                                    : Icons.add_circle_outline_rounded,
                                color: picked
                                    ? OrbitTokens.orange
                                    : OrbitTokens.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
