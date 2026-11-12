import 'package:flutter/material.dart';

import '../core/haptics.dart';
import '../core/springs.dart';
import '../core/tokens.dart';
import '../core/typography.dart';
import 'glass_lens.dart';

/// Horizontal filter chips:
/// - Idle = Tier B glass fill & rim
/// - Selected = liquid gradient pill (flameRed -> orange) with outer glow
/// - Selection pill slides & stretches between chips using a leader/follower metaball.
class FilterChips extends StatefulWidget {
  const FilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(
      horizontal: OrbitTokens.screenPadding,
    ),
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsets padding;

  @override
  State<FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<FilterChips>
    with TickerProviderStateMixin {
  final GlobalKey _rowKey = GlobalKey();
  late List<GlobalKey> _chipKeys;
  late List<Rect?> _rects;

  late final AnimationController _leaderController;
  late final AnimationController _followerController;

  @override
  void initState() {
    super.initState();
    _chipKeys = List.generate(widget.labels.length, (_) => GlobalKey());
    _rects = List<Rect?>.filled(widget.labels.length, null);

    final idx = widget.selectedIndex.toDouble();
    _leaderController = AnimationController.unbounded(vsync: this, value: idx);
    _followerController = AnimationController.unbounded(vsync: this, value: idx);

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAll());
  }

  @override
  void didUpdateWidget(covariant FilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length) {
      _chipKeys = List.generate(widget.labels.length, (_) => GlobalKey());
      _rects = List<Rect?>.filled(widget.labels.length, null);
    }
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animateToIndex(widget.selectedIndex);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAll());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAll());
  }

  void _animateToIndex(int index) {
    final target = index.toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _leaderController.value = target;
      _followerController.value = target;
      return;
    }
    _leaderController.animateWith(
      Springs.simulate(
        Springs.snappy,
        start: _leaderController.value,
        end: target,
      ),
    );
    _followerController.animateWith(
      Springs.simulate(
        Springs.liquid,
        start: _followerController.value,
        end: target,
      ),
    );
  }

  void _measureAll() {
    if (!mounted) return;
    final rowBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (rowBox == null || !rowBox.hasSize) return;

    var changed = false;
    final next = List<Rect?>.filled(widget.labels.length, null);
    for (var i = 0; i < _chipKeys.length; i++) {
      final box = _chipKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final offset = box.localToGlobal(Offset.zero, ancestor: rowBox);
      next[i] = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        box.size.width,
        box.size.height,
      );
      if (next[i] != _rects[i]) changed = true;
    }
    if (changed) {
      setState(() => _rects = next);
    }
  }

  Rect _sampleRect(double pos) {
    if (_rects.isEmpty) return Rect.zero;
    final clamped = pos.clamp(0.0, (_rects.length - 1).toDouble());
    final lo = clamped.floor();
    final hi = clamped.ceil();
    final rLo = _rects[lo];
    final rHi = _rects[hi];
    if (rLo == null && rHi == null) return Rect.zero;
    if (rLo == null) return rHi!;
    if (rHi == null) return rLo;
    final frac = clamped - lo;
    return Rect.lerp(rLo, rHi, frac)!;
  }

  @override
  void dispose() {
    _leaderController.dispose();
    _followerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMeasured = _rects.every((r) => r != null);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: widget.padding,
      child: Stack(
        key: _rowKey,
        clipBehavior: Clip.none,
        children: [
          // Sliding & stretching liquid metaball pill rendered BEHIND the single chip Row
          if (hasMeasured)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation:
                      Listenable.merge([_leaderController, _followerController]),
                  builder: (context, _) {
                    final leader = _sampleRect(_leaderController.value);
                    final follower = _sampleRect(_followerController.value);
                    if (leader == Rect.zero) return const SizedBox.shrink();
                    final slimFollower = Rect.fromCenter(
                      center: follower.center,
                      width: follower.width * 0.84,
                      height: follower.height * 0.88,
                    );
                    final path = buildMetaballPath(
                      leader: leader,
                      follower: slimFollower,
                      radius: 17,
                    );
                    return CustomPaint(
                      painter: _LiquidChipPillPainter(path),
                    );
                  },
                ),
              ),
            ),

          // Single Row of chips guaranteeing exact centered label alignment
          Row(
            children: List.generate(widget.labels.length, (i) {
              final selected = i == widget.selectedIndex;
              final showStaticSelected = !hasMeasured && selected;
              final hideIdleFill = hasMeasured && selected;

              return Padding(
                padding: EdgeInsets.only(
                  right: i == widget.labels.length - 1 ? 0 : OrbitTokens.space8,
                ),
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: '${widget.labels[i]} filter',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      OrbitHaptics.selection();
                      widget.onSelected(i);
                    },
                    child: SizedBox(
                      height: OrbitTokens.minTouchTarget,
                      child: Center(
                        child: Container(
                          key: _chipKeys[i],
                          height: 34,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(OrbitTokens.radiusChip),
                            gradient: showStaticSelected
                                ? const LinearGradient(
                                    colors: [
                                      OrbitTokens.flameRed,
                                      OrbitTokens.orange,
                                    ],
                                  )
                                : hideIdleFill
                                    ? null
                                    : LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.14),
                                          Colors.white.withValues(alpha: 0.04),
                                        ],
                                      ),
                            border: Border.all(
                              color: showStaticSelected
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : hideIdleFill
                                      ? Colors.transparent
                                      : Colors.white.withValues(alpha: 0.24),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            widget.labels[i],
                            style: OrbitTypography.chip.copyWith(
                              color: OrbitTokens.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LiquidChipPillPainter extends CustomPainter {
  _LiquidChipPillPainter(this.path);

  final Path path;

  final Paint _glowPaint = Paint()
    ..color = OrbitTokens.flameRed.withValues(alpha: 0.45)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  final Paint _fillPaint = Paint();
  final Paint _rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = Colors.white.withValues(alpha: 0.45);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = path.getBounds();
    if (bounds.isEmpty) return;

    canvas.drawPath(path, _glowPaint);

    _fillPaint.shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [OrbitTokens.flameRed, OrbitTokens.orange],
    ).createShader(bounds);
    canvas.drawPath(path, _fillPaint);
    canvas.drawPath(path, _rimPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidChipPillPainter oldDelegate) => true;
}
