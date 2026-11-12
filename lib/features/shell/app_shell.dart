import 'package:flutter/material.dart';

import '../../core/orbit_state.dart';
import '../../core/tokens.dart';
import '../../core/typography.dart';
import '../../data/mock.dart';
import '../../widgets/liquid_backdrop.dart';
import '../../widgets/mini_player.dart';
import '../create/create_page.dart';
import '../home/home_page.dart';
import '../library/library_page.dart';
import '../player/now_playing_sheet.dart';
import '../search/search_page.dart';
import 'glass_nav.dart';

/// Persistent app shell hosting ONE [LiquidBackdrop], tab navigators,
/// floating Tier A glass mini player, liquid-glass metaball nav pill, and toast banner.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.dotSlotKey,
    this.entryProgress = 1.0,
    this.enableDotHero = true,
  });

  final GlobalKey dotSlotKey;
  final double entryProgress;
  final bool enableDotHero;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final List<GlobalKey<NavigatorState>> _tabNavKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  int _previousTab = 0;

  @override
  Widget build(BuildContext context) {
    final orbit = OrbitScope.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final springT = Curves.easeOutBack
        .transform(widget.entryProgress.clamp(0.0, 1.0));
    final bottomSlideY = (1.0 - springT) * 120.0;

    return ValueListenableBuilder<int>(
      valueListenable: orbit.currentTab,
      builder: (context, tabIndex, _) {
        final slideDir = tabIndex >= _previousTab ? 1.0 : -1.0;
        _previousTab = tabIndex;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final nav = _tabNavKeys[tabIndex].currentState;
            if (nav != null && nav.canPop()) {
              nav.pop();
              return;
            }
            if (tabIndex != 0) {
              orbit.selectTab(0);
            }
          },
          child: Scaffold(
            backgroundColor: OrbitTokens.black,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                // Single vibrant orange-red animated backdrop behind every tab
                Positioned.fill(
                  child: ValueListenableBuilder<OrbitTrack>(
                    valueListenable: orbit.currentTrack,
                    builder: (context, track, _) {
                      return LiquidBackdrop(
                        scrollOffset: orbit.scrollOffset,
                        isPlaying: orbit.isPlaying,
                        trackHue: orbit.activeArtColor,
                        bpm: track.bpm,
                      );
                    },
                  ),
                ),

                // Tab contents kept mounted with cross-fade + micro-slide
                Positioned.fill(
                  child: _FadeSlideTabStack(
                    currentIndex: tabIndex,
                    slideDir: slideDir,
                    children: [
                      _TabNavigator(
                        navigatorKey: _tabNavKeys[0],
                        child: HomePage(
                          dotSlotKey: widget.dotSlotKey,
                          entryProgress: widget.entryProgress,
                          enableDotHero: widget.enableDotHero,
                        ),
                      ),
                      _TabNavigator(
                        navigatorKey: _tabNavKeys[1],
                        child: const SearchPage(),
                      ),
                      _TabNavigator(
                        navigatorKey: _tabNavKeys[2],
                        child: const LibraryPage(),
                      ),
                      _TabNavigator(
                        navigatorKey: _tabNavKeys[3],
                        child: const CreatePage(),
                      ),
                    ],
                  ),
                ),

                // Bottom fade scrim behind floating mini player & pill
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: OrbitTokens.navPillHeight +
                      OrbitTokens.navBottomMargin +
                      OrbitTokens.miniPlayerHeight +
                      OrbitTokens.miniPlayerGap +
                      safeBottom +
                      14,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            OrbitTokens.black.withValues(alpha: 0.72),
                            OrbitTokens.black,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Toast feedback banner above mini player
                Positioned(
                  left: OrbitTokens.space24,
                  right: OrbitTokens.space24,
                  bottom: OrbitTokens.navPillHeight +
                      OrbitTokens.navBottomMargin +
                      OrbitTokens.miniPlayerHeight +
                      OrbitTokens.miniPlayerGap +
                      safeBottom +
                      14,
                  child: ValueListenableBuilder<String?>(
                    valueListenable: orbit.toastMessage,
                    builder: (context, msg, _) {
                      return IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: msg != null ? 1.0 : 0.0,
                          duration: OrbitTokens.durChip,
                          child: AnimatedSlide(
                            offset: msg != null
                                ? Offset.zero
                                : const Offset(0, 0.25),
                            duration: OrbitTokens.durChip,
                            curve: OrbitTokens.curveDefault,
                            child: msg == null
                                ? const SizedBox.shrink()
                                : Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: OrbitTokens.space16,
                                        vertical: OrbitTokens.space8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: OrbitTokens.surface2
                                            .withValues(alpha: 0.94),
                                        borderRadius: BorderRadius.circular(
                                          OrbitTokens.radiusChip,
                                        ),
                                        border: Border.all(
                                          color: OrbitTokens.orange
                                              .withValues(alpha: 0.55),
                                        ),
                                        boxShadow: OrbitTokens.softElevation,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 15,
                                            color: OrbitTokens.orange,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              msg,
                                              style: OrbitTypography.bodyS
                                                  .copyWith(
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
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Floating MiniPlayer + Floating Liquid-Glass Nav Pill
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Transform.translate(
                    offset: Offset(0, bottomSlideY),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: orbit.backdropSuppressed,
                      builder: (context, suppressed, _) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MiniPlayer(
                              enableBackdropBlur: !suppressed,
                              onExpand: (originRect) => openNowPlayingSheet(
                                context,
                                originRect: originRect,
                              ),
                            ),
                            const SizedBox(
                              height: OrbitTokens.miniPlayerGap - 6,
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: orbit.libraryBadge,
                              builder: (context, hasBadge, _) {
                                return FloatingGlassNav(
                                  currentIndex: tabIndex,
                                  libraryBadge: hasBadge,
                                  enableBackdropBlur: !suppressed,
                                  onSelect: (idx) {
                                    if (idx == tabIndex) {
                                      _tabNavKeys[idx]
                                          .currentState
                                          ?.popUntil((r) => r.isFirst);
                                    } else {
                                      orbit.selectTab(idx);
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FadeSlideTabStack extends StatelessWidget {
  const _FadeSlideTabStack({
    required this.currentIndex,
    required this.slideDir,
    required this.children,
  });

  final int currentIndex;
  final double slideDir;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Stack(
      children: List.generate(children.length, (i) {
        final active = i == currentIndex;
        return _TabSlot(
          active: active,
          slideDir: slideDir,
          reduceMotion: reduceMotion,
          child: children[i],
        );
      }),
    );
  }
}

class _TabSlot extends StatefulWidget {
  const _TabSlot({
    required this.active,
    required this.slideDir,
    required this.reduceMotion,
    required this.child,
  });

  final bool active;
  final double slideDir;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_TabSlot> createState() => _TabSlotState();
}

class _TabSlotState extends State<_TabSlot> with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.active ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant _TabSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      if (widget.reduceMotion) {
        _enterController.value = 1.0;
      } else {
        _enterController.forward(from: 0.0);
      }
    } else if (oldWidget.active && !widget.active) {
      _enterController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !widget.active,
      child: IgnorePointer(
        ignoring: !widget.active,
        child: ExcludeSemantics(
          excluding: !widget.active,
          child: TickerMode(
            enabled: widget.active,
            child: AnimatedBuilder(
              animation: _enterController,
              child: widget.child,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(_enterController.value);
                final dx = (1.0 - t) * widget.slideDir * 12.0;
                final dy = (1.0 - t) * 8.0;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(dx, dy),
                    child: child,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, _, _) => child,
      ),
    );
  }
}
