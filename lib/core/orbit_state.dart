import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/art_repository.dart';
import '../data/dominant_color.dart';
import '../data/mock.dart';
import 'haptics.dart';

/// Central lightweight state holder built with ValueNotifiers & InheritedNotifier.
class OrbitController extends ChangeNotifier {
  OrbitController({
    bool enableTicker = true,
    bool enableNetworkArt = true,
  })  : _enableTicker = enableTicker,
        _enableNetworkArt = enableNetworkArt {
    final initialTracks = _enableNetworkArt
        ? OrbitMockData.tracks
            .map((t) => t.copyWith(imageUrl: ArtRepository.picsumUrl(t.id)))
            .toList(growable: false)
        : OrbitMockData.tracks;
    final initialPlaylists = _enableNetworkArt
        ? OrbitMockData.playlists
            .map((p) => p.copyWith(imageUrl: ArtRepository.picsumUrl(p.id)))
            .toList(growable: false)
        : OrbitMockData.playlists;
    final initialArtists = _enableNetworkArt
        ? OrbitMockData.artists
            .map((a) => a.copyWith(imageUrl: ArtRepository.picsumUrl(a.id)))
            .toList(growable: false)
        : OrbitMockData.artists;
    final initialCategories = _enableNetworkArt
        ? OrbitMockData.categories
            .map((c) => c.copyWith(imageUrl: ArtRepository.picsumUrl(c.id)))
            .toList(growable: false)
        : OrbitMockData.categories;

    catalogTracks = ValueNotifier<List<OrbitTrack>>(initialTracks);
    catalogPlaylists = ValueNotifier<List<OrbitPlaylist>>(initialPlaylists);
    catalogArtists = ValueNotifier<List<OrbitArtist>>(initialArtists);
    catalogCategories = ValueNotifier<List<OrbitCategory>>(initialCategories);

    currentTrack = ValueNotifier<OrbitTrack>(initialTracks.first);
    activeArtColor = ValueNotifier<Color>(initialTracks.first.dominantColor);
    currentSourceLabel = ValueNotifier<String>(initialPlaylists.first.title);
    isPlaying = ValueNotifier<bool>(true);
    progress = ValueNotifier<double>(0.34);
    isShuffled = ValueNotifier<bool>(false);
    repeatMode = ValueNotifier<int>(0); // 0: off, 1: all, 2: one
    currentTab = ValueNotifier<int>(0);
    selectedHomeFilter = ValueNotifier<int>(0);
    selectedLibraryFilter = ValueNotifier<int>(0);
    libraryGridMode = ValueNotifier<bool>(false);
    librarySortMode = ValueNotifier<int>(0);
    likedTrackIds = ValueNotifier<Set<String>>({'trk_01', 'trk_03', 'trk_07'});
    savedPlaylistIds = ValueNotifier<Set<String>>({
      'pl_01',
      'pl_02',
      'pl_03',
      'pl_06',
      'pl_07',
      'pl_08',
      'pl_13',
    });
    downloadedPlaylistIds = ValueNotifier<Set<String>>({'pl_01', 'pl_06'});
    userPlaylists = ValueNotifier<List<OrbitPlaylist>>(const []);
    queue = ValueNotifier<List<OrbitTrack>>(initialTracks.sublist(1, 7));
    libraryBadge = ValueNotifier<bool>(false);
    unreadNotifications = ValueNotifier<bool>(true);
    backdropSuppressed = ValueNotifier<bool>(false);
    isBootSkeleton = ValueNotifier<bool>(false);
    toastMessage = ValueNotifier<String?>(null);
    scrollOffset = ValueNotifier<double>(0.0);
    userReducedMotion = ValueNotifier<bool>(false);

    if (_enableTicker) {
      _ticker = Timer.periodic(const Duration(milliseconds: 250), _onTick);
    }

    if (_enableNetworkArt) {
      unawaited(hydrateArtCatalog());
    }
  }

  final bool _enableTicker;
  final bool _enableNetworkArt;
  Timer? _ticker;
  Timer? _toastTimer;
  Completer<void>? _artInitCompleter;
  final List<double> _tabScrollOffsets = [0.0, 0.0, 0.0, 0.0];

  late final ValueNotifier<List<OrbitTrack>> catalogTracks;
  late final ValueNotifier<List<OrbitPlaylist>> catalogPlaylists;
  late final ValueNotifier<List<OrbitArtist>> catalogArtists;
  late final ValueNotifier<List<OrbitCategory>> catalogCategories;

