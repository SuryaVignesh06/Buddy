import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/orbit_state.dart';
import '../../core/springs.dart';
import '../../core/tokens.dart';
import '../../core/typography.dart';
import '../../data/mock.dart';
import '../../widgets/adaptive_header.dart';
import '../../widgets/app_image.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/like_button.dart';
import '../../widgets/play_button.dart';
import '../../widgets/track_row.dart';

/// Spring-driven Detail route: Hero art + content sliding up 32 px with [Springs.smooth].
Future<void> pushPlaylistDetail(
  BuildContext context,
  OrbitPlaylist playlist, {
  String heroTagPrefix = 'album',
}) {
  return Navigator.of(context).push(
    _SpringDetailRoute(
      builder: (_) => PlaylistDetailPage(
        playlist: playlist,
        heroTagPrefix: heroTagPrefix,
      ),
    ),
  );
}

Future<void> pushArtistDetail(BuildContext context, OrbitArtist artist) {
  return Navigator.of(context).push(
    _SpringDetailRoute(
      builder: (_) => ArtistDetailPage(artist: artist),
    ),
  );
}

class _SpringDetailRoute extends PageRouteBuilder<void> {
  _SpringDetailRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final dy = 32.0 * (1.0 - curved.value);
            return FadeTransition(
              opacity: curved,
              child: Transform.translate(
                offset: Offset(0, dy),
                child: child,
              ),
            );
          },
        );
}

/// Playlist / Album detail page with adaptive gradient, glass action buttons,
/// and swipeable track rows.
class PlaylistDetailPage extends StatelessWidget {
  const PlaylistDetailPage({
    super.key,
    required this.playlist,
    this.heroTagPrefix = 'album',
  });

  final OrbitPlaylist playlist;
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    final orbit = OrbitScope.of(context);
    final tracks = orbit.tracksForPlaylist(playlist);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomReserve = OrbitTokens.navPillHeight +
        OrbitTokens.navBottomMargin +
        OrbitTokens.miniPlayerHeight +
        OrbitTokens.miniPlayerGap +
        OrbitTokens.space24 +
        safeBottom;
    final heroTag = heroTagPrefix.isEmpty
        ? 'art-${playlist.id}'
        : '${heroTagPrefix}_art-${playlist.id}';

