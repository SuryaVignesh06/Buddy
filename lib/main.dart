import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/debug.dart';
import 'core/orbit_state.dart';
import 'core/theme.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const OrbitApp());
}

/// Global bouncing scroll physics across mobile, web, and desktop.
class OrbitScrollBehavior extends MaterialScrollBehavior {
  const OrbitScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

class OrbitApp extends StatefulWidget {
  const OrbitApp({
    super.key,
    this.skipSplash = false,
    this.enablePlaybackTicker = true,
    this.enableNetworkArt = true,
  });

  /// Ignored whenever [kForceSplash] is true.
  final bool skipSplash;
  final bool enablePlaybackTicker;
  final bool enableNetworkArt;

  @override
  State<OrbitApp> createState() => _OrbitAppState();
}

class _OrbitAppState extends State<OrbitApp> {
  late final OrbitController _controller;
  final GlobalKey _fallbackSlotKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = OrbitController(
      enableTicker: widget.enablePlaybackTicker,
      enableNetworkArt: widget.enableNetworkArt,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowSplash = kForceSplash || !widget.skipSplash;

    return OrbitScope(
      controller: _controller,
      child: MaterialApp(
        title: 'Orbit',
        debugShowCheckedModeBanner: false,
        theme: OrbitTheme.dark,
        scrollBehavior: const OrbitScrollBehavior(),
        builder: (context, child) {
          return MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: shouldShowSplash
            ? const SplashPage()
            : AppShell(dotSlotKey: _fallbackSlotKey),
      ),
    );
  }
}
