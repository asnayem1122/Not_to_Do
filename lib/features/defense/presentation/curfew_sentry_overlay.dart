import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';

/// A defensive overlay that locks the app between 22:30 and 04:00.
/// Requires a 3-second continuous long-press to bypass, breaking mindless
/// late-night dopamine loops.
class CurfewSentryOverlay extends StatefulWidget {
  final Widget child;

  const CurfewSentryOverlay({super.key, required this.child});

  @override
  State<CurfewSentryOverlay> createState() => _CurfewSentryOverlayState();

  static bool isCurfewLocked(int currentMins, int startMins, int endMins) {
    if (startMins > endMins) {
      // Crosses midnight
      return currentMins >= startMins || currentMins <= endMins;
    } else {
      // Same day
      return currentMins >= startMins && currentMins <= endMins;
    }
  }
}

class _CurfewSentryOverlayState extends State<CurfewSentryOverlay> with SingleTickerProviderStateMixin {
  late Timer _timeCheckTimer;
  bool _isCurfewActive = false;
  bool _isBypassed = false;
  
  // Long-press unlock mechanics
  double _unlockProgress = 0.0;
  Timer? _unlockTimer;
  static const int _requiredUnlockMs = 3000;
  static const int _tickMs = 50;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkCurfew();
    
    // Check time every minute to auto-lock/unlock
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkCurfew());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timeCheckTimer.cancel();
    _unlockTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkCurfew() {
    if (_isBypassed) return;
    
    final settingsBox = Hive.box('settings_box');
    final bool isCurfewEnabled = settingsBox.get('curfewEnabled', defaultValue: true);
    
    if (!isCurfewEnabled) {
      if (_isCurfewActive) {
        setState(() => _isCurfewActive = false);
      }
      return;
    }

    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    
    final int startMins = settingsBox.get('curfewStartMins', defaultValue: 1350);
    final int endMins = settingsBox.get('curfewEndMins', defaultValue: 240);
    
    bool isLocked = CurfewSentryOverlay.isCurfewLocked(minutesSinceMidnight, startMins, endMins);
    
    if (isLocked != _isCurfewActive) {
      setState(() => _isCurfewActive = isLocked);
    }
  }



  void _startUnlock() {
    HapticFeedback.lightImpact();
    _unlockTimer?.cancel();
    _unlockTimer = Timer.periodic(const Duration(milliseconds: _tickMs), (timer) {
      setState(() {
        _unlockProgress += _tickMs / _requiredUnlockMs;
        if (_unlockProgress >= 1.0) {
          _unlockProgress = 1.0;
          timer.cancel();
          _triggerBypass();
        }
      });
    });
  }

  void _cancelUnlock() {
    _unlockTimer?.cancel();
    if (_unlockProgress < 1.0) {
      setState(() => _unlockProgress = 0.0);
    }
  }

  void _triggerBypass() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isBypassed = true;
      _isCurfewActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCurfewActive) return widget.child;

    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: customColors.canvasBackground,
      body: Stack(
        children: [
          // Background graphic
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: customColors.antiHabit.withValues(alpha: _pulseAnimation.value * 0.3),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nights_stay_rounded, size: 64, color: customColors.antiHabit),
                  const SizedBox(height: 32),
                  Text(
                    'Bedtime Boundary Locked',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: customColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'It is past 22:30. Continuing to use this device will degrade your focus tomorrow. Sleep cannot be rescheduled.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: customColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 64),
                  
                  // Hold to bypass button
                  GestureDetector(
                    onTapDown: (_) => _startUnlock(),
                    onTapUp: (_) => _cancelUnlock(),
                    onTapCancel: () => _cancelUnlock(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _unlockProgress,
                            strokeWidth: 4,
                            backgroundColor: customColors.cardBorder,
                            color: customColors.antiHabit,
                          ),
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: customColors.antiHabit.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: customColors.antiHabit.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(Icons.fingerprint, color: customColors.antiHabit),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Hold to bypass (Not Recommended)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: customColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
