import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/orbit_state.dart';
import '../../core/springs.dart';
import '../../core/tokens.dart';
import '../../core/typography.dart';
import '../../data/mock.dart';
import '../../widgets/app_image.dart';
import '../../widgets/dot_logo.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/pressable_scale.dart';
import '../detail/detail_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const List<String> _sortLabels = [
    'Recents',
    'Recently Added',
    'Alphabetical',
  ];

  bool _searchVisible = false;
  final TextEditingController _filterController = TextEditingController();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
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

    return Column(
      children: [
        SizedBox(height: safeTop + OrbitTokens.space8),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OrbitTokens.screenPadding,
          ),
          child: SizedBox(
            height: OrbitTokens.headerHeight,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: OrbitTokens.accentGradient,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    OrbitMockData.userName.substring(0, 1),
                    style: OrbitTypography.h3.copyWith(color: OrbitTokens.bg),
                  ),
                ),
                const SizedBox(width: OrbitTokens.space12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Library',
                        style: OrbitTypography.h1,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                GlassIconButton(
                  icon: Icons.search_rounded,
                  label: 'Search in library',
                  buttonSize: 40,
                  onTap: () {
                    OrbitHaptics.selection();
                    setState(() {
                      _searchVisible = !_searchVisible;
                      if (!_searchVisible) _filterController.clear();
                    });
                  },
                ),
                GlassIconButton(
                  icon: Icons.add_rounded,
                  label: 'Create new playlist',
                  buttonSize: 40,
                  iconSize: 24,
                  onTap: () {
                    OrbitHaptics.selection();
                    orbit.selectTab(3);
                  },
                ),
              ],
            ),
          ),
        ),
        if (_searchVisible)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OrbitTokens.screenPadding,
              OrbitTokens.space4,
              OrbitTokens.screenPadding,
              OrbitTokens.space8,
            ),
            child: GlassSurface(
              radius: 12,
              height: 44,
              enableHoverLift: false,
              padding: const EdgeInsets.symmetric(
                horizontal: OrbitTokens.space12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: OrbitTokens.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: OrbitTokens.space8),
                  Expanded(
                    child: TextField(
                      controller: _filterController,
                      onChanged: (_) => setState(() {}),
                      style: OrbitTypography.body,
                      cursorColor: OrbitTokens.orange,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Filter Your Library',
                        hintStyle: OrbitTypography.body.copyWith(
                          color: OrbitTokens.textMuted,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_filterController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _filterController.clear();
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: OrbitTokens.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Filter chips: Playlists, Artists, Albums, Podcasts
        ValueListenableBuilder<int>(
          valueListenable: orbit.selectedLibraryFilter,
          builder: (context, selectedIdx, _) {
            return FilterChips(
              labels: OrbitMockData.libraryFilters,
              selectedIndex: selectedIdx,
              onSelected: (idx) => orbit.selectedLibraryFilter.value = idx,
            );
          },
        ),

        // Glass sort row + Grid/List toggle
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OrbitTokens.screenPadding,
            vertical: 2,
          ),
          child: Row(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: orbit.librarySortMode,
                builder: (context, sortIdx, _) {
                  return Semantics(
                    button: true,
                    label: 'Sort library: ${_sortLabels[sortIdx]}',
                    child: GlassSurface(
                      radius: OrbitTokens.radiusChip,
                      intensity: 0.72,
                      onTap: () {
                        OrbitHaptics.selection();
                        orbit.librarySortMode.value =
                            (sortIdx + 1) % _sortLabels.length;
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.swap_vert_rounded,
                            size: 16,
                            color: OrbitTokens.orange,
                          ),
                          const SizedBox(width: OrbitTokens.space8),
                          Text(
                            _sortLabels[sortIdx],
                            style: OrbitTypography.bodyS.copyWith(
                              color: OrbitTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              ValueListenableBuilder<bool>(
                valueListenable: orbit.libraryGridMode,
                builder: (context, gridMode, _) {
                  return GlassIconButton(
                    icon: gridMode
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    label: gridMode
                        ? 'Switch to list view'
                        : 'Switch to grid view',
                    buttonSize: 40,
                    iconSize: 20,
                    onTap: () {
                      OrbitHaptics.selection();
                      orbit.libraryGridMode.value = !gridMode;
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // Library items list or 3-col grid
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.depth == 0) {
                orbit.setTabScrollOffset(2, notification.metrics.pixels);
              }
              return false;
            },
            child: ValueListenableBuilder<int>(
              valueListenable: orbit.selectedLibraryFilter,
              builder: (context, filterIdx, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: orbit.librarySortMode,
                  builder: (context, sortIdx, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: orbit.libraryGridMode,
                      builder: (context, gridMode, _) {
                        return ValueListenableBuilder<List<OrbitPlaylist>>(
                          valueListenable: orbit.catalogPlaylists,
                          builder: (context, _, _) {
                            return ValueListenableBuilder<List<OrbitPlaylist>>(
                              valueListenable: orbit.userPlaylists,
                              builder: (context, _, _) {
                                return ValueListenableBuilder<Set<String>>(
                                  valueListenable: orbit.savedPlaylistIds,
                                  builder: (context, savedIds, _) {
                                    final q = _filterController.text
                                        .trim()
                                        .toLowerCase();

                                    if (filterIdx == 1) {
                                      final artists = orbit.catalogArtists.value
                                          .where(
                                            (a) =>
                                                q.isEmpty ||
                                                a.name
                                                    .toLowerCase()
                                                    .contains(q),
                                          )
                                          .toList();
                                      if (sortIdx == 2) {
                                        artists.sort(
                                          (a, b) => a.name.compareTo(b.name),
                                        );
                                      }
                                      if (artists.isEmpty) {
                                        return _LibraryEmptyState(
                                          onReset: () {
                                            _filterController.clear();
                                            setState(() {});
                                          },
                                        );
                                      }
                                      return gridMode
                                          ? _buildArtistGrid(
                                              artists,
                                              bottomReserve,
                                            )
                                          : _buildArtistList(
                                              artists,
                                              bottomReserve,
                                            );
                                    }

                                    final targetType = switch (filterIdx) {
                                      2 => LibraryItemType.album,
                                      3 => LibraryItemType.podcast,
                                      _ => LibraryItemType.playlist,
                                    };

                                    final items = orbit.allPlaylists.where((pl) {
                                      final matchesType = filterIdx == 0
                                          ? (pl.libraryType ==
                                                  LibraryItemType.playlist ||
                                              savedIds.contains(pl.id))
                                          : pl.libraryType == targetType;
                                      final matchesQuery = q.isEmpty ||
                                          pl.title.toLowerCase().contains(q) ||
                                          pl.creator.toLowerCase().contains(q);
                                      return matchesType && matchesQuery;
                                    }).toList();

                                    if (sortIdx == 2) {
                                      items.sort(
                                        (a, b) => a.title.compareTo(b.title),
                                      );
                                    } else if (sortIdx == 0) {
                                      items.sort((a, b) {
                                        if (a.pinned == b.pinned) return 0;
                                        return a.pinned ? -1 : 1;
                                      });
                                    }

                                    if (items.isEmpty) {
                                      return _LibraryEmptyState(
                                        onReset: () {
                                          _filterController.clear();
                                          setState(() {});
                                        },
                                      );
                                    }

                                    return gridMode
                                        ? _buildPlaylistGrid(
                                            items,
                                            bottomReserve,
                                          )
                                        : _buildPlaylistList(
                                            items,
                                            bottomReserve,
                                          );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistList(List<OrbitPlaylist> items, double bottomReserve) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        OrbitTokens.screenPadding,
        OrbitTokens.space4,
        OrbitTokens.screenPadding,
        bottomReserve,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final pl = items[i];
        final typeLabel = switch (pl.libraryType) {
          LibraryItemType.album => 'Album',
          LibraryItemType.podcast => 'Podcast',
          LibraryItemType.artist => 'Artist',
          LibraryItemType.playlist => 'Playlist',
        };
        return SpringEntrance(
          index: i,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: OrbitPressable(
              onTap: () => pushPlaylistDetail(
                context,
                pl,
                heroTagPrefix: 'lib',
              ),
              semanticLabel: '${pl.title}, $typeLabel by ${pl.creator}',
              child: GlassSurface(
                radius: 12,
                intensity: 0.65,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    AppImage(
                      id: pl.id,
                      imageUrl: pl.imageUrl,
                      seed: pl.seed,
                      primaryColor: pl.dominantColor,
                      secondaryColor: pl.secondaryColor,
                      width: 56,
                      height: 56,
                      borderRadius: 6,
                      heroTag: 'lib_art-${pl.id}',
                    ),
                    const SizedBox(width: OrbitTokens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pl.title,
                            style: OrbitTypography.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (pl.pinned) ...[
                                Transform.rotate(
                                  angle: 0.45,
                                  child: const Icon(
                                    Icons.push_pin_rounded,
                                    size: 13,
                                    color: OrbitTokens.orange,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  '$typeLabel • ${pl.creator}',
                                  style: OrbitTypography.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistGrid(List<OrbitPlaylist> items, double bottomReserve) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth =
            (constraints.maxWidth - OrbitTokens.screenPadding * 2 - OrbitTokens.space12 * 2) /
                3;
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final extent = colWidth + 10.0 + (46.0 * textScale) + 14.0;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            OrbitTokens.screenPadding,
            OrbitTokens.space8,
            OrbitTokens.screenPadding,
            bottomReserve,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: OrbitTokens.space12,
            mainAxisSpacing: OrbitTokens.space16,
            mainAxisExtent: math.max(extent, colWidth + 56),
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final pl = items[i];
            final artSize = (colWidth - 8).clamp(40.0, colWidth);
            return SpringEntrance(
              index: i,
              child: OrbitPressable(
                onTap: () => pushPlaylistDetail(
                  context,
                  pl,
                  heroTagPrefix: 'lib',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassSurface(
                      radius: 10,
                      padding: const EdgeInsets.all(4),
                      tint: pl.dominantColor,
                      child: AppImage(
                        id: pl.id,
                        imageUrl: pl.imageUrl,
                        seed: pl.seed,
                        primaryColor: pl.dominantColor,
                        secondaryColor: pl.secondaryColor,
                        width: artSize,
                        height: artSize,
                        borderRadius: 6,
                        heroTag: 'lib_art-${pl.id}',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pl.title,
                      style: OrbitTypography.bodyS.copyWith(
                        color: OrbitTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      pl.creator,
                      style: OrbitTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArtistList(List<OrbitArtist> artists, double bottomReserve) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        OrbitTokens.screenPadding,
        OrbitTokens.space4,
        OrbitTokens.screenPadding,
        bottomReserve,
      ),
      itemCount: artists.length,
      itemBuilder: (context, i) {
        final artist = artists[i];
        return SpringEntrance(
          index: i,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: OrbitPressable(
              onTap: () => pushArtistDetail(context, artist),
              child: GlassSurface(
                radius: 12,
                intensity: 0.65,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    AppImage(
                      id: artist.id,
                      imageUrl: artist.imageUrl,
                      seed: artist.seed,
                      primaryColor: artist.dominantColor,
                      secondaryColor: artist.secondaryColor,
                      width: 56,
                      height: 56,
                      circular: true,
                      heroTag: 'lib_artist_art-${artist.id}',
                    ),
                    const SizedBox(width: OrbitTokens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artist.name,
                            style: OrbitTypography.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Artist • ${artist.genre}',
                            style: OrbitTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistGrid(List<OrbitArtist> artists, double bottomReserve) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth =
            (constraints.maxWidth - OrbitTokens.screenPadding * 2 - OrbitTokens.space12 * 2) /
                3;
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final extent = colWidth + 10.0 + (28.0 * textScale) + 12.0;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            OrbitTokens.screenPadding,
            OrbitTokens.space8,
            OrbitTokens.screenPadding,
            bottomReserve,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: OrbitTokens.space12,
            mainAxisSpacing: OrbitTokens.space16,
            mainAxisExtent: math.max(extent, colWidth + 40),
          ),
          itemCount: artists.length,
          itemBuilder: (context, i) {
            final artist = artists[i];
            final artSize = (colWidth - 8).clamp(40.0, colWidth);
            return SpringEntrance(
              index: i,
              child: OrbitPressable(
                onTap: () => pushArtistDetail(context, artist),
                child: Column(
                  children: [
                    GlassSurface(
                      circular: true,
                      padding: const EdgeInsets.all(4),
                      tint: artist.dominantColor,
                      child: AppImage(
                        id: artist.id,
                        imageUrl: artist.imageUrl,
                        seed: artist.seed,
                        primaryColor: artist.dominantColor,
                        secondaryColor: artist.secondaryColor,
                        width: artSize,
                        height: artSize,
                        circular: true,
                        heroTag: 'lib_artist_art-${artist.id}',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      artist.name,
                      style: OrbitTypography.bodyS.copyWith(
                        color: OrbitTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OrbitTokens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DotLogo(size: 72, headphones: true, eyeLook: -0.3),
            const SizedBox(height: OrbitTokens.space16),
            Text(
              'Nothing matches in Your Library',
              style: OrbitTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OrbitTokens.space8),
            Text(
              'Clear your filter or create a fresh Orbit mix.',
              style: OrbitTypography.bodyS,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OrbitTokens.space16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: OrbitTokens.accent,
                foregroundColor: OrbitTokens.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(OrbitTokens.radiusChip),
                ),
              ),
              onPressed: onReset,
              child: Text(
                'Reset filter',
                style: OrbitTypography.chip.copyWith(color: OrbitTokens.bg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
