import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/springs.dart';
import '../../core/tokens.dart';
import '../../core/typography.dart';
import '../../widgets/glass_bubble_hover.dart';
import '../../widgets/glass_lens.dart';
import '../../widgets/orbit_nav_icons.dart';

/// Floating rounded black pill nav bar with a dual-spring metaball liquid-glass lens.
class FloatingGlassNav extends StatefulWidget {
  const FloatingGlassNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    this.libraryBadge = false,
    this.enableBackdropBlur = true,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool libraryBadge;
  final bool enableBackdropBlur;

  static const List<(OrbitNavTab, String)> _items = [
    (OrbitNavTab.home, 'Home'),
    (OrbitNavTab.search, 'Search'),
    (OrbitNavTab.library, 'Library'),
    (OrbitNavTab.create, 'Create'),
  ];

  @override
  State<FloatingGlassNav> createState() => _FloatingGlassNavState();
}

class _FloatingGlassNavState extends State<FloatingGlassNav>
    with TickerProviderStateMixin {
  late final AnimationController _leaderController;
  late final AnimationController _followerController;
  late final AnimationController _arrivalSquashController;
  late final AnimationController _labelBounceController;

  bool _dragging = false;
  int _lastSnapIndex = 0;
  int? _hoveredIndex;
  Offset _hoverParallax = Offset.zero;
  double _lastLeaderPos = 0.0;
  double _velocityEstimate = 0.0;
  bool _wasMoving = false;

  @override
  void initState() {
    super.initState();
    final start = widget.currentIndex.toDouble();
    _lastSnapIndex = widget.currentIndex;
    _lastLeaderPos = start;

    _leaderController = AnimationController.unbounded(vsync: this, value: start)
      ..addListener(() {
        final next = _leaderController.value;
        _velocityEstimate = (next - _lastLeaderPos) * 32.0;
        _lastLeaderPos = next;
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _wasMoving) {
          _wasMoving = false;
          _playArrivalSquash();
        }
      });

    _followerController =
        AnimationController.unbounded(vsync: this, value: start);

    _arrivalSquashController =
        AnimationController.unbounded(vsync: this, value: 1.0);

    _labelBounceController =
        AnimationController.unbounded(vsync: this, value: 1.0);
  }

  @override
  void didUpdateWidget(covariant FloatingGlassNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_dragging) {
      _lastSnapIndex = widget.currentIndex;
      _animateLensTo(widget.currentIndex.toDouble());
      _playLabelBounce();
    }
  }

  @override
  void dispose() {
    _leaderController.dispose();
    _followerController.dispose();
    _arrivalSquashController.dispose();
    _labelBounceController.dispose();
    super.dispose();
  }

  void _playArrivalSquash() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    _arrivalSquashController.value = 0.94;
    _arrivalSquashController.animateWith(
      Springs.simulate(Springs.bouncy, start: 0.94, end: 1.0),
    );
  }

  void _playLabelBounce() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    _labelBounceController.value = 0.85;
    _labelBounceController.animateWith(
      Springs.simulate(Springs.bouncy, start: 0.85, end: 1.0),
    );
  }

  void _animateLensTo(double target, {double velocity = 0.0}) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _leaderController.value = target;
      _followerController.value = target;
      return;
    }
    _wasMoving = true;
    _leaderController.animateWith(
      Springs.simulate(
        Springs.snappy,
        start: _leaderController.value,
        end: target,
        velocity: velocity,
      ),
    );
    _followerController.animateWith(
      Springs.simulate(
        Springs.liquid,
        start: _followerController.value,
        end: target,
        velocity: velocity * 0.65,
      ),
    );
  }

  void _handleDragStart(DragStartDetails details, double slotWidth) {
    _dragging = true;
    _leaderController.stop();
    _followerController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details, double slotWidth) {
    if (slotWidth <= 0) return;
    final next =
        (_leaderController.value + details.delta.dx / slotWidth).clamp(0.0, 3.0);
    _leaderController.value = next;
    _followerController.value =
        _followerController.value + (next - _followerController.value) * 0.42;

    final nearest = next.round().clamp(0, 3);
    if (nearest != _lastSnapIndex) {
      _lastSnapIndex = nearest;
      OrbitHaptics.selection();
      _playLabelBounce();
      widget.onSelect(nearest);
    }
  }

  void _handleDragEnd(DragEndDetails details, double slotWidth) {
    _dragging = false;
    final nearest = _leaderController.value.round().clamp(0, 3);
    final velocityInSlots =
        slotWidth > 0 ? details.velocity.pixelsPerSecond.dx / slotWidth : 0.0;
    if (nearest != widget.currentIndex) {
      OrbitHaptics.selection();
      _playLabelBounce();
      widget.onSelect(nearest);
    }
    _animateLensTo(nearest.toDouble(), velocity: velocityInSlots * 0.35);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        OrbitTokens.space20,
        6,
        OrbitTokens.space20,
        OrbitTokens.navBottomMargin + safeBottom,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = constraints.maxWidth;
          final slotWidth = pillWidth / FloatingGlassNav._items.length;
          final lensWidth =
              slotWidth < 86 ? (slotWidth + 6).clamp(68.0, 88.0) : 88.0;
          const lensHeight = 76.0;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (d) => _handleDragStart(d, slotWidth),
            onHorizontalDragUpdate: (d) => _handleDragUpdate(d, slotWidth),
            onHorizontalDragEnd: (d) => _handleDragEnd(d, slotWidth),
            child: SizedBox(
              height: OrbitTokens.navPillHeight,
              width: pillWidth,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Solid dark rounded pill container
                  Container(
                    height: OrbitTokens.navPillHeight,
                    width: pillWidth,
                    decoration: BoxDecoration(
                      color: OrbitTokens.surface1.withValues(alpha: 0.94),
                      borderRadius:
                          BorderRadius.circular(OrbitTokens.radiusNavPill),
                      border: Border.all(
                        color: OrbitTokens.pillBorder,
                        width: 1.0,
                      ),
                      boxShadow: OrbitTokens.softElevation,
                    ),
                  ),

                  // Inactive destination icons & hover bubbles
                  Row(
                    children: List.generate(FloatingGlassNav._items.length, (i) {
                      final item = FloatingGlassNav._items[i];
                      final isActive = i == widget.currentIndex;
                      final isHovered = _hoveredIndex == i && !isActive;

                      return Expanded(
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoveredIndex = i),
                          onHover: (event) {
                            final center = Offset(
                              slotWidth / 2,
                              OrbitTokens.navPillHeight / 2,
                            );
                            final delta = event.localPosition - center;
                            setState(() {
                              _hoveredIndex = i;
                              _hoverParallax = Offset(
                                (delta.dx / (slotWidth / 2) * 6).clamp(-6.0, 6.0),
                                (delta.dy / 34 * 6).clamp(-6.0, 6.0),
                              );
                            });
                          },
                          onExit: (_) => setState(() {
                            if (_hoveredIndex == i) _hoveredIndex = null;
                            _hoverParallax = Offset.zero;
                          }),
                          child: Semantics(
                            button: true,
                            selected: isActive,
                            label: '${item.$2} tab',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                OrbitHaptics.selection();
                                widget.onSelect(i);
                              },
                              onLongPressStart: (_) {
                                OrbitHaptics.selection();
                                setState(() => _hoveredIndex = i);
                              },
                              onLongPressEnd: (_) {
                                setState(() {
                                  if (_hoveredIndex == i) _hoveredIndex = null;
                                });
                              },
                              child: SizedBox(
                                height: OrbitTokens.navPillHeight,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedOpacity(
                                      opacity: isActive ? 0.0 : 1.0,
                                      duration: OrbitTokens.durPress,
                                      child: GlassBubbleHover(
                                        label: item.$2,
                                        visible: isHovered,
                                        parallax: _hoverParallax,
                                        child: OrbitNavIcon(
                                          tab: item.$1,
                                          active: false,
                                          color: OrbitTokens.textMuted,
                                        ),
                                      ),
                                    ),
                                    if (i == 2 && widget.libraryBadge)
                                      Positioned(
                                        top: 14,
                                        right: (slotWidth / 2) - 18,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: OrbitTokens.orange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Metaball liquid-glass lens sliding over the pill
                  Positioned(
                    left: 0,
                    top: (OrbitTokens.navPillHeight - lensHeight) / 2,
                    width: pillWidth,
                    height: lensHeight,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _leaderController,
                          _followerController,
                          _arrivalSquashController,
                          _labelBounceController,
                        ]),
                        builder: (context, _) {
                          final leaderPos = _leaderController.value.clamp(0.0, 3.0);
                          final followerPos =
                              _followerController.value.clamp(0.0, 3.0);

                          final leaderCenterX = ((leaderPos + 0.5) * slotWidth)
                              .clamp(lensWidth / 2 - 4, pillWidth - lensWidth / 2 + 4);
                          final followerCenterX =
                              ((followerPos + 0.5) * slotWidth)
                                  .clamp(lensWidth / 2 - 4, pillWidth - lensWidth / 2 + 4);

                          final leaderRect = Rect.fromCenter(
                            center: Offset(leaderCenterX, lensHeight / 2),
                            width: lensWidth,
                            height: lensHeight,
                          );
                          final followerRect = Rect.fromCenter(
                            center: Offset(followerCenterX, lensHeight / 2),
                            width: lensWidth * 0.78,
                            height: lensHeight * 0.88,
                          );

                          final speed = _dragging
                              ? 0.0
                              : _velocityEstimate.abs().clamp(0.0, 1.0);
                          final stretchX = 1.0 + speed * 0.30;
                          final squashX = _arrivalSquashController.value;
                          final lagOffset = _dragging
                              ? Offset.zero
                              : Offset(
                                  (-_velocityEstimate * 4.0).clamp(-6.0, 6.0),
                                  0.0,
                                );

                          final visualIndex = leaderPos.round().clamp(0, 3);
                          final activeItem =
                              FloatingGlassNav._items[visualIndex];
                          final labelScale =
                              _labelBounceController.value.clamp(0.82, 1.12);

                          return GlassLens(
                            totalWidth: pillWidth,
                            height: lensHeight,
                            leaderRect: leaderRect,
                            followerRect: followerRect,
                            childCenterX: leaderCenterX,
                            childWidth: lensWidth,
                            radius: 30,
                            stretchX: stretchX,
                            squashX: squashX,
                            specularOffset:
                                _hoveredIndex == widget.currentIndex
                                    ? _hoverParallax
                                    : lagOffset,
                            enableBackdropBlur: widget.enableBackdropBlur,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Transform.scale(
                                scale: labelScale,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OrbitNavIcon(
                                      tab: activeItem.$1,
                                      active: true,
                                      color: OrbitTokens.textPrimary,
                                      size: 23,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      activeItem.$2,
                                      style: OrbitTypography.nav.copyWith(
                                        color: OrbitTokens.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
            ),
          );
        },
      ),
    );
  }
}
