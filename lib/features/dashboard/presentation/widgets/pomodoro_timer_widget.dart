import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum PomodoroMode {
  pomodoro,
  shortBreak,
  longBreak,
}

/// Pomodoro Focus Station Widget.
/// Features 25:00 focus intervals, short/long breaks, start/pause/reset controls,
/// and study streak counters.
class PomodoroTimerWidget extends StatefulWidget {
  final VoidCallback? onSettingsPressed;

  const PomodoroTimerWidget({
    super.key,
    this.onSettingsPressed,
  });

  @override
  State<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends State<PomodoroTimerWidget> {
  PomodoroMode _currentMode = PomodoroMode.pomodoro;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  int _completedSessions = 4;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _switchMode(PomodoroMode mode) {
    _timer?.cancel();
    setState(() {
      _currentMode = mode;
      _isRunning = false;
      switch (mode) {
        case PomodoroMode.pomodoro:
          _secondsRemaining = 25 * 60;
          break;
        case PomodoroMode.shortBreak:
          _secondsRemaining = 5 * 60;
          break;
        case PomodoroMode.longBreak:
          _secondsRemaining = 15 * 60;
          break;
      }
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          timer.cancel();
          setState(() {
            _isRunning = false;
            if (_currentMode == PomodoroMode.pomodoro) {
              _completedSessions++;
            }
          });
        }
      });
    }
  }

  void _resetTimer() {
    _switchMode(_currentMode);
  }

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: customColors.cardBorder, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            customColors.cardBackground,
            const Color(0xFF131720),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mode Switcher Tabs
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0D12),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: customColors.cardBorder, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTab('Pomodoro', PomodoroMode.pomodoro),
                _buildModeTab('Short Break', PomodoroMode.shortBreak),
                _buildModeTab('Long Break', PomodoroMode.longBreak),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Big Glowing Countdown Readout
          Text(
            '$minutes:$seconds',
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              letterSpacing: 2.0,
              color: _isRunning
                  ? customColors.primaryAccent
                  : customColors.textPrimary,
              shadows: _isRunning
                  ? [
                      Shadow(
                        color: customColors.primaryAccent.withValues(alpha: 0.4),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Control Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Start / Pause pill button
              InkWell(
                onTap: _toggleTimer,
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isRunning
                        ? const Color(0xFFF59E0B)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRunning
                                ? const Color(0xFFF59E0B)
                                : Colors.white)
                            .withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        size: 16,
                        color: const Color(0xFF0E1015),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isRunning ? 'Pause' : 'Start',
                        style: const TextStyle(
                          color: Color(0xFF0E1015),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Reset Button
              IconButton(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh, size: 20),
                color: customColors.textSecondary,
                tooltip: 'Reset Timer',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0B0D12),
                  side: BorderSide(color: customColors.cardBorder, width: 0.8),
                ),
              ),

              // Settings Button
              IconButton(
                onPressed: widget.onSettingsPressed,
                icon: const Icon(Icons.settings_outlined, size: 19),
                color: customColors.textSecondary,
                tooltip: 'Timer Settings',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0B0D12),
                  side: BorderSide(color: customColors.cardBorder, width: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Completed Session Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                '$_completedSessions Pomodoros finished today (${_completedSessions * 25}m protected)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: customColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, PomodoroMode mode) {
    final customColors = AppColors.of(context);
    final isSelected = _currentMode == mode;

    return InkWell(
      onTap: () => _switchMode(mode),
      borderRadius: BorderRadius.circular(9999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (mode == PomodoroMode.pomodoro
                  ? customColors.primaryAccent.withValues(alpha: 0.22)
                  : const Color(0xFF38BDF8).withValues(alpha: 0.22))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          border: isSelected
              ? Border.all(
                  color: mode == PomodoroMode.pomodoro
                      ? customColors.primaryAccent
                      : const Color(0xFF38BDF8),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? customColors.textPrimary
                : customColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
