import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A reusable Bento-style empty state card.
///
/// Displays an icon, title, subtitle, and an optional CTA button inside a
/// tactile 1px-bordered card using [AppCustomColors] semantic tokens.
/// Drop this into any screen's body when its Riverpod provider returns [].
class BentoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  const BentoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: customColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container with soft accent background
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: customColors.primaryAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: customColors.primaryAccent.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: customColors.primaryAccent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: customColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: customColors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          // Optional CTA button
          if (ctaLabel != null && onCtaTap != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: onCtaTap,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  ctaLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: customColors.primaryAccent,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
