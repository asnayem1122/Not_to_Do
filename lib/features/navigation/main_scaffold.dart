import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../habits/presentation/habit_protection_screen.dart';
import '../sync_ai_guard/presentation/sync_ai_guard_modal.dart';
import '../timetable/presentation/class_timetable_screen.dart';
import '../today/presentation/today_timeline_screen.dart';

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
      const TodayTimelineScreen(),
      ClassTimetableScreen(
        onNavigateToVault: () {
          setState(() => _currentIndex = 2);
        },
      ),
      const HabitProtectionScreen(),
      const SyncAiGuardModal(isBottomSheet: false),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: customColors.cardBackground.withOpacity(0.95),
          border: Border(
            top: BorderSide(
              color: customColors.cardBorder.withOpacity(0.6),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.schedule,
                  label: 'Today',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.calendar_view_week,
                  label: 'Routine',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: Icons.shield,
                  label: 'Not To Do',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.smart_toy_outlined,
                  label: 'AI Guard',
                  isSelected: _currentIndex == 3,
                  onTap: () {
                    // Also trigger bottom sheet modal for authentic modal interaction
                    SyncAiGuardModal.show(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    final color = isSelected
        ? customColors.primaryAccent
        : customColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
