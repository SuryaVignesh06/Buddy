import 'package:flutter/material.dart';

enum OrbitNavTab { home, search, library, create }

/// Custom-painted 24 px nav icons (1.8 px outlined when inactive, filled when active).
class OrbitNavIcon extends StatelessWidget {
  const OrbitNavIcon({
    super.key,
    required this.tab,
    required this.active,
    required this.color,
    this.size = 24.0,
  });

  final OrbitNavTab tab;
  final bool active;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _NavIconPainter(
          tab: tab,
          active: active,
          color: color,
        ),
      ),
    );
  }
}

class _NavIconPainter extends CustomPainter {
  const _NavIconPainter({
    required this.tab,
    required this.active,
    required this.color,
  });

  final OrbitNavTab tab;
  final bool active;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (tab) {
      case OrbitNavTab.home:
        final path = Path()
          ..moveTo(s * 0.14, s * 0.45)
          ..lineTo(s * 0.50, s * 0.14)
          ..lineTo(s * 0.86, s * 0.45)
          ..lineTo(s * 0.86, s * 0.83)
          ..quadraticBezierTo(s * 0.86, s * 0.88, s * 0.80, s * 0.88)
          ..lineTo(s * 0.60, s * 0.88)
          ..lineTo(s * 0.60, s * 0.62)
          ..quadraticBezierTo(s * 0.60, s * 0.56, s * 0.54, s * 0.56)
          ..lineTo(s * 0.46, s * 0.56)
          ..quadraticBezierTo(s * 0.40, s * 0.56, s * 0.40, s * 0.62)
          ..lineTo(s * 0.40, s * 0.88)
          ..lineTo(s * 0.20, s * 0.88)
          ..quadraticBezierTo(s * 0.14, s * 0.88, s * 0.14, s * 0.83)
          ..close();
        if (active) {
          canvas.drawPath(path, fillPaint);
        } else {
          canvas.drawPath(path, strokePaint);
        }
        break;

      case OrbitNavTab.search:
        final center = Offset(s * 0.44, s * 0.44);
        final r = s * 0.27;
        if (active) {
          canvas.drawCircle(
            center,
            r,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.6,
          );
          canvas.drawCircle(
            center,
            r * 0.55,
            Paint()..color = color.withValues(alpha: 0.25),
          );
          canvas.drawLine(
            Offset(s * 0.64, s * 0.64),
            Offset(s * 0.86, s * 0.86),
            Paint()
              ..color = color
              ..strokeWidth = 2.6
              ..strokeCap = StrokeCap.round,
          );
        } else {
          canvas.drawCircle(center, r, strokePaint);
          canvas.drawLine(
            Offset(s * 0.64, s * 0.64),
            Offset(s * 0.86, s * 0.86),
            strokePaint,
          );
        }
        break;

      case OrbitNavTab.library:
        // Three vertical music stacks (one tilted like a leaning record)
        final r1 = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.16, s * 0.18, s * 0.16, s * 0.66),
          Radius.circular(s * 0.04),
        );
        final r2 = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.40, s * 0.18, s * 0.16, s * 0.66),
          Radius.circular(s * 0.04),
        );
        if (active) {
          canvas.drawRRect(r1, fillPaint);
          canvas.drawRRect(r2, fillPaint);
        } else {
          canvas.drawRRect(r1, strokePaint);
          canvas.drawRRect(r2, strokePaint);
        }
        canvas.save();
        canvas.translate(s * 0.72, s * 0.52);
        canvas.rotate(-0.22);
        final r3 = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: s * 0.16,
            height: s * 0.64,
          ),
          Radius.circular(s * 0.04),
        );
        canvas.drawRRect(r3, active ? fillPaint : strokePaint);
        canvas.restore();
        break;

      case OrbitNavTab.create:
        final center = Offset(s * 0.50, s * 0.50);
        final outer = s * 0.36;
        if (active) {
          canvas.drawCircle(center, outer, fillPaint);
          final cutPaint = Paint()
            ..color = const Color(0xFF0E0E0E)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            Offset(s * 0.50, s * 0.32),
            Offset(s * 0.50, s * 0.68),
            cutPaint,
          );
          canvas.drawLine(
            Offset(s * 0.32, s * 0.50),
            Offset(s * 0.68, s * 0.50),
            cutPaint,
          );
        } else {
          canvas.drawCircle(center, outer, strokePaint);
          canvas.drawLine(
            Offset(s * 0.50, s * 0.34),
            Offset(s * 0.50, s * 0.66),
            strokePaint,
          );
          canvas.drawLine(
            Offset(s * 0.34, s * 0.50),
            Offset(s * 0.66, s * 0.50),
            strokePaint,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter oldDelegate) {
    return oldDelegate.tab != tab ||
        oldDelegate.active != active ||
        oldDelegate.color != color;
  }
}