    return Scaffold(
      backgroundColor: OrbitTokens.black,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) {
            orbit.setDetailScrollOffset(notification.metrics.pixels);
          }
          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            AdaptiveHeader(
              title: playlist.title,
              id: playlist.id,
              imageUrl: playlist.imageUrl,
              dominantColor: playlist.dominantColor,
              secondaryColor: playlist.secondaryColor,
              artSeed: playlist.seed,
              heroTag: heroTag,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  OrbitTokens.screenPadding,
                  OrbitTokens.space12,
                  OrbitTokens.screenPadding,
                  OrbitTokens.space12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.title,
                      style: OrbitTypography.h1,
                    ),
                    const SizedBox(height: OrbitTokens.space8),
                    Text(
                      playlist.subtitle,
                      style: OrbitTypography.body.copyWith(
                        color: OrbitTokens.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: OrbitTokens.space12),
                    Row(
                      children: [
                        AppImage(
                          id: 'creator_${playlist.creator}',
                          seed: playlist.creator.hashCode,
                          primaryColor: OrbitTokens.orange,
                          secondaryColor: OrbitTokens.crimson,
                          width: 24,
                          height: 24,
                          circular: true,
                        ),
                        const SizedBox(width: OrbitTokens.space8),
                        Expanded(
                          child: Text(
                            '${playlist.creator} • ${playlist.year}',
                            style: OrbitTypography.bodyS.copyWith(
                              color: OrbitTokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrbitTokens.space4),
                    Text(
                      '${playlist.savesLabel} • ${playlist.durationLabel}',
                      style: OrbitTypography.caption,
                    ),
                    const SizedBox(height: OrbitTokens.space12),

                    // Glass Action Row (responsive for 320 px width)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 316;
                        final btnTouch = compact ? 40.0 : 48.0;
                        final btnVisual = compact ? 36.0 : 42.0;
                        final playSize = compact ? 54.0 : 62.0;

                        return Row(
                          children: [
                            ValueListenableBuilder<Set<String>>(
                              valueListenable: orbit.downloadedPlaylistIds,
                              builder: (context, downloaded, _) {
                                final isDown = downloaded.contains(playlist.id);
                                return GlassIconButton(
                                  buttonSize: btnVisual,
                                  touchSize: btnTouch,
                                  icon: isDown
                                      ? Icons.download_for_offline_rounded
                                      : Icons.download_for_offline_outlined,
                                  iconColor: isDown
                                      ? OrbitTokens.orange
                                      : OrbitTokens.textPrimary,
                                  tint: isDown ? OrbitTokens.orange : null,
                                  label: isDown ? 'Downloaded' : 'Download',
                                  onTap: () =>
                                      orbit.togglePlaylistDownloaded(playlist),
                                );
                              },
                            ),
                            ValueListenableBuilder<Set<String>>(
                              valueListenable: orbit.savedPlaylistIds,
                              builder: (context, saved, _) {
                                final isSaved = saved.contains(playlist.id);
                                return GlassSurface(
                                  width: btnVisual,
                                  height: btnVisual,
                                  circular: true,
                                  tint: isSaved ? OrbitTokens.flame : null,
                                  child: LikeButton(
                                    liked: isSaved,
                                    size: 20,
                                    touchSize: btnVisual,
                                    activeColor: OrbitTokens.flame,
                                    inactiveColor: OrbitTokens.textPrimary,
                                    label: isSaved
                                        ? 'Remove from library'
                                        : 'Save to library',
                                    onTap: () =>
                                        orbit.togglePlaylistSaved(playlist),
                                  ),
                                );
                              },
                            ),
                            GlassIconButton(
                              buttonSize: btnVisual,
                              touchSize: btnTouch,
                              icon: Icons.ios_share_rounded,
                              iconColor: OrbitTokens.textPrimary,
                              label: 'Share playlist',
                              onTap: () {
                                OrbitHaptics.light();
                                orbit.showToast(
                                  'Copied link for "${playlist.title}"',
                                );
                              },
                            ),
                            GlassIconButton(
                              buttonSize: btnVisual,
                              touchSize: btnTouch,
                              icon: Icons.more_horiz_rounded,
                              iconColor: OrbitTokens.textPrimary,
                              label: 'More actions',
                              onTap: () {
                                OrbitHaptics.light();
                                orbit.addPlaylistToQueue(playlist);
                              },
                            ),
                            const Spacer(),
                            ValueListenableBuilder<bool>(
                              valueListenable: orbit.isShuffled,
                              builder: (context, shuffled, _) {
                                return GlassIconButton(
                                  buttonSize: btnVisual,
                                  touchSize: btnTouch,
                                  icon: Icons.shuffle_rounded,
                                  iconColor: shuffled
                                      ? OrbitTokens.orange
                                      : OrbitTokens.textPrimary,
                                  tint: shuffled ? OrbitTokens.orange : null,
                                  label: 'Shuffle',
                                  onTap: orbit.toggleShuffle,
                                );
                              },
                            ),
                            const SizedBox(width: OrbitTokens.space4),
                            ValueListenableBuilder<bool>(
                              valueListenable: orbit.isPlaying,
                              builder: (context, playing, _) {
                                return ValueListenableBuilder<String>(
                                  valueListenable: orbit.currentSourceLabel,
                                  builder: (context, sourceLabel, _) {
                                    final isThisContext =
                                        sourceLabel == playlist.title;
                                    return PlayButton(
                                      isPlaying: isThisContext && playing,
                                      size: playSize,
                                      backgroundColor: OrbitTokens.accent,
                                      iconColor: OrbitTokens.bg,
                                      onPressed: () {
                                        if (isThisContext) {
                                          orbit.togglePlay();
                                        } else {
                                          orbit.playPlaylist(
                                            playlist,
                                            shuffle: orbit.isShuffled.value,
                                          );
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  OrbitTokens.screenPadding,
                  0,
                  OrbitTokens.screenPadding,
                  OrbitTokens.space8,
                ),
                child: Text(
                  'Swipe right to queue • Swipe left to like',
                  style: OrbitTypography.caption.copyWith(
                    color: OrbitTokens.textMuted,
                  ),
                ),
              ),
            ),

            SliverList.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return SpringEntrance(
                  index: index,
                  child: ValueListenableBuilder<OrbitTrack>(
                    valueListenable: orbit.currentTrack,
                    builder: (context, activeTrack, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: orbit.isPlaying,
                        builder: (context, playing, _) {
                          return ValueListenableBuilder<Set<String>>(
                            valueListenable: orbit.likedTrackIds,
                            builder: (context, likedIds, _) {
                              return TrackRow(
                                track: track,
                                index: index + 1,
                                isActive: activeTrack.id == track.id,
                                isPlaying: playing,
                                isLiked: likedIds.contains(track.id),
                                onTap: () => orbit.playTrack(
                                  track,
                                  sourceLabel: playlist.title,
                                  contextQueue: tracks,
                                ),
                                onQueue: () => orbit.addToQueue(track),
                                onToggleLike: () =>
                                    orbit.toggleTrackLike(track),
                                onMoreTap: () => _showTrackActionsSheet(
                                  context,
                                  orbit,
                                  track,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: bottomReserve),
            ),
          ],
        ),
      ),
    );
  }
}

/// Artist detail page reusing AdaptiveHeader and TrackRow components.
class ArtistDetailPage extends StatefulWidget {
  const ArtistDetailPage({
    super.key,
    required this.artist,
  });

  final OrbitArtist artist;

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  bool _following = true;

  @override
  Widget build(BuildContext context) {
    final orbit = OrbitScope.of(context);
    final tracks = orbit.tracksForArtist(widget.artist.id);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomReserve = OrbitTokens.navPillHeight +
        OrbitTokens.navBottomMargin +
        OrbitTokens.miniPlayerHeight +
        OrbitTokens.miniPlayerGap +
        OrbitTokens.space24 +
        safeBottom;

    return Scaffold(
      backgroundColor: OrbitTokens.black,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) {
            orbit.setDetailScrollOffset(notification.metrics.pixels);
          }
          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            AdaptiveHeader(
              title: widget.artist.name,
              id: widget.artist.id,
              imageUrl: widget.artist.imageUrl,
              dominantColor: widget.artist.dominantColor,
              secondaryColor: widget.artist.secondaryColor,
              artSeed: widget.artist.seed,
              heroTag: 'art-${widget.artist.id}',
              circularArt: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(OrbitTokens.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.artist.name, style: OrbitTypography.h1),
                    const SizedBox(height: OrbitTokens.space4),
                    Text(
                      '${widget.artist.monthlyListeners} • ${widget.artist.genre}',
                      style: OrbitTypography.bodyS,
                    ),
                    const SizedBox(height: OrbitTokens.space12),
                    Text(
                      widget.artist.bio,
                      style: OrbitTypography.body.copyWith(
                        color: OrbitTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: OrbitTokens.space16),
                    Row(
                      children: [
                        GlassSurface(
                          radius: OrbitTokens.radiusChip,
                          tint: _following ? null : OrbitTokens.flame,
                          intensity: _following ? 0.85 : 1.15,
                          onTap: () {
                            OrbitHaptics.selection();
                            setState(() => _following = !_following);
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          child: Text(
                            _following ? 'Following' : 'Follow',
                            style: OrbitTypography.chip.copyWith(
                              color: OrbitTokens.textPrimary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (tracks.isNotEmpty)
                          PlayButton(
                            isPlaying: false,
                            size: 56,
                            onPressed: () => orbit.playTrack(
                              tracks.first,
                              sourceLabel: widget.artist.name,
                              contextQueue: tracks,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: OrbitTokens.space24),
                    Text('Popular', style: OrbitTypography.h2),
                  ],
                ),
              ),
            ),
            SliverList.builder(
              itemCount: tracks.length,
              itemBuilder: (context, i) {
                final track = tracks[i];
                return SpringEntrance(
                  index: i,
                  child: ValueListenableBuilder<OrbitTrack>(
                    valueListenable: orbit.currentTrack,
                    builder: (context, activeTrack, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: orbit.isPlaying,
                        builder: (context, playing, _) {
                          return ValueListenableBuilder<Set<String>>(
                            valueListenable: orbit.likedTrackIds,
                            builder: (context, liked, _) {
                              return TrackRow(
                                track: track,
                                index: i + 1,
                                isActive: activeTrack.id == track.id,
                                isPlaying: playing,
                                isLiked: liked.contains(track.id),
                                onTap: () => orbit.playTrack(
                                  track,
                                  sourceLabel: widget.artist.name,
                                  contextQueue: tracks,
                                ),
                                onQueue: () => orbit.addToQueue(track),
                                onToggleLike: () =>
                                    orbit.toggleTrackLike(track),
                                onMoreTap: () => _showTrackActionsSheet(
                                  context,
                                  orbit,
                                  track,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: bottomReserve),
            ),
          ],
        ),
      ),
    );
  }
}

void _showTrackActionsSheet(
  BuildContext context,
  OrbitController orbit,
  OrbitTrack track,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: OrbitTokens.surface1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(OrbitTokens.radiusSheet),
      ),
    ),
    builder: (ctx) {
      final isLiked = orbit.isTrackLiked(track.id);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OrbitTokens.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AppImage(
                    id: track.id,
                    imageUrl: track.imageUrl,
                    seed: track.seed,
                    primaryColor: track.dominantColor,
                    secondaryColor: track.secondaryColor,
                    width: 48,
                    height: 48,
                    borderRadius: OrbitTokens.radiusQuickTile,
                  ),
                  const SizedBox(width: OrbitTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title, style: OrbitTypography.h3),
                        Text(track.artistName, style: OrbitTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OrbitTokens.space16),
              ListTile(
                leading: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isLiked ? OrbitTokens.flame : OrbitTokens.textPrimary,
                ),
                title: Text(
                  isLiked ? 'Remove from Liked Songs' : 'Save to Liked Songs',
                  style: OrbitTypography.body,
                ),
                onTap: () {
                  orbit.toggleTrackLike(track);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.queue_music_rounded,
                  color: OrbitTokens.textPrimary,
                ),
                title: Text('Add to queue', style: OrbitTypography.body),
                onTap: () {
                  orbit.addToQueue(track);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_outline_rounded,
                  color: OrbitTokens.textPrimary,
                ),
                title: Text('View artist', style: OrbitTypography.body),
                onTap: () {
                  Navigator.pop(ctx);
                  pushArtistDetail(
                    context,
                    orbit.artistById(track.artistId),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
