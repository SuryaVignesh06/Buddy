import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/orbit_state.dart';
import '../../core/springs.dart';
import '../../core/tokens.dart';
import '../../core/typography.dart';
import '../../data/art_repository.dart';
import '../../data/mock.dart';
import '../../widgets/app_image.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/dot_logo.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/liquid_backdrop.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/track_row.dart';
import '../detail/detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _searchMode = false;
  bool _loadingSkeleton = false;
  Timer? _debounce;
  late List<String> _recent;
  List<OrbitPlaylist> _remoteAlbums = const [];

  @override
  void initState() {
    super.initState();
    _recent = List<String>.from(OrbitMockData.recentSearches);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _enterSearchMode() {
    setState(() => _searchMode = true);
    _focusNode.requestFocus();
  }

  void _exitSearchMode() {
    _debounce?.cancel();
    _queryController.clear();
    _focusNode.unfocus();
    setState(() {
      _searchMode = false;
      _loadingSkeleton = false;
      _remoteAlbums = const [];
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _loadingSkeleton = false;
        _remoteAlbums = const [];
      });
      return;
    }
    setState(() => _loadingSkeleton = true);
    _debounce = Timer(const Duration(milliseconds: 240), () async {
      if (!mounted) return;
      setState(() => _loadingSkeleton = false);
      final hits = await ArtRepository.instance.search(trimmed, limit: 8);
      if (!mounted || _queryController.text.trim() != trimmed) return;
      setState(() => _remoteAlbums = hits);
    });
  }

  void _openCameraMatchModal(OrbitController orbit) {
    OrbitHaptics.medium();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: OrbitTokens.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OrbitTokens.radiusSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OrbitTokens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DotLogo(size: 64, headphones: true, beatPulse: 0.7),
              const SizedBox(height: OrbitTokens.space16),
              Text('Orbit Lens Scan', style: OrbitTypography.h2),
              const SizedBox(height: OrbitTokens.space8),
              Text(
                'Point at any Orbit vinyl wave code or album cover to jump straight into playback.',
                style: OrbitTypography.body.copyWith(
                  color: OrbitTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: OrbitTokens.space20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OrbitTokens.accent,
                    foregroundColor: OrbitTokens.bg,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(OrbitTokens.radiusChip),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    orbit.playPlaylist(orbit.catalogPlaylists.value.first);
                    orbit.showToast(
                      'Matched "${orbit.catalogPlaylists.value.first.title}" via Orbit Lens',
                    );
                  },
                  child: Text(
                    'Simulate Sample Match',
                    style: OrbitTypography.chip.copyWith(color: OrbitTokens.bg),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategory(OrbitCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CategoryResultsPage(category: category),
      ),
    );
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

    if (_searchMode) {
      return _buildExpandedSearch(orbit, safeTop, bottomReserve);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) {
          orbit.setTabScrollOffset(1, notification.metrics.pixels);
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: safeTop + OrbitTokens.space12),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: OrbitTokens.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: OrbitTokens.headerHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Search', style: OrbitTypography.h1),
                    ),
                  ),
                  const SizedBox(height: OrbitTokens.space8),
                  // Tier B glass search field
                  Semantics(
                    textField: true,
                    label: 'What do you want to play?',
                    child: GlassSurface(
                      radius: 14,
                      intensity: 1.05,
                      onTap: _enterSearchMode,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrbitTokens.space12,
                      ),
                      height: 50,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: OrbitTokens.textPrimary,
                            size: 22,
                          ),
                          const SizedBox(width: OrbitTokens.space12),
                          Expanded(
                            child: Text(
                              'What do you want to play?',
                              style: OrbitTypography.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'Orbit Lens camera search',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _openCameraMatchModal(orbit),
                              child: const SizedBox(
                                width: OrbitTokens.minTouchTarget,
                                height: OrbitTokens.minTouchTarget,
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color: OrbitTokens.textPrimary,
                                  size: 21,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: OrbitTokens.sectionGap),
                  Text('Browse all', style: OrbitTypography.h2),
                  const SizedBox(height: OrbitTokens.space12),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<List<OrbitCategory>>(
            valueListenable: orbit.catalogCategories,
            builder: (context, categories, _) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OrbitTokens.screenPadding,
                ),
                sliver: SliverGrid.builder(
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: OrbitTokens.space12,
                    crossAxisSpacing: OrbitTokens.space12,
                    mainAxisExtent: 100,
                  ),
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    return SpringEntrance(
                      index: i,
                      child: CategoryTile(
                        category: cat,
                        onTap: () => _openCategory(cat),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottomReserve)),
        ],
      ),
    );
  }

  Widget _buildExpandedSearch(
    OrbitController orbit,
    double safeTop,
    double bottomReserve,
  ) {
    final q = _queryController.text.trim().toLowerCase();
    final matchedTracks = q.isEmpty
        ? const <OrbitTrack>[]
        : orbit.catalogTracks.value
            .where(
              (t) =>
                  t.title.toLowerCase().contains(q) ||
                  t.artistName.toLowerCase().contains(q) ||
                  t.albumTitle.toLowerCase().contains(q),
            )
            .toList();
    final localPlaylists = q.isEmpty
        ? const <OrbitPlaylist>[]
        : orbit.allPlaylists
            .where(
              (p) =>
                  p.title.toLowerCase().contains(q) ||
                  p.subtitle.toLowerCase().contains(q),
            )
            .toList();
    final matchedPlaylists = <OrbitPlaylist>[
      ...localPlaylists,
      ..._remoteAlbums.where(
        (r) => !localPlaylists.any((l) => l.title == r.title),
      ),
    ];
    final matchedArtists = q.isEmpty
        ? const <OrbitArtist>[]
        : orbit.catalogArtists.value
            .where(
              (a) =>
                  a.name.toLowerCase().contains(q) ||
                  a.genre.toLowerCase().contains(q),
            )
            .toList();

    return Column(
      children: [
        SizedBox(height: safeTop + OrbitTokens.space8),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OrbitTokens.screenPadding,
          ),
          child: Row(
            children: [
              GlassIconButton(
                icon: Icons.arrow_back_rounded,
                label: 'Close search',
                onTap: _exitSearchMode,
                buttonSize: 40,
              ),
              const SizedBox(width: OrbitTokens.space4),
              Expanded(
                child: GlassSurface(
                  radius: 14,
                  height: 48,
                  enableHoverLift: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: OrbitTokens.space12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: OrbitTokens.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: OrbitTokens.space8),
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          focusNode: _focusNode,
                          onChanged: _onQueryChanged,
                          style: OrbitTypography.body,
                          cursorColor: OrbitTokens.orange,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Artists, songs, or playlists',
                            hintStyle: OrbitTypography.body.copyWith(
                              color: OrbitTokens.textMuted,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (q.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _queryController.clear();
                            _onQueryChanged('');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: OrbitTokens.textSecondary,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: OrbitTokens.space12),
        Expanded(
          child: _loadingSkeleton
              ? ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    OrbitTokens.screenPadding,
                    0,
                    OrbitTokens.screenPadding,
                    bottomReserve,
                  ),
                  itemCount: 6,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: OrbitTokens.space12),
                  itemBuilder: (_, _) => const Row(
                    children: [
                      SkeletonBox(width: 48, height: 48, borderRadius: 6),
                      SizedBox(width: OrbitTokens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(
                              width: 180,
                              height: 16,
                              borderRadius: 4,
                            ),
                            SizedBox(height: 6),
                            SkeletonBox(
                              width: 110,
                              height: 12,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : q.isEmpty
                  ? _buildRecentSearches(bottomReserve)
                  : (matchedTracks.isEmpty &&
                          matchedPlaylists.isEmpty &&
                          matchedArtists.isEmpty)
                      ? _EmptySearchState(
                          query: _queryController.text,
                          onClear: () {
                            _queryController.clear();
                            _onQueryChanged('');
                          },
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.depth == 0) {
                              orbit.setTabScrollOffset(
                                1,
                                notification.metrics.pixels,
                              );
                            }
                            return false;
                          },
                          child: ListView(
                            padding: EdgeInsets.only(bottom: bottomReserve),
                            children: [
                              if (matchedArtists.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: OrbitTokens.screenPadding,
                                    vertical: OrbitTokens.space8,
                                  ),
                                  child: Text('Artists', style: OrbitTypography.h3),
                                ),
                                ...matchedArtists.map(
                                  (artist) => ListTile(
                                    leading: AppImage(
                                      id: artist.id,
                                      imageUrl: artist.imageUrl,
                                      seed: artist.seed,
                                      primaryColor: artist.dominantColor,
                                      secondaryColor: artist.secondaryColor,
                                      width: 48,
                                      height: 48,
                                      circular: true,
                                    ),
                                    title: Text(
                                      artist.name,
                                      style: OrbitTypography.h3,
                                    ),
                                    subtitle: Text(
                                      'Artist • ${artist.genre}',
                                      style: OrbitTypography.caption,
                                    ),
                                    onTap: () =>
                                        pushArtistDetail(context, artist),
                                  ),
                                ),
                              ],
                              if (matchedPlaylists.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: OrbitTokens.screenPadding,
                                    vertical: OrbitTokens.space8,
                                  ),
                                  child: Text(
                                    'Playlists & Albums',
                                    style: OrbitTypography.h3,
                                  ),
                                ),
                                ...matchedPlaylists.map(
                                  (pl) => ListTile(
                                    leading: AppImage(
                                      id: pl.id,
                                      imageUrl: pl.imageUrl,
                                      seed: pl.seed,
                                      primaryColor: pl.dominantColor,
                                      secondaryColor: pl.secondaryColor,
                                      width: 48,
                                      height: 48,
                                      borderRadius: 6,
                                    ),
                                    title: Text(
                                      pl.title,
                                      style: OrbitTypography.h3,
                                    ),
                                    subtitle: Text(
                                      pl.subtitle,
                                      style: OrbitTypography.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => pushPlaylistDetail(
                                      context,
                                      pl,
                                      heroTagPrefix: 'search',
                                    ),
                                  ),
                                ),
                              ],
                              if (matchedTracks.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: OrbitTokens.screenPadding,
                                    vertical: OrbitTokens.space8,
                                  ),
                                  child: Text('Songs', style: OrbitTypography.h3),
                                ),
                                ...matchedTracks.map(
                                  (track) => ValueListenableBuilder<OrbitTrack>(
                                    valueListenable: orbit.currentTrack,
                                    builder: (context, active, _) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable: orbit.isPlaying,
                                        builder: (context, playing, _) {
                                          return ValueListenableBuilder<
                                              Set<String>>(
                                            valueListenable:
                                                orbit.likedTrackIds,
                                            builder: (context, liked, _) {
                                              return TrackRow(
                                                track: track,
                                                isActive: active.id == track.id,
                                                isPlaying: playing,
                                                isLiked:
                                                    liked.contains(track.id),
                                                onTap: () => orbit.playTrack(
                                                  track,
                                                  sourceLabel: 'Search',
                                                ),
                                                onQueue: () =>
                                                    orbit.addToQueue(track),
                                                onToggleLike: () => orbit
                                                    .toggleTrackLike(track),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches(double bottomReserve) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        OrbitTokens.screenPadding,
        OrbitTokens.space8,
        OrbitTokens.screenPadding,
        bottomReserve,
      ),
      children: [
        Text('Recent searches', style: OrbitTypography.h3),
        const SizedBox(height: OrbitTokens.space12),
        if (_recent.isEmpty)
          Text(
            'Your recent searches will appear here.',
            style: OrbitTypography.bodyS,
          )
        else
          ..._recent.map(
            (term) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.history_rounded,
                color: OrbitTokens.textSecondary,
              ),
              title: Text(term, style: OrbitTypography.body),
              trailing: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: OrbitTokens.textMuted,
                ),
                onPressed: () {
                  setState(() => _recent.remove(term));
                },
              ),
              onTap: () {
                _queryController.text = term;
                _onQueryChanged(term);
              },
            ),
          ),
      ],
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OrbitTokens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DotLogo(size: 72, headphones: true, eyeLook: 0.4),
            const SizedBox(height: OrbitTokens.space16),
            Text(
              'No results for "$query"',
              style: OrbitTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OrbitTokens.space8),
            Text(
              'Try searching by artist, mood, or synth vibe.',
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
              onPressed: onClear,
              child: Text(
                'Clear search',
                style: OrbitTypography.chip.copyWith(color: OrbitTokens.bg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryResultsPage extends StatelessWidget {
  const _CategoryResultsPage({required this.category});

  final OrbitCategory category;

  @override
  Widget build(BuildContext context) {
    final orbit = OrbitScope.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomReserve = OrbitTokens.navPillHeight +
        OrbitTokens.navBottomMargin +
        OrbitTokens.miniPlayerHeight +
        OrbitTokens.miniPlayerGap +
        OrbitTokens.space24 +
        safeBottom;
    final playlists = orbit.allPlaylists
        .where(
          (p) =>
              (p.seed + category.artSeed) % 2 == 0 ||
              p.title.toLowerCase().contains(
                    category.title.split(' ').first.toLowerCase(),
                  ),
        )
        .take(8)
        .toList();

    return Scaffold(
      backgroundColor: OrbitTokens.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: OrbitTokens.space8),
          child: GlassIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Back',
            onTap: () => Navigator.pop(context),
            buttonSize: 40,
          ),
        ),
        title: Text(category.title, style: OrbitTypography.h2),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LiquidBackdrop(
              scrollOffset: orbit.scrollOffset,
              isPlaying: orbit.isPlaying,
              trackHue: orbit.activeArtColor,
            ),
          ),
          SafeArea(
            bottom: false,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.depth == 0) {
                  orbit.setDetailScrollOffset(n.metrics.pixels);
                }
                return false;
              },
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  OrbitTokens.screenPadding,
                  OrbitTokens.space12,
                  OrbitTokens.screenPadding,
                  bottomReserve,
                ),
                itemCount: playlists.length,
                itemBuilder: (context, i) {
                  final pl = playlists[i];
                  return SpringEntrance(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: OrbitTokens.space8),
                      child: GlassSurface(
                        radius: 12,
                        intensity: 0.72,
                        onTap: () => pushPlaylistDetail(
                          context,
                          pl,
                          heroTagPrefix: 'cat_${category.id}',
                        ),
                        padding: const EdgeInsets.all(OrbitTokens.space8),
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
                              heroTag: 'cat_${category.id}_art-${pl.id}',
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
                                  Text(
                                    pl.subtitle,
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
