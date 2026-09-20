import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// Reusable App Logo with automatic fallback safety.
/// Tries SVG first, then PNG, and finally a pure Flutter vector shield icon fallback.
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
      child: SvgPicture.asset(
        'assets/stitch/06_logo_transparent.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (ctx) => Image.asset(
          'assets/stitch/06_logo_transparent.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallback(context, customColors),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, AppCustomColors customColors) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: customColors.primaryAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(
          color: customColors.primaryAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.shield,
          size: size * 0.6,
          color: customColors.primaryAccent,
        ),
      ),
    );
  }
}
