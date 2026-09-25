import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/routine_models.dart';
import '../../../core/providers/routine_providers.dart';
import '../../../core/services/ai_conversational_agent_service.dart';
import '../../../core/services/ai_planner_service.dart';
import '../../../core/services/calendar_sync_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/routine_parser_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_settings_dialog.dart';

/// Bottom sheet modal and standalone screen for Calendar Sync & Gemini AI Routine Guard.
/// Provides a conversational memory agent that negotiates daily routines, aligns free slots
/// between university classes and Google Calendar events, and deploys Not To Do distraction barriers.
class SyncAiGuardModal extends ConsumerStatefulWidget {
  final bool isBottomSheet;

  const SyncAiGuardModal({
    super.key,
    this.isBottomSheet = false,
  });

  /// Static helper to display this modal bottom sheet from anywhere.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SyncAiGuardModal(isBottomSheet: true),
    );
  }

  @override
  ConsumerState<SyncAiGuardModal> createState() => _SyncAiGuardModalState();
}

class _SyncAiGuardModalState extends ConsumerState<SyncAiGuardModal>
    with TickerProviderStateMixin {
  late AnimationController _syncAnimController;
  late TabController _tabController;
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  bool _isThinking = false;
  List<SuggestedRoutineBlock> _suggestedBlocks = [];

  final List<Map<String, String>> _quickPromptChips = [
    {
      'label': 'Exam Prep Mode',
      'icon': '📝',
      'prompt':
          'Exam Prep Mode: Prioritize midterm and class test revision, deep focus blocks, strict social media lockout.',
    },
    {
      'label': 'Heavy Lab Week',
      'icon': '🔬',
      'prompt':
          'Heavy Lab Week: Carve out lab preparation, code review, wireframe review, and git repository push verification.',
    },
    {
      'label': 'Competitive Programming',
      'icon': '💻',
      'prompt':
          'Competitive Programming Focus: Schedule a 90-minute LeetCode & Codeforces practice slot in the afternoon gap.',
    },
    {
      'label': 'Recharge / Light Routine',
      'icon': '🌿',
      'prompt':
          'Recharge / Light Routine: Light syllabus review, 20-minute post-class breathing buffer, enforce evening screen curfew.',
    },
    {
      'label': 'Tighten Distraction Shields',
      'icon': '🛡️',
      'prompt':
          'Tighten distraction shields: Lock out Instagram, TikTok, Reels, Steam, and Discord for the entire afternoon.',
    },
    {
      'label': 'Add 30m Buffer',
      'icon': '⏱️',
      'prompt':
          'Add a 30-minute rest buffer before my next class and keep all focus blocks under 60 minutes.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _syncAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _tabController = TabController(length: 2, vsync: this);

    // Initial default recommendations seeded from Stitch Screen 5 specs
    _suggestedBlocks = [
      const SuggestedRoutineBlock(
        id: 'sug-1',
        title: 'Deep Focus: Software Engineering Wireframes',
        startTime: '13:30',
        endTime: '15:00',
        category: 'positiveHabit',
        blockType: TimelineBlockType.routineFocus,
        priority: 'High',
        rationale:
            'Post-lab consolidation window for CSE 3102 project submission.',
        shieldedDistraction: null,
      ),
      const SuggestedRoutineBlock(
        id: 'sug-2',
        title: 'Shield: High-Dopamine Distraction Barrier',
        startTime: '15:00',
        endTime: '16:00',
        category: 'antiHabit',
        blockType: TimelineBlockType.antiHabitShield,
        priority: 'Critical',
        rationale:
            'Vulnerable energy dip after lunch. Carving zero-interruption shield.',
        shieldedDistraction: 'Instagram, TikTok, YouTube Shorts, Gaming',
      ),
      const SuggestedRoutineBlock(
        id: 'sug-3',
        title: 'Pre-Lecture Review: Operating Systems',
        startTime: '16:30',
        endTime: '17:00',
        category: 'academicPrep',
        blockType: TimelineBlockType.academicClass,
        priority: 'Medium',
        rationale:
            'Review CPU scheduling algorithms before tomorrow morning lecture.',
      ),
    ];
  }

  @override
  void dispose() {
    _syncAnimController.dispose();
    _tabController.dispose();
    _promptController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _triggerSyncRefresh() async {
    _syncAnimController.forward(from: 0.0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting Google Calendar 2-way sync...'),
        duration: Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final calService = ref.read(calendarSyncServiceProvider);
    final notifService = ref.read(notificationServiceProvider);
    final timelineNotifier = ref.read(timelineBlocksProvider.notifier);
    final academicNotifier = ref.read(academicEventsProvider.notifier);

    final result =
        await ref.read(syncSettingsProvider.notifier).performTwoWaySync(
              calService: calService,
              notifService: notifService,
              timelineNotifier: timelineNotifier,
              academicNotifier: academicNotifier,
            );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synced ${result.exportedCount} classes to ${result.calendarName ?? "Google Calendar"} • ${result.importedBlocks.length} external events imported',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.of(context).primaryAccent,
        ),
      );
    }
  }

  Future<void> _sendAgentMessage(String promptText) async {
    final text = promptText.trim();
    if (text.isEmpty) return;

    _promptController.clear();
    setState(() => _isThinking = true);

    final agentService = ref.read(aiConversationalAgentServiceProvider);
    final freeGaps = ref.read(todayFreeGapsProvider);
    final todayEvents = ref.read(currentDayEventsProvider);
    final allTimelineBlocks = ref.read(timelineBlocksProvider);
    final externalEvents = allTimelineBlocks
        .where((b) => b.type == TimelineBlockType.calendarSync)
        .toList();
    final activeHabits = ref.read(habitsProvider);

    try {
      ConversationalRoutineResponse response;
      if (agentService.messageHistory.isEmpty) {
        response = await agentService.startNewSession(
          freeGaps: freeGaps,
          todayEvents: todayEvents,
          externalAppointments: externalEvents,
          activeHabits: activeHabits,
          initialPrompt: text,
        );
      } else {
        response = await agentService.sendRefinementMessage(text);
      }

      if (mounted) {
        setState(() {
          _isThinking = false;
          if (response.updatedBlocks.isNotEmpty) {
            _suggestedBlocks = List.from(response.updatedBlocks);
          }
        });

        // Scroll chat to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isThinking = false);
        if (e is GeminiApiKeyMissingException) {
          _showMissingKeyDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Agent Error: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.of(context).antiHabit,
            ),
          );
        }
      }
    }
  }

  void _showMissingKeyDialog() {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.key, size: 20),
            SizedBox(width: 8),
            Text('Gemini Key Required'),
          ],
        ),
        content: const Text(
          'Please configure your Gemini API Key in settings to enable conversational multi-turn routine optimization.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              ApiSettingsDialog.show(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _editBlockTime(int index, bool isStart) async {
    final block = _suggestedBlocks[index];
    final current = isStart ? block.startTime : block.endTime;
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _suggestedBlocks[index] = isStart
            ? block.copyWith(startTime: formatted)
            : block.copyWith(endTime: formatted);
      });
      ref.read(aiConversationalAgentServiceProvider).setBlocks(_suggestedBlocks);
    }
  }

  void _dismissBlock(int index) {
    final removed = _suggestedBlocks.removeAt(index);
    setState(() {});
    ref.read(aiConversationalAgentServiceProvider).setBlocks(_suggestedBlocks);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dismissed "${removed.title}"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _suggestedBlocks.insert(index, removed);
            });
            ref
                .read(aiConversationalAgentServiceProvider)
                .setBlocks(_suggestedBlocks);
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Commits the approved suggested routine blocks to Hive, device Google Calendar, and Local Notifications.
  Future<void> _commitRoutineToTimelineAndCalendar() async {
    if (_suggestedBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No suggested blocks to apply.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final timelineItems =
        _suggestedBlocks.map((b) => b.toTimelineBlock()).toList();

    // 1. Batch save to Hive timeline store
    await ref.read(timelineBlocksProvider.notifier).batchAddBlocks(timelineItems);

    final syncSettings = ref.read(syncSettingsProvider);
    int calendarExported = 0;

    // 2. Export focus blocks and anti-habit shields to device Google Calendar
    if (syncSettings.is2WayLiveSyncActive || syncSettings.autoBlockDistractions) {
      final calService = ref.read(calendarSyncServiceProvider);
      calendarExported =
          await calService.exportTimelineBlocksToCalendar(timelineItems);
    }

    // 3. Schedule 10-minute advance notifications
    if (syncSettings.classReminderAlerts) {
      final notifService = ref.read(notificationServiceProvider);
      await notifService.scheduleTimelineBlockAlerts(timelineItems);
    }

    if (mounted) {
      if (widget.isBottomSheet) {
        Navigator.of(context).pop();
      }

      final calendarMsg = calendarExported > 0
          ? ' • $calendarExported exported to Google Calendar'
          : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Applied ${_suggestedBlocks.length} blocks to Today\'s Protected Timeline$calendarMsg • Alerts Armed! 🛡️',
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
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final agentService = ref.watch(aiConversationalAgentServiceProvider);
    final messageHistory = agentService.messageHistory;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle for bottom sheet
        if (widget.isBottomSheet) ...[
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
          const SizedBox(height: 10),
        ],

        // Header Top Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: customColors.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      size: 18,
                      color: customColors.onPrimaryFixed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync & AI Routine Guard',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Gemini Memory Agent & 2-Way Sync',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: customColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.tune, size: 20),
                tooltip: 'API Settings',
                onPressed: () => ApiSettingsDialog.show(context),
              ),
            ],
          ),
        ),

        // Segmented Tabs Header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: customColors.primaryAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: customColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            tabs: const [
              Tab(
                height: 38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum, size: 15),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'AI Assistant',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                height: 38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_sync, size: 15),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Calendar & Gaps',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // TAB 0: CONVERSATIONAL AGENT & LIVE SUGGESTIONS
              _buildConversationalAgentTab(
                context,
                messageHistory: messageHistory,
                customColors: customColors,
                theme: theme,
              ),

              // TAB 1: CALENDAR 2-WAY SYNC & DETECTED GAPS
              _buildCalendarSyncSettingsTab(
                context,
                customColors: customColors,
                theme: theme,
              ),
            ],
          ),
        ),

        // Bottom Fixed Action Bar (Commit to Timeline) - only when suggestions present
        if (_suggestedBlocks.isNotEmpty)
          _buildBottomCommitBar(customColors, theme),
      ],
    );

    if (widget.isBottomSheet) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: content,
      );
    }

    return Scaffold(
      body: SafeArea(child: content),
    );
  }

  // =========================================================================
  // TAB 0: CONVERSATIONAL AGENT & ROUTINE CARDS
  // =========================================================================
  Widget _buildConversationalAgentTab(
    BuildContext context, {
    required List<AiChatMessage> messageHistory,
    required AppCustomColors customColors,
    required ThemeData theme,
  }) {
    return SingleChildScrollView(
      controller: _chatScrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Introductory Agent Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: customColors.primaryFixed.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: customColors.primaryAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: customColors.primaryAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chat with Gemini to shape today\'s open hours. Gaps between university classes and calendar appointments are protected automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: customColors.onPrimaryFixed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Message History / Dialogue Stream
          if (messageHistory.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: customColors.cardBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 28,
                    color: customColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No dialogue history yet.',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: customColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a strategy preset below or enter custom instructions to generate your daily plan.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: customColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            ...messageHistory.map((msg) => _buildChatMessageBubble(
                  context,
                  message: msg,
                  customColors: customColors,
                  theme: theme,
                )),

          // Thinking / Generating Indicator
          if (_isThinking)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: customColors.primaryFixed,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: customColors.primaryAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gemini Flash is analyzing free gaps and anti-habit shields...',
                    style: TextStyle(
                      color: customColors.primaryAccent,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Quick Strategy Preset Chips
          Text(
            'STRATEGY PRESETS & ADJUSTMENTS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: customColors.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickPromptChips.map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: Text(chip['icon']!),
                    label: Text(
                      chip['label']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _isThinking
                        ? null
                        : () {
                            _sendAgentMessage(chip['prompt']!);
                          },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Conversational Input TextField
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptController,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. "Move gym to 5 PM", "Make shield stricter", "Add a 30m break"...',
                    hintStyle: TextStyle(
                      color: customColors.textMuted,
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: customColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: customColors.primaryAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty && !_isThinking) {
                      _sendAgentMessage(val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isThinking
                    ? null
                    : () {
                        if (_promptController.text.trim().isNotEmpty) {
                          _sendAgentMessage(_promptController.text);
                        }
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isThinking
                        ? customColors.cardBorder
                        : customColors.primaryAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.send,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Suggested Routine Blocks Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE ROUTINE DECK (${_suggestedBlocks.length})',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: customColors.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              if (_suggestedBlocks.isNotEmpty)
                Text(
                  'Tap times to adjust bounds',
                  style: TextStyle(
                    color: customColors.textSecondary,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Suggested Blocks Cards List
          if (_suggestedBlocks.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: customColors.cardBorder),
              ),
              child: Center(
                child: Text(
                  'No suggested blocks. Type a prompt above or tap a preset to formulate a routine.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: customColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...List.generate(_suggestedBlocks.length, (index) {
              final block = _suggestedBlocks[index];
              return _buildSuggestedBlockCard(
                context,
                block: block,
                index: index,
                customColors: customColors,
                theme: theme,
              );
            }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: CALENDAR 2-WAY SYNC & DETECTED GAPS
  // =========================================================================
  Widget _buildCalendarSyncSettingsTab(
    BuildContext context, {
    required AppCustomColors customColors,
    required ThemeData theme,
  }) {
    final syncSettings = ref.watch(syncSettingsProvider);
    final freeGaps = ref.watch(todayFreeGapsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Google Calendar Card
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: customColors.primaryFixed,
                          ),
                          child: Icon(
                            Icons.cloud_sync,
                            size: 24,
                            color: customColors.onPrimaryFixed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Calendar',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              syncSettings.accountEmail,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: customColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Refresh Calendar Sync',
                      icon: RotationTransition(
                        turns: _syncAnimController,
                        child: Icon(
                          Icons.refresh,
                          color: customColors.primaryAccent,
                        ),
                      ),
                      onPressed: _triggerSyncRefresh,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: customColors.primaryAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '2-Way Live Sync Active',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Last sync: ${syncSettings.lastSyncTime}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: customColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Automated Sync Settings Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: customColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: customColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automated Sync Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildToggleRow(
                  context,
                  title: 'Auto-push class routine',
                  subtitle: 'Sync timetable changes immediately',
                  value: syncSettings.autoPushRoutine,
                  onChanged: (val) =>
                      ref.read(syncSettingsProvider.notifier).toggleAutoPush(),
                ),
                const SizedBox(height: 10),
                _buildToggleRow(
                  context,
                  title: "Auto-block 'Not To Do' distraction slots",
                  subtitle: 'Carve defensive study windows in calendar',
                  value: syncSettings.autoBlockDistractions,
                  onChanged: (val) =>
                      ref.read(syncSettingsProvider.notifier).toggleAutoBlock(),
                ),
                const SizedBox(height: 10),
                _buildToggleRow(
                  context,
                  title: 'Class reminder alerts',
                  subtitle: '15 minutes before lecture hall gates',
                  value: syncSettings.classReminderAlerts,
                  onChanged: (val) =>
                      ref.read(syncSettingsProvider.notifier).toggleReminders(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Free Slots Detection Strip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: customColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: customColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 20,
                          color: customColors.academic,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Today's Detected Free Slots",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: customColors.academic.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${freeGaps.length} GAPS DETECTED',
                        style: TextStyle(
                          color: customColors.academic,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Calculated unallocated intervals between locked university classes and Google Calendar events (07:30 – 22:30).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: customColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                if (freeGaps.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('No free gaps detected between classes today.'),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: freeGaps.map((gap) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: customColors.cardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: customColors.primaryAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              gap.displayRange,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================================
  // CHAT BUBBLE WIDGET
  // =========================================================================
  Widget _buildChatMessageBubble(
    BuildContext context, {
    required AiChatMessage message,
    required AppCustomColors customColors,
    required ThemeData theme,
  }) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: customColors.primaryFixed,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: customColors.onPrimaryFixed,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 30),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: customColors.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: customColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: customColors.primaryAccent.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 14,
                color: customColors.primaryAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Routine Guard',
                    style: TextStyle(
                      color: customColors.primaryAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message.text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12.5,
                      height: 1.4,
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

  // =========================================================================
  // SUGGESTED BLOCK CARD WIDGET
  // =========================================================================
  Widget _buildSuggestedBlockCard(
    BuildContext context, {
    required SuggestedRoutineBlock block,
    required int index,
    required AppCustomColors customColors,
    required ThemeData theme,
  }) {
    Color borderColor;
    Color badgeColor;
    String badgeLabel;
    IconData icon;

    switch (block.blockType) {
      case TimelineBlockType.antiHabitShield:
        borderColor = customColors.antiHabit;
        badgeColor = customColors.antiHabit;
        badgeLabel = 'NOT TO DO SHIELD';
        icon = Icons.shield;
        break;
      case TimelineBlockType.academicClass:
        borderColor = customColors.academic;
        badgeColor = customColors.academic;
        badgeLabel = 'ACADEMIC PREP';
        icon = Icons.menu_book;
        break;
      default:
        borderColor = customColors.primaryAccent;
        badgeColor = customColors.primaryAccent;
        badgeLabel = 'FOCUS BLOCK';
        icon = Icons.bolt;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: borderColor),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Inline time adjusters
                InkWell(
                  onTap: () => _editBlockTime(index, true),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      block.startTime,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: borderColor,
                      ),
                    ),
                  ),
                ),
                const Text(' – ', style: TextStyle(fontSize: 11)),
                InkWell(
                  onTap: () => _editBlockTime(index, false),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      block.endTime,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: borderColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Dismiss action
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _dismissBlock(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              block.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              block.rationale,
              style: theme.textTheme.bodySmall?.copyWith(
                color: customColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (block.shieldedDistraction != null) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: customColors.antiHabit.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: 13,
                      color: customColors.antiHabit,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Locked Out: ${block.shieldedDistraction}',
                        style: TextStyle(
                          color: customColors.antiHabit,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // BOTTOM COMMIT BAR
  // =========================================================================
  Widget _buildBottomCommitBar(
    AppCustomColors customColors,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        border: Border(
          top: BorderSide(color: customColors.cardBorder),
        ),
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed: _suggestedBlocks.isEmpty
              ? null
              : _commitRoutineToTimelineAndCalendar,
          icon: const Icon(Icons.playlist_add_check, size: 20),
          label: Text(
            'Apply Routine to Schedule (${_suggestedBlocks.length})',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: customColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: customColors.primaryAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
