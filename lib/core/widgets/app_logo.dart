import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable App Logo: Renders the authentic original Not To Do shield mark
/// from `assets/stitch/06_logo_transparent.png` with crisp image scaling
/// and graceful vector fallback.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/stitch/06_logo_transparent.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => _buildVectorFallback(customColors),
      ),
    );
  }

  Widget _buildVectorFallback(AppCustomColors customColors) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ShieldSlashMarkPainter(
        shieldColor: customColors.primaryAccent,
        slashColor: customColors.antiHabit,
      ),
    );
  }
}

/// Fallback painter for the shield outline with diagonal slash.
class _ShieldSlashMarkPainter extends CustomPainter {
  final Color shieldColor;
  final Color slashColor;

  const _ShieldSlashMarkPainter({
    required this.shieldColor,
    required this.slashColor,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final scale = canvasSize.shortestSide / 100;
    canvas.scale(scale, scale);
    const stroke = 7.0;

    final shield = Path()
      ..moveTo(18, 18)
      ..quadraticBezierTo(50, 4, 82, 18)
      ..lineTo(82, 50)
      ..quadraticBezierTo(82, 76, 50, 92)
      ..quadraticBezierTo(18, 76, 18, 50)
      ..close();

    final shieldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = shieldColor;

    canvas.drawPath(shield, shieldPaint);

    final slashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = slashColor;

    canvas.drawLine(const Offset(63, 36), const Offset(37, 64), slashPaint);
  }

  @override
  bool shouldRepaint(covariant _ShieldSlashMarkPainter oldDelegate) {
    return oldDelegate.shieldColor != shieldColor ||
        oldDelegate.slashColor != slashColor;
  }
}
