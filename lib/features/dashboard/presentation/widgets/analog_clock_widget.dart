import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

/// Minimalist Analog & Digital Chronometer Widget.
/// Displays a live ticking analog dial with hour/minute/second hands
/// alongside digital timestamp and date readouts.
class AnalogClockWidget extends StatefulWidget {
  final double size;

  const AnalogClockWidget({
    super.key,
    this.size = 130,
  });

  @override
  State<AnalogClockWidget> createState() => _AnalogClockWidgetState();
}

class _AnalogClockWidgetState extends State<AnalogClockWidget> {
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);
    final dateStr = DateFormat('EEE MMM d').format(_currentTime);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Analog dial
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _AnalogClockPainter(
              time: _currentTime,
              dialColor: customColors.cardBackground,
              tickColor: customColors.textMuted.withValues(alpha: 0.4),
              majorTickColor: customColors.textSecondary,
              hourHandColor: customColors.textPrimary,
              minuteHandColor: customColors.textSecondary,
              secondHandColor: customColors.primaryAccent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Digital readout
        Text(
          timeStr,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 1.0,
            fontFamily: 'monospace',
            color: customColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dateStr,
          style: theme.textTheme.labelSmall?.copyWith(
            color: customColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final DateTime time;
  final Color dialColor;
  final Color tickColor;
  final Color majorTickColor;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;

  _AnalogClockPainter({
    required this.time,
    required this.dialColor,
    required this.tickColor,
    required this.majorTickColor,
    required this.hourHandColor,
    required this.minuteHandColor,
    required this.secondHandColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dial background
    final bgPaint = Paint()
      ..color = dialColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Border ring
    final borderPaint = Paint()
      ..color = tickColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 1, borderPaint);

    // Ticks (12 hours)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final isMajor = i % 3 == 0;
      final tickLength = isMajor ? 6.0 : 3.5;
      final tickPaint = Paint()
        ..color = isMajor ? majorTickColor : tickColor
        ..strokeWidth = isMajor ? 1.5 : 1.0;

      final p1 = Offset(
        center.dx + (radius - 6) * math.cos(angle),
        center.dy + (radius - 6) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 6 - tickLength) * math.cos(angle),
        center.dy + (radius - 6 - tickLength) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Hour hand
    final hourAngle =
        ((time.hour % 12 + time.minute / 60.0) * 30 - 90) * math.pi / 180;
    final hourPaint = Paint()
      ..color = hourHandColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final hourEnd = Offset(
      center.dx + (radius * 0.48) * math.cos(hourAngle),
      center.dy + (radius * 0.48) * math.sin(hourAngle),
    );
    canvas.drawLine(center, hourEnd, hourPaint);

    // Minute hand
    final minuteAngle =
        ((time.minute + time.second / 60.0) * 6 - 90) * math.pi / 180;
    final minutePaint = Paint()
      ..color = minuteHandColor
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final minuteEnd = Offset(
      center.dx + (radius * 0.70) * math.cos(minuteAngle),
      center.dy + (radius * 0.70) * math.sin(minuteAngle),
    );
    canvas.drawLine(center, minuteEnd, minutePaint);

    // Second hand
    final secondAngle = (time.second * 6 - 90) * math.pi / 180;
    final secondPaint = Paint()
      ..color = secondHandColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final secondEnd = Offset(
      center.dx + (radius * 0.78) * math.cos(secondAngle),
      center.dy + (radius * 0.78) * math.sin(secondAngle),
    );
    canvas.drawLine(center, secondEnd, secondPaint);

    // Center pivot dot
    final pivotPaint = Paint()
      ..color = secondHandColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) {
    return oldDelegate.time.second != time.second;
  }
}
