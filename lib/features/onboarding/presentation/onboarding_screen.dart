import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/providers/routine_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';
import '../../navigation/main_scaffold.dart';

/// 90-Second Onboarding Commitment Flow.
///
/// A sleek 4-page PageView that introduces the app's value proposition,
/// asks the user to identify their "main battle", and writes
/// `hasCompletedOnboarding: true` to the Hive settings box before
/// navigating to the main dashboard.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 4;

  /// The user's selected "main battle" index. -1 means none selected.
  int _selectedBattle = -1;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon: Icons.shield_outlined,
      title: 'Stop what hurts you',
      subtitle:
          'Most productivity apps tell you what to do.\n'
          'This one protects you from what you shouldn\'t.',
    ),
    _OnboardingPageData(
      icon: Icons.calendar_view_week_outlined,
      title: 'Your routine, protected',
      subtitle:
          'Scan your class timetable, import your schedule,\n'
          'and let the engine guard your focus blocks.',
    ),
    _OnboardingPageData(
      icon: Icons.auto_awesome_outlined,
      title: 'AI-powered defense',
      subtitle:
          'Bring your own Gemini API key.\n'
          'The AI Guard analyzes gaps and suggests shields.',
    ),
    // Page 4 is the "battle picker" — rendered separately
    _OnboardingPageData(
      icon: Icons.local_fire_department_outlined,
      title: 'What\'s your main battle?',
      subtitle: 'Pick the habit you want to break first.\nYou can always change this later.',
    ),
  ];

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();

    // Write flag to Hive settings box
    final settingsBox = Hive.box('settings_box');
    await settingsBox.put('hasCompletedOnboarding', true);

    // Invalidate the provider so bootstrap picks up the change
    ref.invalidate(hasCompletedOnboardingProvider);

    if (!mounted) return;

    // Navigate to main scaffold, replacing the entire navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScaffold(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  const AppLogo(size: 28),
                  // Skip
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: customColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView body
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  if (index == _totalPages - 1) {
                    return _buildBattlePickerPage(customColors, theme);
                  }
                  return _buildInfoPage(_pages[index], customColors, theme);
                },
              ),
            ),

            // Bottom controls: page indicator + next button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? customColors.primaryAccent
                              : customColors.chipInactiveBg,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: (_currentPage == _totalPages - 1 && _selectedBattle == -1)
                          ? null
                          : _nextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: customColors.primaryAccent,
                        foregroundColor: theme.colorScheme.onPrimary,
                        disabledBackgroundColor:
                            customColors.chipInactiveBg,
                        disabledForegroundColor:
                            customColors.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a standard informational onboarding page.
  Widget _buildInfoPage(
    _OnboardingPageData data,
    AppCustomColors customColors,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Icon container
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: customColors.primaryAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: customColors.primaryAccent.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              data.icon,
              size: 40,
              color: customColors.primaryAccent,
            ),
          ),
          const SizedBox(height: 36),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.3,
              color: customColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: customColors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  /// Builds the final "battle picker" page with selectable chip options.
  Widget _buildBattlePickerPage(
    AppCustomColors customColors,
    ThemeData theme,
  ) {
    final battles = [
      (icon: Icons.phone_android, label: 'Doomscrolling / Social Media'),
      (icon: Icons.videogame_asset_outlined, label: 'Gaming during study hours'),
      (icon: Icons.nights_stay_outlined, label: 'Sleeping past alarm'),
      (icon: Icons.fastfood_outlined, label: 'Junk food / energy drinks'),
      (icon: Icons.chat_bubble_outline, label: 'Procrastination / overthinking'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: customColors.antiHabit.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: customColors.antiHabit.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.local_fire_department_outlined,
              size: 40,
              color: customColors.antiHabit,
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'What\'s your main battle?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.3,
              color: customColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick the habit you want to break first.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: customColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),

          // Battle options
          ...List.generate(battles.length, (i) {
            final battle = battles[i];
            final isSelected = _selectedBattle == i;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedBattle = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? customColors.antiHabit.withValues(alpha: 0.10)
                        : customColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? customColors.antiHabit.withValues(alpha: 0.5)
                          : customColors.cardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        battle.icon,
                        size: 20,
                        color: isSelected
                            ? customColors.antiHabit
                            : customColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          battle.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? customColors.textPrimary
                                : customColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? customColors.antiHabit
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? customColors.antiHabit
                                : customColors.cardBorder,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Internal data class for onboarding page content.
class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
