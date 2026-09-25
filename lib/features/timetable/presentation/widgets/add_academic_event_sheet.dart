import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/routine_models.dart';
import '../../../../core/providers/routine_providers.dart';
import '../../../../core/theme/app_colors.dart';

class AddEditAcademicEventSheet extends ConsumerStatefulWidget {
  final AcademicEvent? eventToEdit;
  final int? initialDayOfWeek;
  final bool isDraft;

  const AddEditAcademicEventSheet({
    super.key,
    this.eventToEdit,
    this.initialDayOfWeek,
    this.isDraft = false,
  });

  static Future<AcademicEvent?> show(
    BuildContext context, {
    AcademicEvent? eventToEdit,
    int? initialDayOfWeek,
    bool isDraft = false,
  }) {
    return showModalBottomSheet<AcademicEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditAcademicEventSheet(
        eventToEdit: eventToEdit,
        initialDayOfWeek: initialDayOfWeek,
        isDraft: isDraft,
      ),
    );
  }

  @override
  ConsumerState<AddEditAcademicEventSheet> createState() =>
      _AddEditAcademicEventSheetState();
}

class _AddEditAcademicEventSheetState
    extends ConsumerState<AddEditAcademicEventSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _roomCtrl;
  late TextEditingController _instructorCtrl;
  late TextEditingController _notesCtrl;

  late AcademicEventType _selectedType;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  int? _selectedDayOfWeek;
  DateTime? _selectedDate;
  bool _syncToCalendar = true;

  bool get _isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    final ev = widget.eventToEdit;

    _codeCtrl = TextEditingController(text: ev?.courseCode ?? '');
    _titleCtrl = TextEditingController(text: ev?.title ?? '');
    _roomCtrl = TextEditingController(text: ev?.room ?? '');
    _instructorCtrl = TextEditingController(text: ev?.instructor ?? '');
    _notesCtrl = TextEditingController(text: ev?.syllabusNotes ?? '');

    _selectedType = ev?.type ?? AcademicEventType.lecture;
    _selectedDayOfWeek =
        ev?.dayOfWeek ?? widget.initialDayOfWeek ?? 2; // Default Tuesday (2)
    _selectedDate = ev?.specificDate;
    _syncToCalendar = ev?.syncToCalendar ?? true;

    // Parse initial start and end times
    _startTime = _parseTimeOfDay(ev?.startTime ?? '09:00');
    _endTime = _parseTimeOfDay(ev?.endTime ?? '10:30');
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0].trim()),
        minute: int.parse(parts[1].trim()),
      );
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _roomCtrl.dispose();
    _instructorCtrl.dispose();
    _notesCtrl.dispose();
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

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDayOfWeek = picked.weekday;
      });
    }
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.eventToEdit?.id ??
        'ae-${DateTime.now().millisecondsSinceEpoch}';

    final newEvent = AcademicEvent(
      id: id,
      title: _titleCtrl.text.trim(),
      courseCode: _codeCtrl.text.trim().toUpperCase(),
      type: _selectedType,
      room: _roomCtrl.text.trim(),
      instructor: _instructorCtrl.text.trim(),
      dayOfWeek: _selectedDayOfWeek,
      specificDate: _selectedDate,
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      syllabusNotes: _notesCtrl.text.trim(),
      isCompleted: widget.eventToEdit?.isCompleted ?? false,
      syncToCalendar: _syncToCalendar,
      calendarEventId: widget.eventToEdit?.calendarEventId,
    );

    if (widget.isDraft) {
      Navigator.pop(context, newEvent);
      return;
    }

    if (_isEditing) {
      ref.read(academicEventsProvider.notifier).updateEvent(newEvent);
    } else {
      ref.read(academicEventsProvider.notifier).createEvent(newEvent);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Updated ${newEvent.courseCode} details!'
            : 'Added ${newEvent.courseCode} to timetable!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Course?'),
        content: Text(
            'Are you sure you want to remove ${widget.eventToEdit!.courseCode} (${widget.eventToEdit!.title})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.of(context).antiHabit,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (widget.isDraft) {
                Navigator.pop(dlgCtx);
                Navigator.pop(context, null);
                return;
              }
              ref
                  .read(academicEventsProvider.notifier)
                  .deleteEvent(widget.eventToEdit!.id);
              Navigator.pop(dlgCtx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Deleted ${widget.eventToEdit!.courseCode} from routine.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final badgeColor = _getBadgeColor(_selectedType, customColors);

    final weekdays = [
      {'label': 'MON', 'idx': 1},
      {'label': 'TUE', 'idx': 2},
      {'label': 'WED', 'idx': 3},
      {'label': 'THU', 'idx': 4},
      {'label': 'FRI', 'idx': 5},
      {'label': 'SAT', 'idx': 6},
      {'label': 'SUN', 'idx': 7},
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isDraft
                          ? (_isEditing
                              ? 'Edit Staged Course'
                              : 'Add Staged Course')
                          : (_isEditing
                              ? 'Edit Academic Course'
                              : 'Add Academic Course'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Timetable scheduling with calendar guard',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: customColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (_isEditing)
                  IconButton(
                    tooltip: 'Delete Event',
                    icon: Icon(
                      Icons.delete_outline,
                      color: customColors.antiHabit,
                    ),
                    onPressed: _confirmDelete,
                  ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Form fields scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Type Dropdown with Semantic Badge
                    Text(
                      'EVENT CATEGORY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: customColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: customColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: customColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AcademicEventType>(
                          value: _selectedType,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down,
                              color: customColors.textSecondary),
                          items: AcademicEventType.values.map((type) {
                            final c = _getBadgeColor(type, customColors);
                            return DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    type.displayName,
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedType = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Course Code & Title
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _codeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Code',
                              hintText: 'CSE 3102',
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Req' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Course Title',
                              hintText: 'Software Engineering Lab',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Course title is required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Room & Instructor
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _roomCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Room / Lab',
                              hintText: 'Lab 3, Software Wing',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _instructorCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Instructor',
                              hintText: 'Dr. Alex Mercer',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Time Range Selector
                    Text(
                      'SCHEDULED TIME',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: customColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: customColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: customColors.cardBorder),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'START TIME',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: customColors.textMuted,
                                          fontSize: 9,
                                        ),
                                      ),
                                      Text(
                                        _formatTimeOfDay(_startTime),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.schedule,
                                      size: 18, color: badgeColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: customColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: customColors.cardBorder),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'END TIME',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: customColors.textMuted,
                                          fontSize: 9,
                                        ),
                                      ),
                                      Text(
                                        _formatTimeOfDay(_endTime),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.schedule,
                                      size: 18, color: badgeColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Recurrence Selector (Day of Week)
                    Text(
                      'RECURRING DAY OF WEEK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: customColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: weekdays.map((w) {
                          final idx = w['idx'] as int;
                          final isSelected = _selectedDayOfWeek == idx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedDayOfWeek = idx),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? customColors.primaryAccent
                                      : customColors.cardBackground,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? customColors.primaryAccent
                                        : customColors.cardBorder,
                                  ),
                                ),
                                child: Text(
                                  w['label'] as String,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Specific Date Picker (for Exams / CT / Assignments)
                    if (_selectedType.isExamOrAssignment) ...[
                      InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: customColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: customColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event,
                                  size: 20, color: customColors.academic),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedDate != null
                                      ? 'Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)}'
                                      : 'Select Specific Exam / Due Date',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                'Change',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: customColors.primaryAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Preparation Note / Syllabus notes (Emphasized for Sessional Lab)
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: _selectedType ==
                                AcademicEventType.sessionalLab
                            ? 'Required Lab Preparation *'
                            : 'Syllabus Notes / Assignment Details',
                        hintText:
                            _selectedType == AcademicEventType.sessionalLab
                                ? 'e.g. Bring Project Wireframes & Git push'
                                : 'Optional topic coverage or study notes',
                      ),
                      validator: (v) {
                        if (_selectedType == AcademicEventType.sessionalLab &&
                            (v == null || v.trim().isEmpty)) {
                          return 'Lab preparation requirements must be specified';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Google Calendar Sync per-event Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sync,
                                size: 18,
                                color: customColors.primaryAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sync to Google Calendar',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _syncToCalendar,
                            activeThumbColor: customColors.primaryAccent,
                            onChanged: (val) =>
                                setState(() => _syncToCalendar = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customColors.primaryAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(widget.isDraft
                          ? (_isEditing ? 'Apply Changes' : 'Add to Staging')
                          : (_isEditing ? 'Update Course' : 'Save Course')),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
