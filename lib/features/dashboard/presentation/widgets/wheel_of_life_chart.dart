import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Wheel of Life Radar Chart Widget.
/// Renders a 6-axis polygonal radar chart displaying life balance scores:
/// Career, Health, Social, Physical Health, Money, Family.
class WheelOfLifeChart extends StatelessWidget {
  final Map<String, double> scores;
  final double size;

  const WheelOfLifeChart({
    super.key,
    this.scores = const {
      'Career': 8.5,
      'Health': 7.0,
      'Social': 6.0,
      'Physical Health': 7.5,
      'Money': 5.5,
      'Family': 8.0,
    },
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: customColors.cardBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wheel of Life',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: customColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: customColors.primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Score: 7.1/10',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: customColors.primaryAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RadarChartPainter(
                data: scores,
                gridColor: customColors.textMuted.withValues(alpha: 0.25),
                axisColor: customColors.textMuted.withValues(alpha: 0.35),
                polygonColor: const Color(0xFFF43F5E).withValues(alpha: 0.28),
                polygonStrokeColor: const Color(0xFFF43F5E),
                labelColor: customColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star,
                size: 11,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 4),
              Text(
                'Powered by ChartBase',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: customColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Color gridColor;
  final Color axisColor;
  final Color polygonColor;
  final Color polygonStrokeColor;
  final Color labelColor;

  _RadarChartPainter({
    required this.data,
    required this.gridColor,
    required this.axisColor,
    required this.polygonColor,
    required this.polygonStrokeColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width / 2) - 28;
    final keys = data.keys.toList();
    final count = keys.length;
    if (count < 3) return;

    final angleStep = 2 * math.pi / count;

    // Draw concentric polygon rings (scale 2, 4, 6, 8, 10)
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int level = 2; level <= 10; level += 2) {
      final r = maxRadius * (level / 10.0);
      final path = Path();
      for (int i = 0; i < count; i++) {
        final angle = (i * angleStep) - (math.pi / 2);
        final pt = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes & labels
    final axisPaint = Paint()
      ..color = axisColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < count; i++) {
      final angle = (i * angleStep) - (math.pi / 2);
      final edge = Offset(
        center.dx + maxRadius * math.cos(angle),
        center.dy + maxRadius * math.sin(angle),
      );
      canvas.drawLine(center, edge, axisPaint);

      // Label text
      final label = keys[i];
      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRadius = maxRadius + 14;
      final labelOffset = Offset(
        center.dx + labelRadius * math.cos(angle) - (textPainter.width / 2),
        center.dy + labelRadius * math.sin(angle) - (textPainter.height / 2),
      );
      textPainter.paint(canvas, labelOffset);
    }

    // Draw data polygon
    final polyPath = Path();
    final polyFillPaint = Paint()
      ..color = polygonColor
      ..style = PaintingStyle.fill;
    final polyStrokePaint = Paint()
      ..color = polygonStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = polygonStrokeColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final score = (data[keys[i]] ?? 5.0).clamp(0.0, 10.0);
      final r = maxRadius * (score / 10.0);
      final angle = (i * angleStep) - (math.pi / 2);
      final pt = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );

      if (i == 0) {
        polyPath.moveTo(pt.dx, pt.dy);
      } else {
        polyPath.lineTo(pt.dx, pt.dy);
      }
    }
    polyPath.close();

    canvas.drawPath(polyPath, polyFillPaint);
    canvas.drawPath(polyPath, polyStrokePaint);

    // Draw node dots
    for (int i = 0; i < count; i++) {
      final score = (data[keys[i]] ?? 5.0).clamp(0.0, 10.0);
      final r = maxRadius * (score / 10.0);
      final angle = (i * angleStep) - (math.pi / 2);
      final pt = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      canvas.drawCircle(pt, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
