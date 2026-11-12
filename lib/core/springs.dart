import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Physics-based spring constants and motion helpers for Orbit v2.
/// All interactive animations use real SpringSimulations rather than linear curves.
abstract final class Springs {
  /// Juicy overshoot (~14%): releases, sheet settles, backdrop rebounds.
  static const SpringDescription liquid = SpringDescription(
    mass: 1.0,
    stiffness: 220.0,
    damping: 16.0,
  );

  /// Playful pops: card/list entries, heart likes, play/pause artwork scale.
  static const SpringDescription bouncy = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 20.0,
  );

  /// Quick, small overshoot: press down, quick snaps, chip transitions.
  static const SpringDescription snappy = SpringDescription(
    mass: 1.0,
    stiffness: 420.0,
    damping: 30.0,
  );

  /// Critically damped, no bounce: route content reveals, smooth settles.
  static const SpringDescription smooth = SpringDescription(
    mass: 1.0,
    stiffness: 260.0,
    damping: 32.0,
  );

  static final Tolerance defaultTolerance = Tolerance(
    velocity: 0.001,
    distance: 0.001,
  );

  static SpringSimulation simulate(
    SpringDescription description, {
    required double start,
    required double end,
    double velocity = 0.0,
  }) {
    return SpringSimulation(
      description,
      start,
      end,
      velocity,
      tolerance: defaultTolerance,
    );
  }
}

/// Staggered spring entrance for list and grid items:
/// starts at scale 0.9, y +24, opacity 0, then settles with [Springs.bouncy].
/// Stagger is 45 ms per item, capped at 12 items.
class SpringEntrance extends StatefulWidget {
  const SpringEntrance({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItem = const Duration(milliseconds: 45),
    this.maxStaggerItems = 12,
  });

  final int index;
  final Widget child;
  final Duration delayPerItem;
  final int maxStaggerItems;

  @override
  State<SpringEntrance> createState() => _SpringEntranceState();
}

class _SpringEntranceState extends State<SpringEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this, value: 0.0);
    final capped = widget.index.clamp(0, widget.maxStaggerItems);
    final delay = widget.delayPerItem * capped;
    if (delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    } else {
      _delayTimer = Timer(delay, () {
        if (mounted) _start();
      });
    }
  }

  void _start() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
      return;
    }
    _controller.animateWith(
      Springs.simulate(Springs.bouncy, start: 0.0, end: 1.0),
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final v = _controller.value;
        final opacity = v.clamp(0.0, 1.0);
        final scale = 0.9 + 0.1 * v;
        final dy = 24.0 * (1.0 - v);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
