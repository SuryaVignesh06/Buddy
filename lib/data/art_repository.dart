// Cover art belongs to its rights holders. It is fine for a private prototype
// or portfolio screenshots. Before any public release, swap the repository
// for licensed or original art.

import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/tokens.dart';
import 'cache_store.dart';
import 'mock.dart';

typedef Album = OrbitPlaylist;

/// Bundle of resolved artwork and music metadata hydrated into [OrbitController].
class ArtHydrationBundle {
  const ArtHydrationBundle({
    required this.playlists,
    required this.artists,
    required this.tracks,
    required this.categories,
  });

  final List<OrbitPlaylist> playlists;
  final List<OrbitArtist> artists;
  final List<OrbitTrack> tracks;
  final List<OrbitCategory> categories;
}

/// Public artwork & catalog repository backed by Deezer -> iTunes -> Picsum -> GeneratedArt.
class ArtRepository {
  ArtRepository({http.Client? client}) : _client = client ?? http.Client();

  static final ArtRepository instance = ArtRepository();

  static const String _cacheFileName = 'orbit_art_cache_v2.json';
  static const Duration _requestTimeout = Duration(seconds: 6);

  static const List<String> personalizedSeedTerms = [
    'Arijit Singh',
    'Anirudh Ravichander',
    'Sid Sriram',
    'A. R. Rahman',
    'The Weeknd',
    'Taylor Swift',
    'Dua Lipa',
  ];

  final http.Client _client;
  final Map<String, List<OrbitPlaylist>> _searchCache = {};

  static String picsumUrl(String id) =>
      'https://picsum.photos/seed/${Uri.encodeComponent(id)}/800/800';

