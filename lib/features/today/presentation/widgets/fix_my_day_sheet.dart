import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/routine_models.dart';
import '../../../../core/providers/routine_providers.dart';
import '../../../../core/services/calendar_sync_service.dart';
import '../../../../core/services/emergency_reschedule_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Modal bottom sheet allowing students to repair their daily schedule with 1 tap.
/// Re-aligns overdue focus sessions, preserves locked university classes,
/// and re-arms anti-habit shields without manual re-planning.
class FixMyDaySheet extends ConsumerStatefulWidget {
  const FixMyDaySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FixMyDaySheet(),
    );
  }

  @override
  ConsumerState<FixMyDaySheet> createState() => _FixMyDaySheetState();
}

class _FixMyDaySheetState extends ConsumerState<FixMyDaySheet> {
  int _selectedReasonIndex = 0;
  bool _isCalculating = false;
  ScheduleRepairResult? _repairResult;

  final List<Map<String, String>> _delayReasons = [
    {
      'label': 'Running 30m Late',
      'icon': '⏱️',
      'reason': 'Running approximately 30 minutes behind schedule.',
    },
    {
      'label': 'Class Overtime',
      'icon': '🔬',
      'reason': 'University lecture or sessional lab ran over scheduled time.',
    },
    {
      'label': 'Procrastination Slip',
      'icon': '🛡️',
      'reason': 'Lost focus to phone or high-dopamine apps; need to re-arm shield.',
    },
    {
      'label': 'Emergency Reset',
      'icon': '⚡',
      'reason': 'Start fresh right now; slide all remaining focus blocks forward.',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runRepair(_selectedReasonIndex);
    });
  }

  Future<void> _runRepair(int index) async {
    setState(() {
      _selectedReasonIndex = index;
      _isCalculating = true;
    });

    final currentBlocks = ref.read(timelineBlocksProvider);
    final todayClasses = ref.read(currentDayEventsProvider);
    final delayReason = _delayReasons[index]['reason']!;

    final rescheduleService = ref.read(emergencyRescheduleServiceProvider);

    try {
      final result = await rescheduleService.calculateAiRepair(
        currentBlocks: currentBlocks,
        todayClasses: todayClasses,
        delayReason: delayReason,
      );

      if (mounted) {
        setState(() {
          _repairResult = result;
          _isCalculating = false;
        });
      }
    } catch (_) {
      // Fallback to offline heuristic
      final fallbackResult = rescheduleService.calculateLocalRepair(
        currentBlocks: currentBlocks,
        todayClasses: todayClasses,
        delayReason: delayReason,
      );

      if (mounted) {
        setState(() {
          _repairResult = fallbackResult;
          _isCalculating = false;
        });
      }
    }
  }

  Future<void> _applyRepair() async {
    if (_repairResult == null || _repairResult!.repairedBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No repaired schedule to apply.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final repairedBlocks = _repairResult!.repairedBlocks;

    // 1. Overwrite Hive timeline
    await ref.read(timelineBlocksProvider.notifier).replaceAllBlocks(repairedBlocks);

    // 2. Sync to Google Calendar if sync active
    final syncSettings = ref.read(syncSettingsProvider);
    int calExported = 0;
    if (syncSettings.is2WayLiveSyncActive || syncSettings.autoBlockDistractions) {
      final calService = ref.read(calendarSyncServiceProvider);
      calExported = await calService.exportTimelineBlocksToCalendar(repairedBlocks);
    }

    // 3. Reschedule local notification alerts
    if (syncSettings.classReminderAlerts) {
      final notifService = ref.read(notificationServiceProvider);
      await notifService.scheduleTimelineBlockAlerts(repairedBlocks);
    }

    if (mounted) {
      Navigator.of(context).pop();

      final calMsg = calExported > 0 ? ' • Calendar updated' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Schedule Repaired! ${_repairResult!.shiftedCount} blocks shifted$calMsg • Focus protected ⚡',
          ),
          backgroundColor: AppColors.of(context).primaryAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = AppColors.of(context);
    final now = DateTime.now();
    final nowStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: customColors.cardBorder,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: customColors.antiHabit.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bolt,
                    size: 22,
                    color: customColors.antiHabit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Fix My Day',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: customColors.antiHabit.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'EMERGENCY REPAIR',
                              style: TextStyle(
                                color: customColors.antiHabit,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Instant schedule realignment & distraction recovery',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: customColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Current Time Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: customColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        size: 16,
                        color: customColors.primaryAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Time: $nowStr',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: customColors.primaryFixed,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'BEDTIME CURFEW: 22:30',
                      style: TextStyle(
                        color: customColors.onPrimaryFixed,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Delay Context Selector Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'WHAT HAPPENED? (SELECT DELAY CONTEXT)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: customColors.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_delayReasons.length, (idx) {
                  final item = _delayReasons[idx];
                  final isSelected = _selectedReasonIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Text(item['icon']!),
                      label: Text(
                        item['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: customColors.primaryFixed,
                      onSelected: _isCalculating
                          ? null
                          : (sel) {
                              if (sel) _runRepair(idx);
                            },
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Main Content: Coaching message + Repaired Blocks List
          Expanded(
            child: _isCalculating
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: customColors.primaryAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Repairing schedule & preserving focus slots...',
                          style: TextStyle(
                            color: customColors.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Coaching Note Box
                        if (_repairResult != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: customColors.primaryFixed.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    customColors.primaryAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 20,
                                  color: customColors.primaryAccent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'RECOVERY TACTIC',
                                            style: TextStyle(
                                              color: customColors.primaryAccent,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: customColors.primaryAccent
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _repairResult!.isAiGenerated
                                                  ? 'GEMINI AI'
                                                  : 'HEURISTIC ENGINE',
                                              style: TextStyle(
                                                color:
                                                    customColors.primaryAccent,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _repairResult!.coachingMessage,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontSize: 12,
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Section Title: Repaired Schedule Preview
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'REPAIRED SCHEDULE (${_repairResult?.repairedBlocks.length ?? 0} BLOCKS)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: customColors.textMuted,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '${_repairResult?.shiftedCount ?? 0} shifted • ${_repairResult?.skippedCount ?? 0} skipped',
                              style: TextStyle(
                                color: customColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (_repairResult != null)
                          ..._repairResult!.repairedBlocks.map((block) {
                            return _buildRepairedBlockTile(
                              context,
                              block: block,
                              customColors: customColors,
                              theme: theme,
                            );
                          }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: customColors.cardBackground,
              border: Border(top: BorderSide(color: customColors.cardBorder)),
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed: (_isCalculating || _repairResult == null)
                    ? null
                    : _applyRepair,
                icon: const Icon(Icons.check_circle, size: 20),
                label: Text(
                  'Apply Schedule Repair (${_repairResult?.repairedBlocks.length ?? 0} Blocks)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: customColors.primaryAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairedBlockTile(
    BuildContext context, {
    required TimelineBlock block,
    required AppCustomColors customColors,
    required ThemeData theme,
  }) {
    Color domainColor;
    String badgeLabel;
    IconData icon;

    switch (block.type) {
      case TimelineBlockType.academicClass:
        domainColor = customColors.academic;
        badgeLabel = 'LOCKED CLASS';
        icon = Icons.menu_book;
        break;
      case TimelineBlockType.antiHabitShield:
        domainColor = customColors.antiHabit;
        badgeLabel = block.badgeText ?? 'NOT TO DO SHIELD';
        icon = Icons.shield;
        break;
      case TimelineBlockType.calendarSync:
        domainColor = customColors.academic;
        badgeLabel = 'CALENDAR EVENT';
        icon = Icons.event;
        break;
      default:
        domainColor = customColors.primaryAccent;
        badgeLabel = block.badgeText ?? 'FOCUS BLOCK';
        icon = Icons.bolt;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: domainColor.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: domainColor.withOpacity(0.12),
            ),
            child: Icon(icon, size: 16, color: domainColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: domainColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: domainColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${block.startTime} – ${block.endTime}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: domainColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  block.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (block.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    block.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: customColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
