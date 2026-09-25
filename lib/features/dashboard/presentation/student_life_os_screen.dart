import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/routine_models.dart';
import '../../../core/providers/routine_providers.dart';
import '../../../core/services/api_key_service.dart';
import '../../../core/services/calendar_sync_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_settings_dialog.dart';
import '../../../core/widgets/app_logo.dart';
import '../../habits/presentation/widgets/add_habit_sheet.dart';
import '../../timetable/presentation/widgets/routine_import_modal.dart';
import '../../today/presentation/widgets/fix_my_day_sheet.dart';
import 'course_syllabus_drilldown_screen.dart';
import 'widgets/pomodoro_timer_widget.dart';

/// Focus OS Master Command Center Screen (formerly Student Life OS).
/// Implements the high-craft Executive Deep Work Protocol:
/// - Study Perimeter Hero with Telemetry Gauge Ring
/// - Quick Action Command Dock
/// - Linear Day Cadence Timeline Stream
/// - Opal-inspired Distraction Defense Vault
/// - Typography-first Course Workspace
class StudentLifeOsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToRoutine;
  final VoidCallback? onNavigateToVault;
  final VoidCallback? onNavigateToToday;

  const StudentLifeOsScreen({
    super.key,
    this.onNavigateToRoutine,
    this.onNavigateToVault,
    this.onNavigateToToday,
  });

  @override
  ConsumerState<StudentLifeOsScreen> createState() => _StudentLifeOsScreenState();
}

class _StudentLifeOsScreenState extends ConsumerState<StudentLifeOsScreen> {
  bool _isOptimizingDay = false;

