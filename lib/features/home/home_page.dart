import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/orbit_state.dart';
import '../../core/springs.dart';
import '../../core/tokens.dart';
import '../../core/typography.dart';
import '../../data/mock.dart';
import '../../widgets/album_card.dart';
import '../../widgets/app_image.dart';
import '../../widgets/artist_card.dart';
import '../../widgets/dot_logo.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/liquid_backdrop.dart';
import '../../widgets/quick_tile.dart';
import '../../widgets/section_header.dart';
import '../detail/detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.dotSlotKey,
    this.entryProgress = 1.0,
    this.enableDotHero = true,
  });

  final GlobalKey dotSlotKey;
  final double entryProgress;
  final bool enableDotHero;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _dotBlink = 0.0;
  double _dotSquash = 0.0;
  Timer? _blinkTimer;

  void _pokeDot() {
    OrbitHaptics.light();
    setState(() {
      _dotBlink = 1.0;
      _dotSquash = 0.7;
    });
    _blinkTimer?.cancel();
    _blinkTimer = Timer(const Duration(milliseconds: 110), () {
      if (!mounted) return;
      setState(() {
        _dotBlink = 0.0;
        _dotSquash = 0.0;
      });
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  List<OrbitPlaylist> _filterPlaylists(
    List<OrbitPlaylist> source,
    int filterIndex,
  ) {
    if (filterIndex == 0) return source;
    final kind = switch (filterIndex) {
      1 => OrbitKind.music,
      2 => OrbitKind.podcasts,
      3 => OrbitKind.audiobooks,
      _ => OrbitKind.radio,
    };
    final filtered =
        source.where((p) => p.kind == kind).toList(growable: false);
    return filtered.isEmpty ? source : filtered;
  }

  void _openNotificationsSheet(OrbitController orbit) {
    OrbitHaptics.light();
    orbit.markNotificationsRead();
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
          padding: const EdgeInsets.all(OrbitTokens.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("What's New", style: OrbitTypography.h2),
                  const Spacer(),
                  Text(
                    'All caught up',
                    style: OrbitTypography.caption.copyWith(
                      color: OrbitTokens.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OrbitTokens.space16),
              ...OrbitMockData.notifications.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: OrbitTokens.space12),
                  child: Row(
                    children: [
                      AppImage(
                        id: item.id,
                        seed: item.seed,
                        primaryColor: item.dominantColor,
                        secondaryColor: item.secondaryColor,
                        width: 48,
                        height: 48,
                        borderRadius: OrbitTokens.radiusQuickTile,
                      ),
                      const SizedBox(width: OrbitTokens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: OrbitTypography.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.subtitle} • ${item.timeAgo}',
                              style: OrbitTypography.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSectionAll(String title, List<OrbitPlaylist> items) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SectionAllPage(title: title, playlists: items),
      ),
    );
  }

  Widget _staggered(int slotIndex, Widget child) {
    final t = widget.entryProgress;
    if (t >= 0.999) return child;
    final start = (slotIndex * 0.12).clamp(0.0, 0.72);
    final local = ((t - start) / (1.0 - start)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(local);
    return Opacity(
      opacity: eased,
      child: Transform.translate(
        offset: Offset(0, 18.0 * (1.0 - eased)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orbit = OrbitScope.of(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomReserve = OrbitTokens.navPillHeight +
        OrbitTokens.navBottomMargin +
        OrbitTokens.miniPlayerHeight +
        OrbitTokens.miniPlayerGap +
        OrbitTokens.space24 +
        safeBottom;

    return ValueListenableBuilder<OrbitTrack>(
      valueListenable: orbit.currentTrack,
      builder: (context, activeTrack, _) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth == 0) {
              orbit.setTabScrollOffset(0, notification.metrics.pixels);
            }
            return false;
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: safeTop + OrbitTokens.space8),
              ),

              // Top bar: 36 px DotLogo + Greeting + Glass notification bell
              SliverToBoxAdapter(
                child: _staggered(
                  0,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrbitTokens.screenPadding,
                    ),
                    child: SizedBox(
                      height: OrbitTokens.headerHeight,
                      child: Row(
                        children: [
                          Semantics(
                            button: true,
                            label: 'Orbit Dot mascot',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _pokeDot,
                              child: SizedBox(
                                width: OrbitTokens.minTouchTarget,
                                height: OrbitTokens.minTouchTarget,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    key: widget.dotSlotKey,
                                    width: 36,
                                    height: 36,
                                    child: widget.enableDotHero
                                        ? Hero(
                                            tag: 'orbit-dot-logo',
                                            child: DotLogo(
                                              size: 36,
                                              headphones: false,
                                              blink: _dotBlink,
                                              squash: _dotSquash,
                                            ),
                                          )
                                        : DotLogo(
                                            size: 36,
                                            headphones: false,
                                            blink: _dotBlink,
                                            squash: _dotSquash,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: OrbitTokens.space4),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good night,',
                                  style: OrbitTypography.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  OrbitMockData.userName,
                                  style: OrbitTypography.h3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: orbit.unreadNotifications,
                            builder: (context, unread, _) {
                              return GlassIconButton(
                                icon: Icons.notifications_none_rounded,
                                label: 'Notifications',
                                badge: unread,
                                onTap: () => _openNotificationsSheet(orbit),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Hero Headline: "Ready to Vibe?" with non-overlapping 0.5x parallax fade
              SliverToBoxAdapter(
                child: _staggered(
                  1,
                  AnimatedBuilder(
                    animation: orbit.scrollOffset,
                    builder: (context, child) {
                      final s = orbit.scrollOffset.value;
                      final parallaxY = s > 0
                          ? (s * 0.22).clamp(0.0, 18.0)
                          : (s * 0.15).clamp(-12.0, 0.0);
                      final fade = s > 0
                          ? (1.0 - (s / 190.0)).clamp(0.0, 1.0)
                          : 1.0;
                      return Opacity(
                        opacity: fade,
                        child: Transform.translate(
                          offset: Offset(0, parallaxY),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        OrbitTokens.screenPadding,
                        OrbitTokens.space12,
                        OrbitTokens.screenPadding,
                        OrbitTokens.space4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: 'Ready to ',
                              style: OrbitTypography.display,
                              children: [
                                TextSpan(
                                  text: 'Vibe?',
                                  style: OrbitTypography.display.copyWith(
                                    color: OrbitTokens.flame,
                                    shadows: [
                                      Shadow(
                                        color: OrbitTokens.flameRed
                                            .withValues(alpha: 0.55),
                                        blurRadius: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: OrbitTokens.space8),
                          Text(
                            'Explore playlists, artists, and new releases.',
                            style: OrbitTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.80),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: _staggered(
                  2,
                  Padding(
                    padding: const EdgeInsets.only(
                      top: OrbitTokens.space12,
                      bottom: OrbitTokens.space12,
                    ),
                    child: ValueListenableBuilder<int>(
                      valueListenable: orbit.selectedHomeFilter,
                      builder: (context, selectedIdx, _) {
                        return FilterChips(
                          labels: OrbitMockData.homeFilters,
                          selectedIndex: selectedIdx,
                          onSelected: (idx) =>
                              orbit.selectedHomeFilter.value = idx,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Content body
              ValueListenableBuilder<List<OrbitPlaylist>>(
                valueListenable: orbit.catalogPlaylists,
                builder: (context, _, _) {
                  return ValueListenableBuilder<List<OrbitPlaylist>>(
                    valueListenable: orbit.userPlaylists,
                    builder: (context, _, _) {
                      return ValueListenableBuilder<int>(
                        valueListenable: orbit.selectedHomeFilter,
                        builder: (context, filterIndex, _) {
                          final allPlaylists = orbit.allPlaylists;
                          final filtered =
                              _filterPlaylists(allPlaylists, filterIndex);
                          final quickItems = filtered.take(8).toList();
                          final madeForYou = filtered
                              .where((p) => p.section == 'Made for you')
                              .toList();
                          final recentlyPlayed = filtered
                              .where((p) => p.section == 'Recently played')
                              .toList();
                          final jumpBackIn = filtered
                              .where((p) => p.section == 'Jump back in')
                              .toList();
                          final newReleases = filtered
                              .where((p) => p.section == 'New releases')
                              .toList();

                          final madeList =
                              madeForYou.isNotEmpty ? madeForYou : filtered;
                          final recentList = recentlyPlayed.isNotEmpty
                              ? recentlyPlayed
                              : filtered.reversed.toList();
                          final jumpList =
                              jumpBackIn.isNotEmpty ? jumpBackIn : filtered;
                          final newList =
                              newReleases.isNotEmpty ? newReleases : filtered;

                          return SliverList(
                            delegate: SliverChildListDelegate([
                              // 2 x 4 Glass Quick-Access Grid
                              _staggered(
                                3,
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: OrbitTokens.screenPadding,
                                  ),
                                  child: _QuickGrid(
                                    playlists: quickItems,
                                    activeTrackId: activeTrack.id,
                                    onTap: (pl) => pushPlaylistDetail(
                                      context,
                                      pl,
                                      heroTagPrefix: 'quick',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: OrbitTokens.sectionGap),

                              // Section 1: Made for you
                              _staggered(
                                4,
                                _PlaylistCarouselSection(
                                  title: 'Made for you',
                                  playlists: madeList,
                                  heroPrefix: 'made',
                                  onShowAll: () =>
                                      _openSectionAll('Made for you', madeList),
                                ),
                              ),
                              const SizedBox(height: OrbitTokens.sectionGap),

                              // Section 2: Recently played
                              _staggered(
                                5,
                                _PlaylistCarouselSection(
                                  title: 'Recently played',
                                  playlists: recentList,
                                  heroPrefix: 'recent',
                                  onShowAll: () => _openSectionAll(
                                    'Recently played',
                                    recentList,
                                  ),
                                ),
                              ),
                              const SizedBox(height: OrbitTokens.sectionGap),

                              // Section 3: Jump back in
                              _PlaylistCarouselSection(
                                title: 'Jump back in',
                                playlists: jumpList,
                                heroPrefix: 'jump',
                                onShowAll: () =>
                                    _openSectionAll('Jump back in', jumpList),
                              ),
                              const SizedBox(height: OrbitTokens.sectionGap),

                              // Section 4: Popular artists
                              SectionHeader(
                                title: 'Popular artists',
                                onActionTap: () {
                                  orbit.selectTab(2);
                                  orbit.selectedLibraryFilter.value = 1;
                                },
                              ),
                              const SizedBox(height: OrbitTokens.space12),
                              ValueListenableBuilder<List<OrbitArtist>>(
                                valueListenable: orbit.catalogArtists,
                                builder: (context, artists, _) {
                                  final textScale = MediaQuery.textScalerOf(context)
                                      .scale(1.0);
                                  final carouselH = 132.0 + 12 + 8 + 16 + (42.0 * textScale);
                                  return SizedBox(
                                    height: carouselH,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: OrbitTokens.screenPadding,
                                      ),
                                      itemCount: artists.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(
                                        width: OrbitTokens.space12,
                                      ),
                                      itemBuilder: (context, i) {
                                        final artist = artists[i];
                                        return SpringEntrance(
                                          index: i,
                                          child: ArtistCard(
                                            artist: artist,
                                            onTap: () => pushArtistDetail(
                                              context,
                                              artist,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: OrbitTokens.sectionGap),

                              // Section 5: New releases
                              _PlaylistCarouselSection(
                                title: 'New releases',
                                playlists: newList,
                                heroPrefix: 'new',
                                onShowAll: () =>
                                    _openSectionAll('New releases', newList),
                              ),
                              SizedBox(height: bottomReserve),
                            ]),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({
    required this.playlists,
    required this.activeTrackId,
    required this.onTap,
  });

  final List<OrbitPlaylist> playlists;
  final String activeTrackId;
  final ValueChanged<OrbitPlaylist> onTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < playlists.length; i += 2) {
      final left = playlists[i];
      final right = i + 1 < playlists.length ? playlists[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SpringEntrance(
                  index: i,
                  child: QuickTile(
                    playlist: left,
                    isPlaying: left.trackIds.contains(activeTrackId),
                    onTap: () => onTap(left),
                  ),
                ),
              ),
              const SizedBox(width: OrbitTokens.space8),
              Expanded(
                child: right != null
                    ? SpringEntrance(
                        index: i + 1,
                        child: QuickTile(
                          playlist: right,
                          isPlaying: right.trackIds.contains(activeTrackId),
                          onTap: () => onTap(right),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < playlists.length) {
        rows.add(const SizedBox(height: OrbitTokens.space8));
      }
    }
    return Column(children: rows);
  }
}

class _PlaylistCarouselSection extends StatelessWidget {
  const _PlaylistCarouselSection({
    required this.title,
    required this.playlists,
    required this.heroPrefix,
    required this.onShowAll,
  });

  final String title;
  final List<OrbitPlaylist> playlists;
  final String heroPrefix;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    // Responsive height accounting for glass frame (12), gap (8), and scaled 3-line caption plate
    final cardHeight = 148.0 + 8.0 + (72.0 * textScale) + 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          onActionTap: onShowAll,
        ),
        const SizedBox(height: OrbitTokens.space12),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: OrbitTokens.screenPadding,
            ),
            itemCount: playlists.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: OrbitTokens.space12),
            itemBuilder: (context, i) {
              final playlist = playlists[i];
              return SpringEntrance(
                index: i,
                child: AlbumCard(
                  playlist: playlist,
                  heroTagPrefix: heroPrefix,
                  onTap: () => pushPlaylistDetail(
                    context,
                    playlist,
                    heroTagPrefix: heroPrefix,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionAllPage extends StatelessWidget {
  const _SectionAllPage({
    required this.title,
    required this.playlists,
  });

  final String title;
  final List<OrbitPlaylist> playlists;

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
            onTap: () => Navigator.of(context).maybePop(),
            buttonSize: 40,
          ),
        ),
        title: Text(title, style: OrbitTypography.h2),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final colWidth = (constraints.maxWidth -
                        OrbitTokens.screenPadding * 2 -
                        OrbitTokens.space12) /
                    2;
                final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                final tileExtent = colWidth + 8.0 + (74.0 * textScale) + 12.0;

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.depth == 0) {
                      orbit.setDetailScrollOffset(n.metrics.pixels);
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      OrbitTokens.screenPadding,
                      OrbitTokens.space12,
                      OrbitTokens.screenPadding,
                      bottomReserve,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: OrbitTokens.space12,
                      mainAxisSpacing: OrbitTokens.space16,
                      mainAxisExtent: math.max(tileExtent, colWidth + 86),
                    ),
                    itemCount: playlists.length,
                    itemBuilder: (context, i) {
                      final pl = playlists[i];
                      return SpringEntrance(
                        index: i,
                        child: AlbumCard(
                          playlist: pl,
                          width: colWidth,
                          heroTagPrefix: 'section_all',
                          onTap: () => pushPlaylistDetail(
                            context,
                            pl,
                            heroTagPrefix: 'section_all',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
