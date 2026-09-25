import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/spring_bounce.dart';
import '../defense/presentation/curfew_sentry_overlay.dart';
import '../dashboard/presentation/student_life_os_screen.dart';
import '../habits/presentation/habit_protection_screen.dart';
import '../sync_ai_guard/presentation/sync_ai_guard_modal.dart';
import '../timetable/presentation/class_timetable_screen.dart';
import '../today/presentation/today_timeline_screen.dart';

/// Central student-hub scaffold with a floating glassmorphic pill dock.
///
/// Uses a [Stack] to overlay the pill dock on top of the [IndexedStack]
/// content area, giving the entire screen real estate to content while
/// the dock floats above with a blur-glass effect.
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);

    final screens = [
      StudentLifeOsScreen(
        onNavigateToToday: () => setState(() => _currentIndex = 1),
        onNavigateToRoutine: () => setState(() => _currentIndex = 2),
        onNavigateToVault: () => setState(() => _currentIndex = 3),
      ),
      const TodayTimelineScreen(),
      ClassTimetableScreen(
        onNavigateToVault: () {
          setState(() => _currentIndex = 3);
        },
      ),
      const HabitProtectionScreen(),
      const SyncAiGuardModal(isBottomSheet: false),
    ];

    return Scaffold(
      body: CurfewSentryOverlay(
        child: Stack(
          children: [
            // Full-bleed content area
            IndexedStack(
              index: _currentIndex,
              children: screens,
            ),

            // Floating Pill Dock — glassmorphic, positioned above bottom edge
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: customColors.cardBackground.withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: customColors.cardBorder.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDockItem(
                        context,
                        icon: Icons.timer_outlined,
                        activeIcon: Icons.timer,
                        label: 'Focus',
                        index: 0,
                      ),
                      _buildDockItem(
                        context,
                        icon: Icons.view_timeline_outlined,
                        activeIcon: Icons.view_timeline,
                        label: 'Timeline',
                        index: 1,
                      ),
                      _buildDockItem(
                        context,
                        icon: Icons.calendar_view_week_outlined,
                        activeIcon: Icons.calendar_view_week,
                        label: 'Routine',
                        index: 2,
                      ),
                      _buildDockItem(
                        context,
                        icon: Icons.shield_outlined,
                        activeIcon: Icons.shield,
                        label: 'Vault',
                        index: 3,
                      ),
                      _buildDockItem(
                        context,
                        icon: Icons.smart_toy_outlined,
                        activeIcon: Icons.smart_toy,
                        label: 'AI Guard',
                        index: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  /// Builds a single pill dock item.
  ///
  /// Active state: solid primaryAccent (Wasabi Glow) background pill
  /// with `colorScheme.onPrimary` icon. Inactive: transparent with
  /// textSecondary icon.
  Widget _buildDockItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;

    return SpringBounce(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      pressedScale: 0.90,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: isSelected ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 14 : 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Color.lerp(
                Colors.transparent,
                customColors.primaryAccent,
                t,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 21,
                  color: Color.lerp(
                    customColors.textSecondary,
                    theme.colorScheme.onPrimary,
                    t,
                  ),
                ),
                // Label slides in for active item
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 240),
                    alignment: Alignment.centerLeft,
                    widthFactor: isSelected ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
