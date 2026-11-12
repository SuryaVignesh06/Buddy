import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:orbit/core/debug.dart';
import 'package:orbit/core/springs.dart';
import 'package:orbit/core/tokens.dart';
import 'package:orbit/data/mock.dart';
import 'package:orbit/features/shell/glass_nav.dart';
import 'package:orbit/features/splash/splash_page.dart';
import 'package:orbit/main.dart';
import 'package:orbit/widgets/adaptive_header.dart';
import 'package:orbit/widgets/album_card.dart';
import 'package:orbit/widgets/glass_player_card.dart';
import 'package:orbit/widgets/liquid_backdrop.dart';
import 'package:orbit/widgets/mini_player.dart';
import 'package:orbit/widgets/track_row.dart';
import 'package:orbit/widgets/wave_seek_bar.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('Mock dataset counts, Orbit v2 tokens, and spring constants', () {
    expect(OrbitMockData.playlists.length, 24);
    expect(OrbitMockData.artists.length, 12);
    expect(OrbitMockData.tracks.length, 40);
    expect(OrbitMockData.categories.length, 12);

    expect(kForceSplash, isTrue);
    expect(OrbitTokens.black, const Color(0xFF000000));
    expect(OrbitTokens.flameRed, const Color(0xFFFF2D00));
    expect(OrbitTokens.flame, const Color(0xFFFF4D00));
    expect(OrbitTokens.orange, const Color(0xFFFF7A00));
    expect(OrbitTokens.amber, const Color(0xFFFFB000));
    expect(OrbitTokens.crimson, const Color(0xFFB81800));
    expect(OrbitTokens.ember, const Color(0xFF5C0F00));
    expect(OrbitTokens.pinkRed, const Color(0xFFFF2E63));

    final liquidSim = Springs.simulate(Springs.liquid, start: 0.0, end: 1.0);
    expect(liquidSim.x(0.25), greaterThan(1.0)); // juicy overshoot
  });

  testWidgets('Splash plays on start and tap-to-skip transitions to Home',
      (tester) async {
    await tester.pumpWidget(
      const OrbitApp(
        enablePlaybackTicker: false,
        enableNetworkArt: false,
      ),
    );
    expect(find.byType(SplashPage), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));

    // Tap anywhere to skip splash cleanly
    await tester.tapAt(const Offset(160, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 780));

    expect(find.text('Made for you'), findsOneWidget);
    expect(find.byType(FloatingGlassNav), findsOneWidget);
    expect(find.byType(LiquidBackdrop), findsOneWidget);
  });

  testWidgets(
      'All 5 screens, detail, and Wave Now Playing render without overflow at 320px & 1.3 text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(1.3),
        ),
        child: const OrbitApp(
          enablePlaybackTicker: false,
          enableNetworkArt: false,
        ),
      ),
    );

    // Skip splash via tap and let 700ms PageRouteBuilder transition settle
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(const Offset(160, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 780));

    expect(find.text('Made for you'), findsOneWidget);
    expect(
      find.byType(BackdropFilter).evaluate().length,
      lessThanOrEqualTo(3),
    );

    // Switch to Search tab and verify Home is completely offstage (zero bleed-through)
    await tester.tap(find.bySemanticsLabel('Search tab'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Browse all'), findsOneWidget);
    expect(find.text('Made for you'), findsNothing);
    expect(
      find.byType(BackdropFilter).evaluate().length,
      lessThanOrEqualTo(3),
    );

    // Switch to Library tab and toggle 3-col grid mode
    await tester.tap(find.bySemanticsLabel('Library tab'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Your Library'), findsOneWidget);
    expect(find.text('Browse all'), findsNothing);

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byType(BackdropFilter).evaluate().length,
      lessThanOrEqualTo(3),
    );

    // Switch to Create tab
    await tester.tap(find.bySemanticsLabel('Create tab'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Create Mix'), findsOneWidget);
    expect(find.text('Your Library'), findsNothing);

    // Return to Home tab, scroll to first AlbumCard, & open Playlist Detail
    await tester.tap(find.bySemanticsLabel('Home tab'));
    await tester.pump(const Duration(milliseconds: 500));
    final firstAlbum = find.byType(AlbumCard).first;
    await tester.ensureVisible(firstAlbum);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(firstAlbum);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(
      find.byType(BackdropFilter).evaluate().length,
      lessThanOrEqualTo(3),
    );

    // Scroll Playlist Detail so AdaptiveHeader collapses and TrackRow materializes
    final detailScroll = find.ancestor(
      of: find.byType(AdaptiveHeader),
      matching: find.byType(CustomScrollView),
    );
    await tester.drag(detailScroll, const Offset(0, -320));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TrackRow), findsWidgets);

    // Swipe right on first TrackRow to add to queue
    final firstTrack = find.byType(TrackRow).first;
    await tester.drag(firstTrack, const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Added "Solar Drift" to queue'), findsOneWidget);

    // Open Now Playing sheet from MiniPlayer and verify GlassPlayerCard + WaveSeekBar
    await tester.tap(find.byType(MiniPlayer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('PLAYING FROM'), findsOneWidget);
    expect(find.byType(GlassPlayerCard), findsOneWidget);
    expect(find.byType(WaveSeekBar), findsOneWidget);
    expect(find.text('Lyrics'), findsOneWidget);
    expect(
      find.byType(BackdropFilter).evaluate().length,
      lessThanOrEqualTo(3),
    );
  });

  testWidgets('Horizontal drag-scrub on FloatingGlassNav switches tabs',
      (tester) async {
    await tester.pumpWidget(
      const OrbitApp(
        enablePlaybackTicker: false,
        enableNetworkArt: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(const Offset(160, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 780));

    final navFinder = find.byType(FloatingGlassNav);
    expect(navFinder, findsOneWidget);
    final navRect = tester.getRect(navFinder);
    final slotWidth = (navRect.width - 40) / 4;

    await tester.dragFrom(
      Offset(navRect.left + 20 + slotWidth * 0.5, navRect.center.dy),
      Offset(slotWidth, 0),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Browse all'), findsOneWidget);
    expect(find.text('Made for you'), findsNothing);
  });
}