  void _triggerDayOptimization() async {
    HapticFeedback.mediumImpact();
    setState(() => _isOptimizingDay = true);

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isOptimizingDay = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 8),
            Text(
              'Day Schedule Repaired & Gaps Protected',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF121826),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1E2638)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPomodoroModal(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.of(context).cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const PomodoroTimerWidget(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final heroClass = ref.watch(heroClassProvider);
    final syncSettings = ref.watch(syncSettingsProvider);
    final hasApiKey =
        ref.watch(geminiApiKeyProvider).valueOrNull?.isNotEmpty ?? false;
    final antiHabits = ref.watch(antiHabitsProvider);
    final enrolledCourses = ref.watch(academicEventsProvider);

    final nowFormatted = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: customColors.canvasBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ==========================================
            // 1. TOP APP BAR (FOCUS OS Brand & Status)
            // ==========================================
            _buildTopAppBar(
              context,
              isDark: isDark,
              hasApiKey: hasApiKey,
              isSynced: syncSettings.is2WayLiveSyncActive,
            ),

            // ==========================================
            // 2. SCROLLABLE FOCUS HUB CANVAS
            // ==========================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // A. EXECUTIVE FOCUS TELEMETRY HERO
                        _buildHeroFocusTelemetry(context, heroClass: heroClass),
                        const SizedBox(height: 14),

                        // B. QUICK COMMAND DOCK
                        _buildQuickCommandDock(context),
                        const SizedBox(height: 18),

                        // C. DAY CADENCE STREAM (Linear Timeline)
                        _buildDayCadenceSection(context, dateText: nowFormatted),
                        const SizedBox(height: 18),

                        // D. ANTI-HABIT DEFENSE VAULT (Opal-inspired)
                        _buildDefenseVaultSection(context, antiHabits: antiHabits),
                        const SizedBox(height: 18),

                        // E. COURSE WORKSPACE
                        _buildCourseWorkspaceSection(
                          context,
                          courses: enrolledCourses,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP APP BAR
  // ==========================================
  Widget _buildTopAppBar(
    BuildContext context, {
    required bool isDark,
    required bool hasApiKey,
    required bool isSynced,
  }) {
    final customColors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: customColors.canvasBackground.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: customColors.cardBorder.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Shield Logo Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF151B26)
                  : customColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: customColors.cardBorder.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: const Center(
              child: AppLogo(size: 22),
            ),
          ),
          const SizedBox(width: 10),

          // Brand Title + Pro Version Pill
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FOCUS OS',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                  color: customColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                      : const Color(0xFF006948).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                        : const Color(0xFF006948).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'v2.4 Pro',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isDark
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF006948),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Live G-Cal Synced Pill
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              final calService = ref.read(calendarSyncServiceProvider);
              final notifService = ref.read(notificationServiceProvider);
              final timelineNotifier = ref.read(timelineBlocksProvider.notifier);
              final academicNotifier = ref.read(academicEventsProvider.notifier);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing with Google Calendar...'),
                  duration: Duration(milliseconds: 900),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              final res = await ref.read(syncSettingsProvider.notifier).performTwoWaySync(
                    calService: calService,
                    notifService: notifService,
                    timelineNotifier: timelineNotifier,
                    academicNotifier: academicNotifier,
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Synced ${res.exportedCount} classes • ${res.importedBlocks.length} external events',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF121826)
                    : customColors.cardBackground,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: customColors.cardBorder.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSynced
                          ? const Color(0xFF10B981)
                          : customColors.textMuted,
                      boxShadow: isSynced
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isSynced ? 'Synced' : 'Offline',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: customColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Theme Toggle
          IconButton(
            tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(4),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 18,
              color: customColors.textSecondary,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),

          // Gemini Key Status Trigger
          IconButton(
            tooltip: hasApiKey ? 'Gemini AI Active' : 'Configure Gemini API Key',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(4),
            icon: Icon(
              hasApiKey ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              size: 18,
              color: hasApiKey
                  ? const Color(0xFF10B981)
                  : customColors.textSecondary,
            ),
            onPressed: () => ApiSettingsDialog.show(context),
          ),

          // Profile Avatar with Status Dot
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Alex Vance • CSE Major • Semester 4 (Executive Protocol Active)',
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: customColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: customColors.cardBorder),
                  ),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF6366F1).withValues(alpha: 0.5)
                          : customColors.primaryAccent.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    color: isDark
                        ? const Color(0xFF1C2230)
                        : customColors.cardBackground,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: isDark
                          ? const Color(0xFF818CF8)
                          : customColors.primaryAccent,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: customColors.canvasBackground,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HERO: EXECUTIVE FOCUS TELEMETRY
  // ==========================================
  Widget _buildHeroFocusTelemetry(
    BuildContext context, {
    required HeroClass heroClass,
  }) {
    final customColors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF121826).withValues(alpha: 0.85)
            : customColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : customColors.cardBorder,
          width: 1,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Perimeter Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.shield,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'STUDY PERIMETER ARMED',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFFF1F5F9) : customColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  heroClass.startsIn.isNotEmpty
                      ? (heroClass.startsIn.toLowerCase().startsWith('starts in ')
                          ? 'Next Anchor in ${heroClass.startsIn.substring(10)}'
                          : 'Next Anchor: ${heroClass.startsIn}')
                      : 'Next Anchor in 45m',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Telemetry Gauge & Academic Anchor Details
          Row(
            children: [
              // Dual-Arc Focus Ring
              const _FocusRingGauge(
                percentage: 0.79,
                size: 78,
              ),
              const SizedBox(width: 14),

              // Academic Anchor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'UPCOMING ACADEMIC ANCHOR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: customColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${heroClass.courseCode} — ${heroClass.title}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: customColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          heroClass.location.isNotEmpty
                              ? heroClass.location
                              : 'Room 402',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: customColors.textSecondary,
                          ),
                        ),
                        Text(
                          '  •  ',
                          style: TextStyle(color: customColors.textMuted),
                        ),
                        Expanded(
                          child: Text(
                            heroClass.instructor.isNotEmpty
                                ? heroClass.instructor
                                : 'Prof. Mercer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: customColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '11:00 AM — 01:30 PM',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF818CF8)
                            : customColors.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Deep Work Protected Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C2230).withValues(alpha: 0.5)
                  : customColors.canvasBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: customColors.cardBorder.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 14,
                        color: isDark
                            ? const Color(0xFF818CF8)
                            : customColors.primaryAccent,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '4.5h ',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF818CF8)
                                      : customColors.primaryAccent,
                                ),
                              ),
                              TextSpan(
                                text: 'Protected Deep Work',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: customColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '2 lectures remaining',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: customColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. "Fix My Day — Auto-Repair Gaps" High-Craft Button
          InkWell(
            onTap: _isOptimizingDay
                ? null
                : () {
                    _triggerDayOptimization();
                  },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2638)
                    : customColors.canvasBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                      : customColors.primaryAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: _isOptimizingDay
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Optimizing Schedules & Shields...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_fix_high,
                            size: 15,
                            color: isDark
                                ? const Color(0xFF818CF8)
                                : customColors.primaryAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Fix My Day — Auto-Repair Gaps',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: isDark
                                  ? const Color(0xFF818CF8)
                                  : customColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // QUICK COMMAND DOCK
  // ==========================================
  Widget _buildQuickCommandDock(BuildContext context) {
    final customColors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Action 1: Scan Syllabus
        Expanded(
          child: _buildActionPill(
            context,
            icon: Icons.document_scanner_outlined,
            iconColor: isDark ? const Color(0xFF818CF8) : customColors.primaryAccent,
            label: 'Scan Syllabus',
            onTap: () {
              HapticFeedback.lightImpact();
              RoutineImportModal.show(context);
            },
          ),
        ),
        const SizedBox(width: 8),

        // Action 2: Log Habit
        Expanded(
          child: _buildActionPill(
            context,
            icon: Icons.block_outlined,
            iconColor: const Color(0xFFF43F5E), // Rose crimson
            label: 'Log Habit',
            onTap: () {
              HapticFeedback.lightImpact();
              AddEditHabitSheet.show(context);
            },
          ),
        ),
        const SizedBox(width: 8),

        // Action 3: 25m Sprint
        Expanded(
          child: _buildActionPill(
            context,
            icon: Icons.play_circle_outline_rounded,
            iconColor: const Color(0xFF10B981), // Emerald
            label: '25m Sprint',
            onTap: () => _showPomodoroModal(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPill(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    final customColors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF121826).withValues(alpha: 0.75)
              : customColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: customColors.cardBorder.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: customColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DAY CADENCE STREAM (Linear Timeline)
  // ==========================================
  Widget _buildDayCadenceSection(
    BuildContext context, {
    required String dateText,
  }) {
    final customColors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Day Cadence',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: customColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF818CF8)
                          : customColors.primaryAccent,
                    ),
                  ),
                ],
              ),
              Text(
                dateText,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: customColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 1. Completed/Attended Lecture Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF121826).withValues(alpha: 0.6)
                : customColors.cardBackground.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: customColors.cardBorder.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 48,
                decoration: BoxDecoration(
                  color: customColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '09:00 — 10:30 AM',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: customColors.textMuted,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Attended',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CSE 3101: Database Systems',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: customColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: customColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Room 301  •  Relational Algebra & Normalization',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: customColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 2. Active Now Lecture Card (Emerald Border & Glow)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F1B1F).withValues(alpha: 0.8)
                : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '11:00 AM — 01:30 PM (NOW)',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'Verified Materials',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CSE 3102: Software Engineering Lab',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: customColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Room 402  •  Git Sprint Milestones Ready',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: customColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 3. Free-Time Window Optimization Card (Dashed Border)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF121826).withValues(alpha: 0.5)
                : customColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                  : customColors.primaryAccent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                      : customColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bolt,
                  size: 16,
                  color: isDark
                      ? const Color(0xFF818CF8)
                      : customColors.primaryAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Free Interval (60m)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: customColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '01:30 PM — 02:30 PM • Ideal for LeetCode / Reflection',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: customColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  FixMyDaySheet.show(context);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C2230)
                        : customColors.canvasBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: customColors.cardBorder.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Lock-In',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF818CF8)
                          : customColors.primaryAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 4. Distraction Barrier Locked Stream Card (Rose-Crimson)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF221118).withValues(alpha: 0.75)
                : const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.remove_moderator_outlined,
                size: 18,
                color: Color(0xFFF43F5E),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DISTRACTION BARRIER LOCKED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: const Color(0xFFF43F5E),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '0 Breaches',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF43F5E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Social Media & Video Reels Lockout active until 18:00',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: customColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target apps: Instagram, TikTok, YouTube Shorts (Hardware VPN Shield active)',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: customColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DEFENSE VAULT SECTION (Opal-inspired)
  // ==========================================
  Widget _buildDefenseVaultSection(
    BuildContext context, {
    required List<HabitItem> antiHabits,
  }) {
    final customColors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryHabit = antiHabits.isNotEmpty ? antiHabits.first : null;
    final habitTitle = primaryHabit?.title ?? 'No Instagram / TikTok before 18:00';
    final replacementCue = primaryHabit?.shieldRuleDescription.isNotEmpty == true
        ? primaryHabit!.shieldRuleDescription
        : 'Courtyard walk + 10 pages reading';
    const frictionText = '60s delay';
    final streakDays = (primaryHabit != null && primaryHabit.streakCount > 0)
        ? primaryHabit.streakCount
        : 18;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF121826).withValues(alpha: 0.8)
            : customColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: customColors.cardBorder.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF818CF8)
                        : customColors.primaryAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Defense Vault',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: customColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onNavigateToVault?.call();
                },
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 3),
                      Text(
                        'Resilient',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 Telemetry Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'SHIELDED',
                  value: '6.2h',
                  sub: 'Today',
                  subColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'IMPULSES',
                  value: '14',
                  sub: 'Defended',
                  subColor: isDark ? const Color(0xFF818CF8) : customColors.primaryAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'STREAK',
                  value: '${streakDays}d',
                  sub: 'Unbroken',
                  subColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Active Rule Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A2130).withValues(alpha: 0.4)
                  : customColors.canvasBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: customColors.cardBorder.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PRIMARY ACTIVE RULE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: customColors.textMuted,
                      ),
                    ),
                    Text(
                      'Hard Friction: $frictionText',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF43F5E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  habitTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: customColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: customColors.cardBorder.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.swap_calls,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Replacement Cue: ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: customColors.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          replacementCue,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required String sub,
    required Color subColor,
  }) {
    final customColors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A2130).withValues(alpha: 0.5)
            : customColors.canvasBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: customColors.cardBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: customColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: customColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COURSE WORKSPACE SECTION
  // ==========================================
  Widget _buildCourseWorkspaceSection(
    BuildContext context, {
    required List<AcademicEvent> courses,
  }) {
    final customColors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Course modules data
    final displayCourses = [
      {
        'code': 'CSE 3102',
        'title': 'Software Engineering',
        'att': '96%',
        'icon': Icons.commit,
        'milestone': 'Git repo sprint delivery',
        'due': 'Due in 2 days',
        'dueColor': isDark ? const Color(0xFF818CF8) : customColors.primaryAccent,
        'instructor': 'Prof. Mercer',
        'room': 'Room 402',
      },
      {
        'code': 'MATH 2205',
        'title': 'Discrete Mathematics',
        'att': '92%',
        'icon': Icons.quiz_outlined,
        'milestone': 'Graph Theory Quiz',
        'due': 'Friday 10:00 AM',
        'dueColor': customColors.textSecondary,
        'instructor': 'Dr. K. Vance',
        'room': 'Hall B',
      },
      {
        'code': 'CS 301',
        'title': 'Design & Analysis of Algorithms',
        'att': '94%',
        'icon': Icons.warning_amber_rounded,
        'milestone': 'Midterm Exam Prep',
        'due': 'In 4 days',
        'dueColor': const Color(0xFFF43F5E),
        'instructor': 'Prof. Dr. A. Vance',
        'room': 'Lab 402 • Turing Hall',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Course Workspace',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: customColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onNavigateToRoutine?.call();
                },
                child: Text(
                  '3 Active Modules',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF818CF8)
                        : customColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Course Cards
        ...displayCourses.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => CourseSyllabusDrilldownScreen(
                      courseCode: c['code'] as String,
                      courseTitle: c['title'] as String,
                      instructor: c['instructor'] as String,
                      room: c['room'] as String,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF121826).withValues(alpha: 0.75)
                      : customColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: customColors.cardBorder.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${c['code']}: ${c['title']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: customColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Att: ${c['att']}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              c['icon'] as IconData,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF818CF8)
                                  : customColors.primaryAccent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              c['milestone'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: customColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          c['due'] as String,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: c['dueColor'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ==========================================
// DUAL-ARC FOCUS RING GAUGE WIDGET
// ==========================================
class _FocusRingGauge extends StatelessWidget {
  final double percentage; // e.g. 0.79
  final double size;

  const _FocusRingGauge({
    required this.percentage,
    this.size = 78,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DualArcPainter(
              percentage: percentage,
              isDark: isDark,
              primaryColor: isDark
                  ? const Color(0xFF6366F1)
                  : customColors.primaryAccent,
              secondaryColor: const Color(0xFF10B981),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percentage * 100).toInt()}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: customColors.textPrimary,
                ),
              ),
              Text(
                'SHIELDED',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: customColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualArcPainter extends CustomPainter {
  final double percentage;
  final bool isDark;
  final Color primaryColor;
  final Color secondaryColor;

  _DualArcPainter({
    required this.percentage,
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.width / 2) - 4;
    final innerRadius = outerRadius - 7;

    // Track Paint
    final trackPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E2638).withValues(alpha: 0.8)
          : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    // 1. Draw Outer Track
    canvas.drawCircle(center, outerRadius, trackPaint);

    // 2. Draw Outer Arc (Indigo)
    final outerArcPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false,
      outerArcPaint,
    );

    // 3. Draw Inner Arc (Emerald)
    final innerArcPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final innerSweep = 2 * math.pi * (percentage * 0.92);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      innerSweep,
      false,
      innerArcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DualArcPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.isDark != isDark ||
        oldDelegate.primaryColor != primaryColor;
  }
}