  late final ValueNotifier<OrbitTrack> currentTrack;
  late final ValueNotifier<Color> activeArtColor;
  late final ValueNotifier<String> currentSourceLabel;
  late final ValueNotifier<bool> isPlaying;
  late final ValueNotifier<double> progress;
  late final ValueNotifier<bool> isShuffled;
  late final ValueNotifier<int> repeatMode;
  late final ValueNotifier<int> currentTab;
  late final ValueNotifier<int> selectedHomeFilter;
  late final ValueNotifier<int> selectedLibraryFilter;
  late final ValueNotifier<bool> libraryGridMode;
  late final ValueNotifier<int> librarySortMode;
  late final ValueNotifier<Set<String>> likedTrackIds;
  late final ValueNotifier<Set<String>> savedPlaylistIds;
  late final ValueNotifier<Set<String>> downloadedPlaylistIds;
  late final ValueNotifier<List<OrbitPlaylist>> userPlaylists;
  late final ValueNotifier<List<OrbitTrack>> queue;
  late final ValueNotifier<bool> libraryBadge;
  late final ValueNotifier<bool> unreadNotifications;
  late final ValueNotifier<bool> backdropSuppressed;
  late final ValueNotifier<bool> isBootSkeleton;
  late final ValueNotifier<String?> toastMessage;
  late final ValueNotifier<double> scrollOffset;
  late final ValueNotifier<bool> userReducedMotion;

  List<OrbitPlaylist> get allPlaylists => [
        ...userPlaylists.value,
        ...catalogPlaylists.value,
      ];

  /// First 12 artwork URLs to precache during the splash sequence.
  List<String> get initialPrecacheUrls {
    final urls = <String>{};
    for (final p in catalogPlaylists.value) {
      if ((p.imageUrl ?? '').isNotEmpty) urls.add(p.imageUrl!);
      if (urls.length >= 8) break;
    }
    for (final a in catalogArtists.value) {
      if ((a.imageUrl ?? '').isNotEmpty) urls.add(a.imageUrl!);
      if (urls.length >= 12) break;
    }
    return urls.take(12).toList(growable: false);
  }

  Future<void> hydrateArtCatalog() async {
    if (_artInitCompleter != null) return _artInitCompleter!.future;
    _artInitCompleter = Completer<void>();

    try {
      // 1. Instant load from disk cache if available
      final cached = await ArtRepository.instance.readDiskCache();
      if (cached != null) {
        _applyBundle(cached);
      }

      // 2. Refresh in background from Deezer -> iTunes -> Picsum
      final fresh = await ArtRepository.instance.fetchAndCacheAll();
      _applyBundle(fresh);
    } catch (_) {
      // Keep fallback artwork cleanly.
    } finally {
      if (!(_artInitCompleter?.isCompleted ?? true)) {
        _artInitCompleter!.complete();
      }
    }
  }

  void _applyBundle(ArtHydrationBundle bundle) {
    catalogPlaylists.value = bundle.playlists;
    catalogArtists.value = bundle.artists;
    catalogTracks.value = bundle.tracks;
    catalogCategories.value = bundle.categories;

    final curId = currentTrack.value.id;
    final updatedCurrent = bundle.tracks.firstWhere(
      (t) => t.id == curId,
      orElse: () => currentTrack.value,
    );
    currentTrack.value = updatedCurrent;
    unawaited(_resolveActiveColor(updatedCurrent));

    final updatedQueue = queue.value.map((qt) {
      return bundle.tracks.firstWhere((t) => t.id == qt.id, orElse: () => qt);
    }).toList(growable: false);
    queue.value = updatedQueue;
  }

  Future<void> _resolveActiveColor(OrbitTrack track) async {
    final url = track.imageUrl;
    if (url != null && url.isNotEmpty && _enableNetworkArt) {
      final resolved = await DominantColor.of(
        CachedNetworkImageProvider(url),
        cacheKey: 'trk_${track.id}_$url',
        fallback: track.dominantColor,
      );
      if (currentTrack.value.id == track.id) {
        activeArtColor.value = resolved;
      }
      return;
    }
    activeArtColor.value = track.dominantColor;
  }

  List<OrbitTrack> tracksForPlaylist(OrbitPlaylist playlist) {
    final list = catalogTracks.value;
    return playlist.trackIds
        .map(
          (id) => list.firstWhere(
            (t) => t.id == id,
            orElse: () => list.first,
          ),
        )
        .toList(growable: false);
  }

  List<OrbitTrack> tracksForArtist(String artistId) {
    return catalogTracks.value
        .where((t) => t.artistId == artistId)
        .toList(growable: false);
  }

  OrbitArtist artistById(String id) {
    return catalogArtists.value.firstWhere(
      (a) => a.id == id,
      orElse: () => catalogArtists.value.first,
    );
  }

  void setTabScrollOffset(int tabIndex, double pixels) {
    if (tabIndex >= 0 && tabIndex < _tabScrollOffsets.length) {
      _tabScrollOffsets[tabIndex] = pixels;
      if (currentTab.value == tabIndex) {
        scrollOffset.value = pixels;
      }
    }
  }

