import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/providers/routine_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';

class DailyEnergyGauge extends ConsumerWidget {
  const DailyEnergyGauge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(filteredTimelineProvider);
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    // Compute total energy balance
    int totalDrain = 0;
    int totalRecharge = 0;
    
    for (final block in blocks) {
      if (block.energyCost < 0) {
        totalDrain += block.energyCost.abs();
      } else {
        totalRecharge += block.energyCost;
      }
    }

    final netEnergy = totalRecharge - totalDrain;
    
    final settings = Hive.box('settings_box');
    final maxDrain = settings.get('maxDailyEnergy', defaultValue: 20.0).toDouble();
    final burnoutThreshold = settings.get('burnoutThreshold', defaultValue: -10.0).toDouble();
    final warningThreshold = burnoutThreshold / 2; // Automatically scale warning based on burnout

    // Determine status color based on drain
    Color statusColor;
    String statusText;
    
    if (netEnergy < burnoutThreshold) {
      statusColor = customColors.antiHabit;
      statusText = 'Burnout Risk: High Drain';
    } else if (netEnergy < warningThreshold) {
      statusColor = customColors.warning;
      statusText = 'Energy Deficit: Need Rest';
    } else {
      statusColor = customColors.success;
      statusText = 'Energy Balanced';
    }

    // Progress bar math (clamped 0.0 to 1.0)
    final fillPercentage = (totalDrain / maxDrain).clamp(0.0, 1.0);

    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Energy Budget',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: customColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Custom Gradient Bar
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: customColors.canvasBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: customColors.cardBorder),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fillPercentage,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      customColors.success,
                      if (fillPercentage > 0.5) customColors.warning,
                      if (fillPercentage > 0.8) customColors.antiHabit,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '-$totalDrain Drain',
                style: theme.textTheme.labelMedium?.copyWith(color: customColors.textPrimary),
              ),
              Text(
                '+$totalRecharge Recharge',
                style: theme.textTheme.labelMedium?.copyWith(color: customColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
