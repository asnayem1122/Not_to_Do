import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/routine_models.dart';
import '../../../../core/providers/routine_providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'add_academic_event_sheet.dart';

class StagingReviewSheet extends ConsumerStatefulWidget {
  final List<AcademicEvent> initialEvents;

  const StagingReviewSheet({
    super.key,
    required this.initialEvents,
  });

  static Future<bool?> show(
    BuildContext context, {
    required List<AcademicEvent> stagedEvents,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StagingReviewSheet(initialEvents: stagedEvents),
    );
  }

  @override
  ConsumerState<StagingReviewSheet> createState() => _StagingReviewSheetState();
}

class _StagingReviewSheetState extends ConsumerState<StagingReviewSheet> {
  late List<AcademicEvent> _stagedList;
  bool _isCommitting = false;

  @override
  void initState() {
    super.initState();
    _stagedList = List<AcademicEvent>.from(widget.initialEvents);
  }

  int get _lecturesCount => _stagedList
      .where((e) =>
          e.type == AcademicEventType.lecture ||
          e.type == AcademicEventType.tutorial)
      .length;

  int get _labsCount => _stagedList
      .where((e) => e.type == AcademicEventType.sessionalLab)
      .length;

  int get _assessmentsCount =>
      _stagedList.where((e) => e.type.isExamOrAssignment).length;

  Color _getBadgeColor(AcademicEventType type, AppCustomColors colors) {
    switch (type) {
      case AcademicEventType.lecture:
      case AcademicEventType.tutorial:
        return colors.academic;
      case AcademicEventType.sessionalLab:
        return const Color(0xFF6366F1); // Indigo
      case AcademicEventType.classTest:
      case AcademicEventType.assignment:
        return const Color(0xFFF59E0B); // Amber
      case AcademicEventType.midterm:
      case AcademicEventType.termFinal:
        return colors.antiHabit; // Crimson
    }
  }

  String _getDayName(int? dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'MON';
      case 2:
        return 'TUE';
      case 3:
        return 'WED';
      case 4:
        return 'THU';
      case 5:
        return 'FRI';
      case 6:
        return 'SAT';
      case 7:
        return 'SUN';
      default:
        return 'FLEX';
    }
  }

  Future<void> _editItem(int index) async {
    final item = _stagedList[index];
    final updated = await AddEditAcademicEventSheet.show(
      context,
      eventToEdit: item,
      initialDayOfWeek: item.dayOfWeek,
      isDraft: true,
    );

    if (updated != null && mounted) {
      setState(() {
        _stagedList[index] = updated;
      });
    }
  }

  Future<void> _addMissingEvent() async {
    final newEvent = await AddEditAcademicEventSheet.show(
      context,
      isDraft: true,
    );

    if (newEvent != null && mounted) {
      setState(() {
        _stagedList.add(newEvent);
      });
    }
  }

  void _removeItem(int index) {
    final removed = _stagedList.removeAt(index);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${removed.courseCode} from staging.'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _stagedList.insert(index, removed);
            });
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _commitAll() async {
    if (_stagedList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No staged items to save.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCommitting = true);

    try {
      await ref
          .read(academicEventsProvider.notifier)
          .batchAddEvents(_stagedList);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully saved ${_stagedList.length} items to your semester routine!',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.of(context).primaryAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCommitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save routine items: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.of(context).antiHabit,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = AppColors.of(context);
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: customColors.primaryFixed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.rule_folder_outlined,
                    size: 22,
                    color: customColors.onPrimaryFixed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Parsed Schedule',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${_stagedList.length} items detected • Inspect before saving',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: customColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Summary Metric Badges Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildSummaryBadge(
                  label: '$_lecturesCount Lectures',
                  color: customColors.academic,
                  icon: Icons.menu_book_outlined,
                ),
                const SizedBox(width: 8),
                _buildSummaryBadge(
                  label: '$_labsCount Labs',
                  color: const Color(0xFF6366F1),
                  icon: Icons.biotech_outlined,
                ),
                const SizedBox(width: 8),
                _buildSummaryBadge(
                  label: '$_assessmentsCount Assessments',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.quiz_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action strip: "+ Add Missing Event" & Staging Note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STAGED SESSIONS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: customColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addMissingEvent,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Missing Event'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Staged Items List
          Expanded(
            child: _stagedList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            size: 48,
                            color: customColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No items currently staged',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'All items were removed or none were detected. Tap below to add manually.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: customColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _addMissingEvent,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Custom Event'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    itemCount: _stagedList.length,
                    itemBuilder: (context, index) {
                      final item = _stagedList[index];
                      return _buildStagedCard(
                        context: context,
                        item: item,
                        index: index,
                        customColors: customColors,
                        theme: theme,
                      );
                    },
                  ),
          ),

          // Bottom Commit Action CTA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: customColors.cardBackground,
              border: Border(
                top: BorderSide(color: customColors.cardBorder),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: _isCommitting ? null : _commitAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: customColors.primaryAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _isCommitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm & Save (${_stagedList.length}) Items to Routine',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
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

  Widget _buildSummaryBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStagedCard({
    required BuildContext context,
    required AcademicEvent item,
    required int index,
    required AppCustomColors customColors,
    required ThemeData theme,
  }) {
    final accentColor = _getBadgeColor(item.type, customColors);
    final dayLabel = _getDayName(item.dayOfWeek);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: customColors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4px Accent Strip
              Container(width: 4, color: accentColor),

              // Card Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Code, Type Badge & Actions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  item.courseCode,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.type.displayName.toUpperCase(),
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 9,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quick Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit Details',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: () => _editItem(index),
                          ),
                          const SizedBox(width: 4),
                          // Delete / Ignore Button
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: customColors.antiHabit,
                            ),
                            tooltip: 'Ignore / Remove Detection',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Title
                      Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: customColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Editable / Information Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildChip(
                            label: dayLabel,
                            icon: Icons.calendar_today,
                            color: customColors.primaryAccent,
                            theme: theme,
                          ),
                          _buildChip(
                            label: item.timeRange,
                            icon: Icons.schedule,
                            color: customColors.textSecondary,
                            theme: theme,
                          ),
                          _buildChip(
                            label: item.room,
                            icon: Icons.location_on_outlined,
                            color: customColors.textSecondary,
                            theme: theme,
                          ),
                          if (item.instructor != 'TBA')
                            _buildChip(
                              label: item.instructor,
                              icon: Icons.person_outline,
                              color: customColors.textSecondary,
                              theme: theme,
                            ),
                        ],
                      ),

                      if (item.syllabusNotes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: accentColor.withOpacity(0.15)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes, size: 14, color: accentColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.syllabusNotes,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
