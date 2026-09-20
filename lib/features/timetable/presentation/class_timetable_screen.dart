import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/routine_models.dart';
import '../../../core/providers/routine_providers.dart';
import '../../../core/services/calendar_sync_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_top_header.dart';
import 'widgets/add_academic_event_sheet.dart';
import 'widgets/routine_import_modal.dart';

class ClassTimetableScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToVault;

  const ClassTimetableScreen({super.key, this.onNavigateToVault});

  @override
  ConsumerState<ClassTimetableScreen> createState() =>
      _ClassTimetableScreenState();
}

class _ClassTimetableScreenState extends ConsumerState<ClassTimetableScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getBadgeColor(AcademicEventType type, AppCustomColors customColors) {
    switch (type) {
      case AcademicEventType.lecture:
      case AcademicEventType.tutorial:
        return customColors.academic; // Sky Blue
      case AcademicEventType.sessionalLab:
        return const Color(0xFF6366F1); // Indigo
      case AcademicEventType.classTest:
      case AcademicEventType.assignment:
        return const Color(0xFFF59E0B); // Amber
      case AcademicEventType.midterm:
      case AcademicEventType.termFinal:
        return customColors.antiHabit; // Crimson
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final selectedDay = ref.watch(selectedDayProvider);
    final weeklyCycles = ref.watch(weeklyCycleProvider);
    final events = ref.watch(currentDayEventsProvider);
    final isAutoSyncActive = ref.watch(isLiveSyncedBarActiveProvider);

    final filteredEvents = events.where((e) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return e.courseCode.toLowerCase().contains(q) ||
          e.title.toLowerCase().contains(q) ||
          e.room.toLowerCase().contains(q) ||
          e.instructor.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: const AppTopHeader(
        subtitle: 'Class Routine & Semester Timetable',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => RoutineImportModal.show(context),
        icon: const Icon(Icons.document_scanner),
        label: const Text(
          'Scan Routine',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: customColors.primaryAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // TITLE & EXPORT ACTION BAR
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semester Routine',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Class schedules auto-synced with calendar guard',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: customColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => RoutineImportModal.show(context),
                      icon: const Icon(Icons.document_scanner, size: 16),
                      label: const Text('Scan Routine'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customColors.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Export Timetable PDF',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surfaceContainer,
                        ),
                        child: Icon(
                          Icons.picture_as_pdf,
                          size: 20,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Exporting Semester Routine Timetable (PDF)...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ==========================================
            // SEMESTER OVERVIEW METRIC BENTO CARD
            // ==========================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: customColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: customColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          'FALL SEMESTER 2026 • 24 CREDITS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: customColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        'Week 7 of 16',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: customColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Meter
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: 7 / 16,
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          customColors.primaryAccent),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dual Metric Tiles
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: customColors.primaryFixed,
                                ),
                                child: Icon(
                                  Icons.school,
                                  size: 18,
                                  color: customColors.onPrimaryFixed,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TARGET GPA',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: customColors.textMuted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        text: '3.85 ',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '/ 4.0',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: customColors.textMuted,
                                              fontWeight: FontWeight.w500,
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
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: customColors.academic.withOpacity(0.2),
                                ),
                                child: Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: customColors.academic,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ATTENDANCE',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: customColors.textMuted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        text: '94% ',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Active',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  customColors.primaryAccent,
                                              fontWeight: FontWeight.w600,
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
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ==========================================
            // ROUTINE DAYS HORIZONTAL PILL SELECTOR
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Weekly Cycle',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: customColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${events.length} Lectures ${selectedDay == "TUE" ? "Today" : selectedDay}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: customColors.primaryAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: weeklyCycles.map((cycle) {
                  final isSelected = cycle.day == selectedDay;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        ref.read(selectedDayProvider.notifier).state =
                            cycle.day;
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? customColors.primaryAccent
                              : customColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? customColors.primaryAccent
                                : customColors.cardBorder,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: customColors.primaryAccent
                                        .withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              cycle.day,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cycle.classCountLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? customColors.primaryFixed
                                    : customColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // SEARCH & AUTO-SYNC BAR
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search routine, room, prof...',
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: customColors.textMuted,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    final current =
                        ref.read(isLiveSyncedBarActiveProvider.notifier).state;
                    ref.read(isLiveSyncedBarActiveProvider.notifier).state =
                        !current;
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: customColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: customColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'SYNC',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAutoSyncActive
                                ? customColors.primaryAccent
                                : theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: Icon(
                            isAutoSyncActive
                                ? Icons.check
                                : Icons.sync_disabled,
                            size: 14,
                            color: isAutoSyncActive
                                ? Colors.white
                                : customColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ==========================================
            // VERTICAL CLASS CARDS FEED (TAP TO EDIT)
            // ==========================================
            if (filteredEvents.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: customColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: customColors.cardBorder),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy,
                          size: 36, color: customColors.textMuted),
                      const SizedBox(height: 8),
                      Text(
                        selectedDay == 'SUN'
                            ? 'Sunday is Off! Enjoy your rest day.'
                            : 'No lectures found matching your criteria.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          AddEditAcademicEventSheet.show(
                            context,
                            initialDayOfWeek: dayCodeToIndex(selectedDay),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Lecture to this Day'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(180, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return _buildCourseCard(
                    context,
                    ref,
                    event: event,
                    selectedDay: selectedDay,
                  );
                },
              ),
            const SizedBox(height: 16),

            // ==========================================
            // OCR ROUTINE IMPORTER & QUICK ACTIONS
            // ==========================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: customColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: customColors.cardBorder),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => RoutineImportModal.show(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: customColors.primaryFixed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.document_scanner,
                            size: 24,
                            color: customColors.onPrimaryFixed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Routine Importer',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Snap paper syllabus, upload PDF or paste text',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: customColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: customColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => RoutineImportModal.show(context),
                          icon: const Icon(Icons.photo_camera_outlined,
                              size: 18),
                          label: const Text('Scan Routine'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            AddEditAcademicEventSheet.show(
                              context,
                              initialDayOfWeek: dayCodeToIndex(selectedDay),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Custom'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: customColors.primaryAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ==========================================
            // HABIT VAULT MICRO-ALERT FOOTER
            // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: customColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: customColors.antiHabit,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Anti-distraction calendar blocks armed for 04:30 PM.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: widget.onNavigateToVault ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Switching to Habit Protection Vault tab.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                    child: Text(
                      'Vault →',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: customColors.primaryAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    WidgetRef ref, {
    required AcademicEvent event,
    required String selectedDay,
  }) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final accentColor = _getBadgeColor(event.type, customColors);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: customColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TAP TO EDIT
            AddEditAcademicEventSheet.show(
              context,
              eventToEdit: event,
              initialDayOfWeek: event.dayOfWeek,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 4px left accent bar
                  Container(width: 4, color: accentColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Course code badge, Type, and Time slot
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      event.courseCode,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: accentColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    event.type.displayName,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: customColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                event.timeRange,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Title
                          Text(
                            event.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Location & Instructor
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: customColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${event.room} • ${event.instructor}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: customColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Preparation Note Callout
                          if (event.syllabusNotes.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.priority_high,
                                    size: 16,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.type ==
                                                  AcademicEventType.sessionalLab
                                              ? 'REQUIRED LAB PREPARATION'
                                              : 'SYLLABUS / EXAM COVERAGE',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: accentColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          event.syllabusNotes,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: accentColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Bottom action / status strip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (event.isCompleted)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: customColors.primaryAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Present (Recorded)',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: customColors.primaryAccent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: customColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Scheduled',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: customColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                              // Attendance trigger & G-Cal sync badge
                              Row(
                                children: [
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    tooltip: event.isCompleted
                                        ? 'Mark Absent'
                                        : 'Mark Present',
                                    icon: Icon(
                                      event.isCompleted
                                          ? Icons.how_to_reg
                                          : Icons.how_to_reg_outlined,
                                      size: 20,
                                      color: event.isCompleted
                                          ? customColors.primaryAccent
                                          : customColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      ref
                                          .read(
                                              academicEventsProvider.notifier)
                                          .toggleCompletion(event.id);
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () async {
                                      final calService = ref.read(calendarSyncServiceProvider);
                                      final notifService = ref.read(notificationServiceProvider);
                                      final isSynced = await ref
                                          .read(academicEventsProvider.notifier)
                                          .toggleCalendarSync(
                                            event.id,
                                            calService: calService,
                                            notifService: notifService,
                                          );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isSynced
                                                  ? 'Exported ${event.courseCode} to Google Calendar & armed alerts.'
                                                  : 'Removed ${event.courseCode} from Google Calendar.',
                                            ),
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: isSynced
                                                ? customColors.primaryAccent
                                                : customColors.cardBorder,
                                          ),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.surfaceContainer,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            event.syncToCalendar
                                                ? Icons.cloud_done_outlined
                                                : Icons.cloud_off_outlined,
                                            size: 13,
                                            color: event.syncToCalendar
                                                ? customColors.academic
                                                : customColors.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.syncToCalendar
                                                ? 'Synced'
                                                : 'Local',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: event.syncToCalendar
                                                  ? customColors.academic
                                                  : customColors.textMuted,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}