  static String _upgradeItunesArtwork(String? url) {
    if (url == null || url.isEmpty) return '';
    return url
        .replaceAll('100x100bb', '800x800bb')
        .replaceAll('60x60bb', '800x800bb');
  }

  Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _client.get(uri).timeout(_requestTimeout);
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        }
      } catch (_) {
        if (attempt == 1) return null;
      }
    }
    return null;
  }

  /// Trending albums: Deezer chart -> iTunes search -> Picsum fallback.
  Future<List<Album>> trending() async {
    if (!kIsWeb) {
      final deezer = await _getJson(
        Uri.parse('https://api.deezer.com/chart/0/albums?limit=30'),
      );
      final data = deezer?['data'];
      if (data is List && data.isNotEmpty) {
        final out = <Album>[];
        for (var i = 0; i < data.length; i++) {
          final item = data[i];
          if (item is! Map) continue;
          final cover = (item['cover_xl'] ?? item['cover_big'] ?? '').toString();
          final title = (item['title'] ?? '').toString();
          final artistMap = item['artist'];
          final artistName =
              artistMap is Map ? (artistMap['name'] ?? 'Orbit Artist').toString() : 'Orbit Artist';
          if (cover.isEmpty || title.isEmpty) continue;
          final base = OrbitMockData.playlists[i % OrbitMockData.playlists.length];
          out.add(
            base.copyWith(
              title: title,
              subtitle: '$artistName • Album',
              creator: artistName,
              imageUrl: cover,
            ),
          );
        }
        if (out.isNotEmpty) return out;
      }
    }

    // Fallback to iTunes Search API (also primary on Web due to Deezer CORS block)
    final itunes = await search('top hits 2025');
    if (itunes.isNotEmpty) return itunes;

    return OrbitMockData.playlists
        .take(12)
        .map((p) => p.copyWith(imageUrl: picsumUrl(p.id)))
        .toList(growable: false);
  }

  /// Top artists: Deezer chart -> iTunes search -> Picsum fallback.
  Future<List<OrbitArtist>> artists() async {
    if (!kIsWeb) {
      final deezer = await _getJson(
        Uri.parse('https://api.deezer.com/chart/0/artists?limit=20'),
      );
      final data = deezer?['data'];
      if (data is List && data.isNotEmpty) {
        final out = <OrbitArtist>[];
        for (var i = 0; i < OrbitMockData.artists.length; i++) {
          final base = OrbitMockData.artists[i];
          final item = i < data.length ? data[i] : null;
          if (item is Map) {
            final pic = (item['picture_xl'] ?? item['picture_big'] ?? '').toString();
            final name = (item['name'] ?? base.name).toString();
            out.add(
              base.copyWith(
                name: name,
                imageUrl: pic.isNotEmpty ? pic : picsumUrl(base.id),
              ),
            );
          } else {
            out.add(base.copyWith(imageUrl: picsumUrl(base.id)));
          }
        }
        return out;
      }
    }

    // On web or if Deezer failed, resolve artist cover images via iTunes
    final futures = List.generate(OrbitMockData.artists.length, (i) async {
      final base = OrbitMockData.artists[i];
      final term = i < personalizedSeedTerms.length
          ? personalizedSeedTerms[i]
          : base.name;
      final hits = await search(term, limit: 1);
      if (hits.isNotEmpty && (hits.first.imageUrl ?? '').isNotEmpty) {
        return base.copyWith(
          name: i < personalizedSeedTerms.length ? term : base.name,
          imageUrl: hits.first.imageUrl,
        );
      }
      return base.copyWith(imageUrl: picsumUrl(base.id));
    });
    return Future.wait(futures);
  }

  /// Playlists with personalised Hindi/Telugu/Tamil/Global mix + chart playlists.
  Future<List<OrbitPlaylist>> playlists() async {
    final resolvedPersonalized = await _resolvePersonalizedRows();
    List<OrbitPlaylist> chartPlaylists = const [];

    if (!kIsWeb) {
      final deezer = await _getJson(
        Uri.parse('https://api.deezer.com/chart/0/playlists?limit=20'),
      );
      final data = deezer?['data'];
      if (data is List && data.isNotEmpty) {
        chartPlaylists = [
          for (var i = 0; i < data.length; i++)
            if (data[i] is Map &&
                ((data[i]['picture_xl'] ?? data[i]['picture_big'] ?? '')
                    .toString()
                    .isNotEmpty))
              OrbitMockData.playlists[i % OrbitMockData.playlists.length].copyWith(
                title: (data[i]['title'] ?? OrbitMockData.playlists[i % OrbitMockData.playlists.length].title)
                    .toString(),
                imageUrl: (data[i]['picture_xl'] ?? data[i]['picture_big']).toString(),
              ),
        ];
      }
    }

    if (chartPlaylists.isEmpty) {
      chartPlaylists = await trending();
    }

    final merged = <OrbitPlaylist>[];
    for (var i = 0; i < OrbitMockData.playlists.length; i++) {
      final base = OrbitMockData.playlists[i];
      if ((base.section == 'Made for you' || base.section == 'Jump back in') &&
          resolvedPersonalized.isNotEmpty) {
        final pick = resolvedPersonalized[i % resolvedPersonalized.length];
        merged.add(
          base.copyWith(
            title: pick.title,
            subtitle: pick.subtitle,
            creator: pick.creator,
            imageUrl: pick.imageUrl,
          ),
        );
      } else if (chartPlaylists.isNotEmpty) {
        final pick = chartPlaylists[i % chartPlaylists.length];
        merged.add(
          base.copyWith(
            title: pick.title,
            subtitle: pick.subtitle,
            creator: pick.creator,
            imageUrl: pick.imageUrl ?? picsumUrl(base.id),
          ),
        );
      } else {
        merged.add(base.copyWith(imageUrl: picsumUrl(base.id)));
      }
    }
    return merged;
  }

  /// Tracks from Deezer chart -> iTunes fallback -> Picsum fallback.
  Future<List<OrbitTrack>> tracks() async {
    if (!kIsWeb) {
      final deezer = await _getJson(
        Uri.parse('https://api.deezer.com/chart/0/tracks?limit=40'),
      );
      final data = deezer?['data'];
      if (data is List && data.isNotEmpty) {
        final out = <OrbitTrack>[];
        for (var i = 0; i < OrbitMockData.tracks.length; i++) {
          final base = OrbitMockData.tracks[i];
          if (i < data.length && data[i] is Map) {
            final item = data[i] as Map;
            final album = item['album'];
            final artist = item['artist'];
            final cover = album is Map
                ? (album['cover_xl'] ?? album['cover_big'] ?? '').toString()
                : '';
            final title = (item['title'] ?? base.title).toString();
            final artistName =
                artist is Map ? (artist['name'] ?? base.artistName).toString() : base.artistName;
            final dur = int.tryParse('${item['duration'] ?? ''}') ?? base.durationSeconds;
            out.add(
              base.copyWith(
                title: title,
                artistName: artistName,
                durationSeconds: dur > 30 ? dur : base.durationSeconds,
                imageUrl: cover.isNotEmpty ? cover : picsumUrl(base.id),
              ),
            );
          } else {
            out.add(base.copyWith(imageUrl: picsumUrl(base.id)));
          }
        }
        return out;
      }
    }

    // iTunes song/album search batch for Web or fallback
    final itunes = await _getJson(
      Uri.parse(
        'https://itunes.apple.com/search?term=arijit+singh+weeknd+anirudh&media=music&entity=song&limit=40',
      ),
    );
    final results = itunes?['results'];
    if (results is List && results.isNotEmpty) {
      return List.generate(OrbitMockData.tracks.length, (i) {
        final base = OrbitMockData.tracks[i];
        final item = results[i % results.length];
        if (item is Map) {
          final art = _upgradeItunesArtwork(item['artworkUrl100']?.toString());
          final title = (item['trackName'] ?? base.title).toString();
          final artistName = (item['artistName'] ?? base.artistName).toString();
          final millis = int.tryParse('${item['trackTimeMillis'] ?? ''}');
          final secs = millis != null && millis > 30000
              ? (millis / 1000).round()
              : base.durationSeconds;
          return base.copyWith(
            title: title,
            artistName: artistName,
            durationSeconds: secs,
            imageUrl: art.isNotEmpty ? art : picsumUrl(base.id),
          );
        }
        return base.copyWith(imageUrl: picsumUrl(base.id));
      });
    }

    return OrbitMockData.tracks
        .map((t) => t.copyWith(imageUrl: picsumUrl(t.id)))
        .toList(growable: false);
  }

  /// Category / genre tiles from Deezer `/genre` -> iTunes -> Picsum fallback.
  Future<List<OrbitCategory>> genres() async {
    if (!kIsWeb) {
      final deezer = await _getJson(Uri.parse('https://api.deezer.com/genre'));
      final data = deezer?['data'];
      if (data is List && data.length > 1) {
        final valid = data
            .whereType<Map>()
            .where((m) => (m['id']?.toString() ?? '0') != '0')
            .toList();
        if (valid.isNotEmpty) {
          return List.generate(OrbitMockData.categories.length, (i) {
            final base = OrbitMockData.categories[i];
            final item = valid[i % valid.length];
            final pic = (item['picture_xl'] ?? item['picture_big'] ?? '').toString();
            return base.copyWith(
              imageUrl: pic.isNotEmpty ? pic : picsumUrl(base.id),
            );
          });
        }
      }
    }

    final futures = List.generate(OrbitMockData.categories.length, (i) async {
      final base = OrbitMockData.categories[i];
      final hits = await search(base.title, limit: 1);
      final url = hits.isNotEmpty ? hits.first.imageUrl : null;
      return base.copyWith(
        imageUrl: (url != null && url.isNotEmpty) ? url : picsumUrl(base.id),
      );
    });
    return Future.wait(futures);
  }

  /// Searches albums via Deezer -> iTunes -> Picsum fallback.
  Future<List<Album>> search(String q, {int limit = 30}) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return const [];
    final cacheKey = '${trimmed.toLowerCase()}_$limit';
    final cached = _searchCache[cacheKey];
    if (cached != null) return cached;

    if (!kIsWeb) {
      final deezer = await _getJson(
        Uri.parse(
          'https://api.deezer.com/search/album?q=${Uri.encodeQueryComponent(trimmed)}&limit=$limit',
        ),
      );
      final data = deezer?['data'];
      if (data is List && data.isNotEmpty) {
        final out = <Album>[];
        for (var i = 0; i < data.length; i++) {
          final item = data[i];
          if (item is! Map) continue;
          final cover = (item['cover_xl'] ?? item['cover_big'] ?? '').toString();
          final title = (item['title'] ?? '').toString();
          final artist = item['artist'];
          final artistName =
              artist is Map ? (artist['name'] ?? trimmed).toString() : trimmed;
          if (cover.isEmpty || title.isEmpty) continue;
          final base = OrbitMockData.playlists[i % OrbitMockData.playlists.length];
          out.add(
            OrbitPlaylist(
              id: 'dz_${item['id'] ?? '${trimmed.hashCode}_$i'}',
              title: title,
              subtitle: '$artistName • Album',
              creator: artistName,
              year: 2026,
              savesLabel: base.savesLabel,
              durationLabel: base.durationLabel,
              seed: title.hashCode,
              dominantColor: base.dominantColor,
              secondaryColor: base.secondaryColor,
              kind: OrbitKind.music,
              section: 'Search',
              trackIds: base.trackIds,
              libraryType: LibraryItemType.album,
              imageUrl: cover,
            ),
          );
        }
        if (out.isNotEmpty) {
          _searchCache[cacheKey] = out;
          return out;
        }
      }
    }

    // iTunes Search API
    final itunes = await _getJson(
      Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeQueryComponent(trimmed)}&media=music&entity=album&limit=$limit',
      ),
    );
    final results = itunes?['results'];
    if (results is List && results.isNotEmpty) {
      final out = <Album>[];
      for (var i = 0; i < results.length; i++) {
        final item = results[i];
        if (item is! Map) continue;
        final art = _upgradeItunesArtwork(item['artworkUrl100']?.toString());
        final title = (item['collectionName'] ?? item['trackName'] ?? '').toString();
        final artistName = (item['artistName'] ?? trimmed).toString();
        if (art.isEmpty || title.isEmpty) continue;
        final base = OrbitMockData.playlists[i % OrbitMockData.playlists.length];
        out.add(
          OrbitPlaylist(
            id: 'it_${item['collectionId'] ?? '${trimmed.hashCode}_$i'}',
            title: title,
            subtitle: '$artistName • Album',
            creator: artistName,
            year: 2026,
            savesLabel: base.savesLabel,
            durationLabel: base.durationLabel,
            seed: title.hashCode,
            dominantColor: base.dominantColor,
            secondaryColor: base.secondaryColor,
            kind: OrbitKind.music,
            section: 'Search',
            trackIds: base.trackIds,
            libraryType: LibraryItemType.album,
            imageUrl: art,
          ),
        );
      }
      if (out.isNotEmpty) {
        _searchCache[cacheKey] = out;
        return out;
      }
    }

    // Picsum deterministic fallback
    final fallback = [
      OrbitMockData.playlists.first.copyWith(
        title: trimmed,
        subtitle: '$trimmed • Mix',
        imageUrl: picsumUrl('search_${trimmed.hashCode}'),
      ),
    ];
    _searchCache[cacheKey] = fallback;
    return fallback;
  }

  Future<List<Album>> _resolvePersonalizedRows() async {
    final results = await Future.wait(
      personalizedSeedTerms.map((term) async {
        final hits = await search(term, limit: 1);
        return hits.isNotEmpty ? hits.first : null;
      }),
    );
    return results.whereType<Album>().toList(growable: false);
  }

  /// Loads cached catalog JSON immediately if present, then fetches fresh data.
  Future<ArtHydrationBundle?> readDiskCache() async {
    final raw = await ArtCacheStore.read(_cacheFileName);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      final plRaw = (map['playlists'] as List?) ?? const [];
      final arRaw = (map['artists'] as List?) ?? const [];
      final trRaw = (map['tracks'] as List?) ?? const [];
      final catRaw = (map['categories'] as List?) ?? const [];

      final playlists = List.generate(OrbitMockData.playlists.length, (i) {
        final base = OrbitMockData.playlists[i];
        if (i < plRaw.length && plRaw[i] is Map) {
          final m = plRaw[i] as Map;
          return base.copyWith(
            title: m['title']?.toString(),
            subtitle: m['subtitle']?.toString(),
            creator: m['creator']?.toString(),
            imageUrl: m['imageUrl']?.toString(),
          );
        }
        return base;
      });
      final artists = List.generate(OrbitMockData.artists.length, (i) {
        final base = OrbitMockData.artists[i];
        if (i < arRaw.length && arRaw[i] is Map) {
          final m = arRaw[i] as Map;
          return base.copyWith(
            name: m['name']?.toString(),
            imageUrl: m['imageUrl']?.toString(),
          );
        }
        return base;
      });
      final tracks = List.generate(OrbitMockData.tracks.length, (i) {
        final base = OrbitMockData.tracks[i];
        if (i < trRaw.length && trRaw[i] is Map) {
          final m = trRaw[i] as Map;
          return base.copyWith(
            title: m['title']?.toString(),
            artistName: m['artistName']?.toString(),
            durationSeconds: int.tryParse('${m['durationSeconds'] ?? ''}'),
            imageUrl: m['imageUrl']?.toString(),
          );
        }
        return base;
      });
      final categories = List.generate(OrbitMockData.categories.length, (i) {
        final base = OrbitMockData.categories[i];
        if (i < catRaw.length && catRaw[i] is Map) {
          final m = catRaw[i] as Map;
          return base.copyWith(imageUrl: m['imageUrl']?.toString());
        }
        return base;
      });

      return ArtHydrationBundle(
        playlists: playlists,
        artists: artists,
        tracks: tracks,
        categories: categories,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetches live artwork across all sections and writes disk cache.
  Future<ArtHydrationBundle> fetchAndCacheAll() async {
    final results = await Future.wait([
      playlists(),
      artists(),
      tracks(),
      genres(),
    ]);

    final bundle = ArtHydrationBundle(
      playlists: results[0] as List<OrbitPlaylist>,
      artists: results[1] as List<OrbitArtist>,
      tracks: results[2] as List<OrbitTrack>,
      categories: results[3] as List<OrbitCategory>,
    );

    unawaited(_writeDiskCache(bundle));
    return bundle;
  }

  Future<void> _writeDiskCache(ArtHydrationBundle bundle) async {
    final payload = {
      'playlists': bundle.playlists
          .map((p) => {
                'id': p.id,
                'title': p.title,
                'subtitle': p.subtitle,
                'creator': p.creator,
                'imageUrl': p.imageUrl,
              })
          .toList(),
      'artists': bundle.artists
          .map((a) => {
                'id': a.id,
                'name': a.name,
                'imageUrl': a.imageUrl,
              })
          .toList(),
      'tracks': bundle.tracks
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'artistName': t.artistName,
                'durationSeconds': t.durationSeconds,
                'imageUrl': t.imageUrl,
              })
          .toList(),
      'categories': bundle.categories
          .map((c) => {
                'id': c.id,
                'imageUrl': c.imageUrl,
              })
          .toList(),
    };
    await ArtCacheStore.write(_cacheFileName, jsonEncode(payload));
  }

  /// Precaches up to the first 12 images during splash, with a hard 3s timeout.
  Future<void> precacheInitialImages(
    BuildContext context, {
    required Iterable<String> urls,
  }) async {
    final candidates = urls
        .where((u) => u.isNotEmpty)
        .toSet()
        .take(12)
        .toList(growable: false);
    if (candidates.isEmpty) return;

    try {
      await Future.wait(
        candidates.map((url) async {
          try {
            await precacheImage(
              CachedNetworkImageProvider(url),
              context,
            );
          } catch (_) {
            // Individual image error falls back to GeneratedArt cleanly.
          }
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      // 3-second timeout exceeded; proceed smoothly into Home.
    }
  }

  /// Helper producing a deterministic fallback Color seeded from an id.
  static Color seededPlaceholderColor(String id) {
    final hash = id.hashCode.abs();
    const palette = [
      OrbitTokens.ember,
      OrbitTokens.crimson,
      OrbitTokens.surface3,
      Color(0xFF28120A),
      Color(0xFF1A1423),
    ];
    return palette[hash % palette.length];
  }
}