  void setDetailScrollOffset(double pixels) {
    scrollOffset.value = pixels;
  }

  void _onTick(Timer _) {
    if (!isPlaying.value) return;
    final dur = currentTrack.value.durationSeconds;
    if (dur <= 0) return;
    final delta = 0.25 / dur;
    final next = progress.value + delta;
    if (next >= 1.0) {
      if (repeatMode.value == 2) {
        progress.value = 0.0;
      } else {
        nextTrack(autoAdvance: true);
      }
    } else {
      progress.value = next;
    }
  }

  void selectTab(int index) {
    final clamped = index.clamp(0, 3);
    if (currentTab.value == clamped) return;
    currentTab.value = clamped;
    scrollOffset.value = _tabScrollOffsets[clamped];
    if (clamped == 2) {
      libraryBadge.value = false;
    }
  }

  void togglePlay() {
    OrbitHaptics.medium();
    isPlaying.value = !isPlaying.value;
  }

  void playTrack(
    OrbitTrack track, {
    String? sourceLabel,
    List<OrbitTrack>? contextQueue,
  }) {
    OrbitHaptics.light();
    currentTrack.value = track;
    unawaited(_resolveActiveColor(track));
    if (sourceLabel != null) {
      currentSourceLabel.value = sourceLabel;
    }
    if (contextQueue != null && contextQueue.isNotEmpty) {
      final idx = contextQueue.indexWhere((t) => t.id == track.id);
      if (idx >= 0) {
        final after = contextQueue.sublist(idx + 1);
        final before = contextQueue.sublist(0, idx);
        queue.value = [...after, ...before];
      } else {
        queue.value = contextQueue;
      }
    }
    progress.value = 0.0;
    isPlaying.value = true;
  }

  void playPlaylist(OrbitPlaylist playlist, {bool shuffle = false}) {
    final tracks = tracksForPlaylist(playlist);
    if (tracks.isEmpty) return;
    final ordered = shuffle ? (List<OrbitTrack>.from(tracks)..shuffle()) : tracks;
    isShuffled.value = shuffle;
    playTrack(
      ordered.first,
      sourceLabel: playlist.title,
      contextQueue: ordered,
    );
  }

  void nextTrack({bool autoAdvance = false}) {
    if (!autoAdvance) OrbitHaptics.light();
    final q = queue.value;
    if (q.isNotEmpty) {
      final next = q.first;
      final rest = q.sublist(1);
      queue.value = [...rest, currentTrack.value];
      currentTrack.value = next;
      unawaited(_resolveActiveColor(next));
      progress.value = 0.0;
      isPlaying.value = true;
      return;
    }
    final all = catalogTracks.value;
    final idx = all.indexWhere((t) => t.id == currentTrack.value.id);
    final nextIdx = isShuffled.value
        ? (idx + 3) % all.length
        : (idx + 1) % all.length;
    currentTrack.value = all[nextIdx];
    unawaited(_resolveActiveColor(all[nextIdx]));
    progress.value = 0.0;
    isPlaying.value = true;
  }

  void previousTrack() {
    OrbitHaptics.light();
    if (progress.value > 0.08) {
      progress.value = 0.0;
      return;
    }
    final all = catalogTracks.value;
    final idx = all.indexWhere((t) => t.id == currentTrack.value.id);
    final prevIdx = (idx - 1 + all.length) % all.length;
    currentTrack.value = all[prevIdx];
    unawaited(_resolveActiveColor(all[prevIdx]));
    progress.value = 0.0;
    isPlaying.value = true;
  }

  void seekTo(double fraction) {
    progress.value = fraction.clamp(0.0, 1.0);
  }

  void toggleShuffle() {
    OrbitHaptics.selection();
    isShuffled.value = !isShuffled.value;
  }

  void cycleRepeat() {
    OrbitHaptics.selection();
    repeatMode.value = (repeatMode.value + 1) % 3;
  }

  bool isTrackLiked(String trackId) => likedTrackIds.value.contains(trackId);

  void toggleTrackLike(OrbitTrack track) {
    OrbitHaptics.light();
    final updated = Set<String>.from(likedTrackIds.value);
    final added = !updated.contains(track.id);
    if (added) {
      updated.add(track.id);
      showToast('Saved "${track.title}" to Liked Songs');
    } else {
      updated.remove(track.id);
      showToast('Removed "${track.title}" from Liked Songs');
    }
    likedTrackIds.value = updated;
  }

  void addToQueue(OrbitTrack track) {
    OrbitHaptics.light();
    queue.value = [track, ...queue.value.where((t) => t.id != track.id)];
    showToast('Added "${track.title}" to queue');
  }

