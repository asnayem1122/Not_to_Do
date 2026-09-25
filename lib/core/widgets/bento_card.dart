import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'spring_bounce.dart';

/// A reusable, highly tactile Bento-style container.
/// Features a subtle 1px border, smooth 20px radius, and optional splash mechanics.
class BentoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Color? borderColor;

  const BentoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    
    final cardDecoration = BoxDecoration(
      color: backgroundColor ?? customColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor ?? customColors.cardBorder, 
        width: 1,
      ),
    );

    Widget cardContent = Container(
      padding: padding,
      decoration: cardDecoration,
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin,
        child: SpringBounce(
          onTap: onTap!,
          child: cardContent,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: cardContent,
    );
  }
}
