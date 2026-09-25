import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';

class BreathingShieldDialog extends StatefulWidget {
  final String title;
  final String warningText;
  final int durationSeconds;
  final VoidCallback onProceed;

  const BreathingShieldDialog({
    super.key,
    required this.title,
    required this.warningText,
    required this.durationSeconds,
    required this.onProceed,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String warningText,
    int durationSeconds = 15,
    required VoidCallback onProceed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BreathingShieldDialog(
        title: title,
        warningText: warningText,
        durationSeconds: durationSeconds,
        onProceed: onProceed,
      ),
    );
  }

  @override
  State<BreathingShieldDialog> createState() => _BreathingShieldDialogState();
}

class _BreathingShieldDialogState extends State<BreathingShieldDialog> with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _scaleAnimation;
  late int _secondsRemaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _secondsRemaining = widget.durationSeconds;

    final settingsBox = Hive.box('settings_box');
    final cycleSeconds = settingsBox.get('breathingCycleSeconds', defaultValue: 4);

    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: cycleSeconds),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          final settingsBox = Hive.box('settings_box');
          final cycleSeconds = settingsBox.get('breathingCycleSeconds', defaultValue: 4);
          if (_secondsRemaining % cycleSeconds == 0) HapticFeedback.lightImpact();
        } else {
          timer.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final isLocked = _secondsRemaining > 0;

    return Dialog(
      backgroundColor: customColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: customColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.warningText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: customColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 120,
              child: Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: customColors.primaryAccent.withValues(alpha: 0.15),
                          border: Border.all(
                            color: customColors.primaryAccent.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              isLocked ? 'Breathe... $_secondsRemaining' : 'You may proceed.',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isLocked ? customColors.primaryAccent : customColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Changed My Mind'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: isLocked ? null : () {
                  Navigator.of(context).pop();
                  widget.onProceed();
                },
                style: TextButton.styleFrom(
                  foregroundColor: customColors.antiHabitText,
                  disabledForegroundColor: customColors.textMuted.withValues(alpha: 0.3),
                ),
                child: Text(
                  'Break Shield',
                  style: TextStyle(
                    fontWeight: isLocked ? FontWeight.w500 : FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