  void addPlaylistToQueue(OrbitPlaylist playlist) {
    OrbitHaptics.light();
    final tracks = tracksForPlaylist(playlist);
    final existingIds = tracks.map((t) => t.id).toSet();
    queue.value = [
      ...tracks,
      ...queue.value.where((t) => !existingIds.contains(t.id)),
    ];
    showToast('Queued ${tracks.length} tracks from ${playlist.title}');
  }

  bool isPlaylistSaved(String playlistId) =>
      savedPlaylistIds.value.contains(playlistId);

  void togglePlaylistSaved(OrbitPlaylist playlist) {
    OrbitHaptics.light();
    final updated = Set<String>.from(savedPlaylistIds.value);
    if (updated.contains(playlist.id)) {
      updated.remove(playlist.id);
      showToast('Removed "${playlist.title}" from Your Library');
    } else {
      updated.add(playlist.id);
      libraryBadge.value = true;
      showToast('Saved "${playlist.title}" to Your Library');
    }
    savedPlaylistIds.value = updated;
  }

  bool isPlaylistDownloaded(String playlistId) =>
      downloadedPlaylistIds.value.contains(playlistId);

  void togglePlaylistDownloaded(OrbitPlaylist playlist) {
    OrbitHaptics.light();
    final updated = Set<String>.from(downloadedPlaylistIds.value);
    if (updated.contains(playlist.id)) {
      updated.remove(playlist.id);
      showToast('Removed offline download');
    } else {
      updated.add(playlist.id);
      showToast('Downloaded "${playlist.title}" for offline listening');
    }
    downloadedPlaylistIds.value = updated;
  }

  void createPlaylist({
    required String title,
    required String description,
    required Color accentColor,
    required Color secondaryColor,
    required List<String> trackIds,
  }) {
    OrbitHaptics.medium();
    final id = 'user_pl_${DateTime.now().millisecondsSinceEpoch}';
    final created = OrbitPlaylist(
      id: id,
      title: title.trim().isEmpty ? 'Untitled Orbit Mix' : title.trim(),
      subtitle: description.trim().isEmpty
          ? 'Created by ${OrbitMockData.userName}'
          : description.trim(),
      creator: OrbitMockData.userName,
      year: 2026,
      savesLabel: '1 save',
      durationLabel: '${trackIds.length * 4}m',
      seed: id.hashCode,
      dominantColor: accentColor,
      secondaryColor: secondaryColor,
      kind: OrbitKind.music,
      section: 'Your mixes',
      trackIds: trackIds.isEmpty
          ? const ['trk_01', 'trk_02', 'trk_03', 'trk_07']
          : trackIds,
      pinned: true,
      imageUrl: _enableNetworkArt ? ArtRepository.picsumUrl(id) : null,
    );
    userPlaylists.value = [created, ...userPlaylists.value];
    savedPlaylistIds.value = {...savedPlaylistIds.value, id};
    libraryBadge.value = true;
    showToast('Created "${created.title}" in Your Library');
  }

  void markNotificationsRead() {
    unreadNotifications.value = false;
  }

  void setBackdropSuppressed(bool suppressed) {
    if (backdropSuppressed.value != suppressed) {
      backdropSuppressed.value = suppressed;
    }
  }

  void showToast(String message) {
    toastMessage.value = message;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 2), () {
      toastMessage.value = null;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _toastTimer?.cancel();
    catalogTracks.dispose();
    catalogPlaylists.dispose();
    catalogArtists.dispose();
    catalogCategories.dispose();
    currentTrack.dispose();
    activeArtColor.dispose();
    currentSourceLabel.dispose();
    isPlaying.dispose();
    progress.dispose();
    isShuffled.dispose();
    repeatMode.dispose();
    currentTab.dispose();
    selectedHomeFilter.dispose();
    selectedLibraryFilter.dispose();
    libraryGridMode.dispose();
    librarySortMode.dispose();
    likedTrackIds.dispose();
    savedPlaylistIds.dispose();
    downloadedPlaylistIds.dispose();
    userPlaylists.dispose();
    queue.dispose();
    libraryBadge.dispose();
    unreadNotifications.dispose();
    backdropSuppressed.dispose();
    isBootSkeleton.dispose();
    toastMessage.dispose();
    scrollOffset.dispose();
    userReducedMotion.dispose();
    super.dispose();
  }
}

/// InheritedNotifier scope giving every screen clean O(1) access to OrbitController.
class OrbitScope extends InheritedNotifier<OrbitController> {
  const OrbitScope({
    super.key,
    required OrbitController controller,
    required super.child,
  }) : super(notifier: controller);

  static OrbitController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OrbitScope>();
    assert(scope != null, 'OrbitScope not found in widget tree');
    return scope!.notifier!;
  }

  static OrbitController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<OrbitScope>();
    assert(scope != null, 'OrbitScope not found in widget tree');
    return scope!.notifier!;
  }

  static OrbitController? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<OrbitScope>()?.notifier;
  }
}
