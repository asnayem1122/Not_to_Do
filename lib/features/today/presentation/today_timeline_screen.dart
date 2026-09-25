import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/routine_models.dart';
import '../../../core/providers/routine_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_top_header.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/bento_empty_state.dart';
import '../../habits/presentation/widgets/add_habit_sheet.dart';
import '../../timetable/presentation/widgets/add_academic_event_sheet.dart';
import 'widgets/daily_energy_gauge.dart';
import 'widgets/fix_my_day_sheet.dart';

class TodayTimelineScreen extends ConsumerWidget {
  const TodayTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final heroClass = ref.watch(heroClassProvider);
    final timelineBlocks = ref.watch(filteredTimelineProvider);
    final currentFilter = ref.watch(timelineFilterProvider);

    return Scaffold(
      appBar: const AppTopHeader(subtitle: "Today's Protected Timeline"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // TOP DATE & STATUS BAR
            // ==========================================
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Tuesday, Oct 14',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'WEEK 7',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: customColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => FixMyDaySheet.show(context),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: customColors.antiHabit.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: customColors.antiHabit.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt,
                              size: 14,
                              color: customColors.antiHabit,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Fix My Day',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: customColors.antiHabit,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: customColors.primaryFixed,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: customColors.primaryAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active Shield',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: customColors.onPrimaryFixed,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Daily Energy Budget Gauge
            const DailyEnergyGauge(),

            // Emergency Schedule Delay Recovery Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: customColors.antiHabit.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: customColors.antiHabit.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: customColors.antiHabit.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.healing,
                      size: 16,
                      color: customColors.antiHabit,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Delay Protection',
                          style: TextStyle(
                            color: customColors.antiHabit,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Running late or class went overtime? Re-align all remaining focus blocks in 1 tap.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: customColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => FixMyDaySheet.show(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customColors.antiHabit,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Fix Now',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ==========================================
            // STAT SUMMARY CARD WITH CIRCULAR RING
            // ==========================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: customColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: customColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '3 protected hours today',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: customColors.primaryFixed,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                '+140 XP',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: customColors.onPrimaryFixed,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 16,
                              color: customColors.primaryAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Distraction defense 100% active',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: customColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 0.85,
                          strokeWidth: 5,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              customColors.primaryAccent),
                        ),
                        Text(
                          '85%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: customColors.primaryAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // HERO CARD: UPCOMING ACADEMIC COMMITMENT
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: customColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: customColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Domain Border Accent (Academic Sky Blue)
                      Container(
                        width: 5,
                        color: customColors.academic,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Tags & Icon
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: customColors.academic
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(9999),
                                        ),
                                        child: Text(
                                          heroClass.startsIn,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: customColors.academic,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(9999),
                                        ),
                                        child: Text(
                                          '${heroClass.courseCode} • ${heroClass.sessionType}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: customColors.textSecondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: customColors.academic
                                          .withValues(alpha: 0.15),
                                    ),
                                    child: Icon(
                                      Icons.terminal,
                                      size: 18,
                                      color: customColors.academic,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Course Title & Location
                              Text(
                                heroClass.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: customColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${heroClass.location} • ${heroClass.instructor}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: customColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Live Status Badges
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: customColors.primaryAccent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check,
                                          size: 13,
                                          color: customColors.primaryAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Slides Downloaded',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: customColors.primaryAccent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (heroClass.assignmentDueText != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: customColors.antiHabit
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.priority_high,
                                            size: 13,
                                            color: customColors.antiHabit,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            heroClass.assignmentDueText!,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: customColors.antiHabit,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Navigating to Room 402, Academic Bldg 2...'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.near_me_outlined,
                                          size: 16),
                                      label: const Text('Navigate Room'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Alarm scheduled for 10m before class.'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.alarm, size: 16),
                                      label: const Text('Push to Alarm'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            customColors.primaryAccent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ==========================================
            // SECTION HEADER & FILTER PILLS
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Protected Schedule',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '${timelineBlocks.length} Blocks Today',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: customColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Filter Scroller
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: 'All (${timelineBlocks.length})',
                    filter: TimelineFilter.all,
                    isSelected: currentFilter == TimelineFilter.all,
                    onTap: () => ref
                        .read(timelineFilterProvider.notifier)
                        .state = TimelineFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Classes',
                    filter: TimelineFilter.classes,
                    isSelected: currentFilter == TimelineFilter.classes,
                    onTap: () => ref
                        .read(timelineFilterProvider.notifier)
                        .state = TimelineFilter.classes,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Positive Habits',
                    filter: TimelineFilter.habits,
                    isSelected: currentFilter == TimelineFilter.habits,
                    onTap: () => ref
                        .read(timelineFilterProvider.notifier)
                        .state = TimelineFilter.habits,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Defended',
                    filter: TimelineFilter.defended,
                    isSelected: currentFilter == TimelineFilter.defended,
                    onTap: () => ref
                        .read(timelineFilterProvider.notifier)
                        .state = TimelineFilter.defended,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // VERTICAL CHRONOLOGICAL TIMELINE (TAP TO EDIT)
            // ==========================================
            if (timelineBlocks.isEmpty)
              BentoEmptyState(
                icon: Icons.view_timeline_outlined,
                title: 'No timeline blocks yet',
                subtitle:
                    'Your protected daily timeline will appear here.\n'
                    'Add classes in the Routine tab or import your schedule.',
                ctaLabel: 'Add a Block',
                onCtaTap: () {
                  AddEditAcademicEventSheet.show(context);
                },
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: timelineBlocks.length,
                itemBuilder: (context, index) {
                  final block = timelineBlocks[index];
                  final isLast = index == timelineBlocks.length - 1;
                  return _buildTimelineItem(
                    context,
                    ref,
                    block: block,
                    isLast: isLast,
                  );
                },
              ),
            const SizedBox(height: 14),

            // ==========================================
            // EVENING SHIELD ALERT CARD
            // ==========================================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: customColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      Icons.nightlight_round,
                      size: 20,
                      color: customColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evening Shield Scheduled',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Anti-procrastination guard locks apps at 21:00',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: customColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: customColors.textMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // ADD BLOCK / RULE CTA
            // ==========================================
            ElevatedButton.icon(
              onPressed: () {
                _showAddOptionsModal(context);
              },
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('+ Add Block / Rule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: customColors.primaryAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required TimelineFilter filter,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? customColors.primaryAccent
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected
                ? customColors.primaryAccent
                : customColors.cardBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: customColors.primaryAccent.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected ? Colors.white : customColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    WidgetRef ref, {
    required TimelineBlock block,
    required bool isLast,
  }) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    // Determine domain color
    Color domainColor;
    switch (block.type) {
      case TimelineBlockType.academicClass:
        domainColor = customColors.academic;
        break;
      case TimelineBlockType.routineFocus:
        domainColor = customColors.primaryAccent;
        break;
      case TimelineBlockType.antiHabitShield:
        domainColor = customColors.antiHabit;
        break;
      case TimelineBlockType.calendarSync:
        domainColor = customColors.academic;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spine column: node dot + vertical guideline
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: customColors.cardBackground,
                    border: Border.all(
                      color: domainColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: domainColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: customColors.cardBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Card content (Tap to toggle / edit)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: BentoCard(
                borderColor: domainColor.withValues(alpha: 0.3),
                padding: EdgeInsets.zero,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Colored strip
                      Container(width: 4, color: domainColor),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Top row: time + tag/badge
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            block.timeRange,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: domainColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (block.location != null) ...[
                                            const SizedBox(width: 6),
                                            Text('•',
                                                style: TextStyle(
                                                    color:
                                                        customColors.textMuted)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                block.location!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.labelSmall
                                                    ?.copyWith(
                                                  color:
                                                      customColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        if (block.badgeText != null)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: block.type ==
                                                      TimelineBlockType
                                                          .antiHabitShield
                                                  ? customColors.antiHabit
                                                      .withValues(alpha: 0.12)
                                                  : customColors.primaryAccent
                                                      .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(9999),
                                            ),
                                            child: Text(
                                              block.badgeText!,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: block.type ==
                                                        TimelineBlockType
                                                            .antiHabitShield
                                                    ? customColors.antiHabit
                                                    : customColors
                                                        .primaryAccent,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.only(
                                              left: 6),
                                          icon: Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: customColors.textMuted,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(timelineBlocksProvider
                                                    .notifier)
                                                .deleteBlock(block.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Title & Subtitle
                                Text(
                                  block.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  block.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: customColors.textSecondary,
                                  ),
                                ),

                                // Anti-habit specific breach defense & replacement trigger
                                if (block.type ==
                                    TimelineBlockType.antiHabitShield) ...[
                                  if (block.replacementTrigger != null) ...[
                                    const SizedBox(height: 6),
                                    RichText(
                                      text: TextSpan(
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: customColors.textSecondary,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Replacement trigger: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  customColors.primaryAccent,
                                            ),
                                          ),
                                          TextSpan(
                                              text:
                                                  block.replacementTrigger!),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: customColors.antiHabit
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.lock,
                                            size: 16,
                                            color: customColors.antiHabit),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Distraction Blocked 01:00 PM – 02:00 PM',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: customColors.antiHabit,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.check_circle,
                                            size: 16,
                                            color: customColors.antiHabit),
                                      ],
                                    ),
                                  ),
                                ],

                                // Routine focus button
                                if (block.type ==
                                    TimelineBlockType.routineFocus) ...[
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () {
                                      ref
                                          .read(
                                              timelineBlocksProvider.notifier)
                                          .toggleBlockCompletion(block.id);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: block.isCompleted
                                            ? customColors.primaryFixed
                                            : customColors.primaryAccent
                                                .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            size: 15,
                                            color: customColors.onPrimaryFixed,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            block.isCompleted
                                                ? '✓ Resisted Slacking'
                                                : 'Log Resistance',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color:
                                                  customColors.onPrimaryFixed,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final customColors = AppColors.of(context);
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: customColors.cardBorder,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Schedule Commitment / Rule',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: customColors.academic.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.school, color: customColors.academic),
                ),
                title: const Text('Add Academic Class / Event'),
                subtitle: const Text(
                    'Lecture, Sessional Lab, Class Test, Assignment'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  AddEditAcademicEventSheet.show(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: customColors.antiHabit.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shield, color: customColors.antiHabit),
                ),
                title: const Text('Declare Habit or Anti-Habit'),
                subtitle: const Text(
                    'Impulse deterrence barrier or daily discipline'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  AddEditHabitSheet.show(context, initialIsAntiHabit: true);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
