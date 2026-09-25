import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/routine_models.dart';
import '../../../../core/providers/routine_providers.dart';
import '../../../../core/theme/app_colors.dart';

class AddEditHabitSheet extends ConsumerStatefulWidget {
  final HabitItem? habitToEdit;
  final bool initialIsAntiHabit;

  const AddEditHabitSheet({
    super.key,
    this.habitToEdit,
    this.initialIsAntiHabit = true,
  });

  static Future<void> show(
    BuildContext context, {
    HabitItem? habitToEdit,
    bool initialIsAntiHabit = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditHabitSheet(
        habitToEdit: habitToEdit,
        initialIsAntiHabit: initialIsAntiHabit,
      ),
    );
  }

  @override
  ConsumerState<AddEditHabitSheet> createState() => _AddEditHabitSheetState();
}

class _AddEditHabitSheetState extends ConsumerState<AddEditHabitSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _descCtrl;

  late HabitType _selectedType;
  late int _streakCount;
  late List<int> _targetDays;

  bool get _isEditing => widget.habitToEdit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habitToEdit;

    _selectedType = h?.type ??
        (widget.initialIsAntiHabit
            ? HabitType.antiHabit
            : HabitType.positiveHabit);
    _titleCtrl = TextEditingController(text: h?.title ?? '');
    _categoryCtrl = TextEditingController(
      text: h?.category ??
          (_selectedType == HabitType.antiHabit
              ? 'Focus Protocol'
              : 'Daily Routine'),
    );
    _descCtrl = TextEditingController(text: h?.shieldRuleDescription ?? '');
    _streakCount = h?.streakCount ?? 0;
    _targetDays = List<int>.from(h?.targetDays ?? [1, 2, 3, 4, 5, 6, 7]);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _saveHabit() {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.habitToEdit?.id ?? 'h-${DateTime.now().millisecondsSinceEpoch}';

    final habit = HabitItem(
      id: id,
      title: _titleCtrl.text.trim(),
      type: _selectedType,
      category: _categoryCtrl.text.trim(),
      streakCount: _streakCount,
      shieldRuleDescription: _descCtrl.text.trim(),
      targetDays: _targetDays,
      completedDates: widget.habitToEdit?.completedDates ?? [],
    );

    if (_isEditing) {
      ref.read(habitsProvider.notifier).updateHabit(habit);
    } else {
      ref.read(habitsProvider.notifier).createHabit(habit);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Updated ${habit.category} rule!'
            : 'Added new rule to Habit Protection Vault!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Rule?'),
        content: Text(
            'Are you sure you want to remove "${widget.habitToEdit!.title}" from the vault?'),
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
              ref
                  .read(habitsProvider.notifier)
                  .deleteHabit(widget.habitToEdit!.id);
              Navigator.pop(dlgCtx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Removed rule from vault.'),
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
    final isAntiHabit = _selectedType == HabitType.antiHabit;
    final accentColor =
        isAntiHabit ? customColors.antiHabit : customColors.primaryAccent;

    final days = [
      {'label': 'S', 'idx': 7},
      {'label': 'M', 'idx': 1},
      {'label': 'T', 'idx': 2},
      {'label': 'W', 'idx': 3},
      {'label': 'T', 'idx': 4},
      {'label': 'F', 'idx': 5},
      {'label': 'S', 'idx': 6},
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
                      _isEditing
                          ? 'Edit Habit / Rule'
                          : 'Declare New Habit / Rule',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Habit vault & impulse deterrence architecture',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: customColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (_isEditing)
                  IconButton(
                    tooltip: 'Delete Rule',
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
                    // Segmented Toggle: Positive Habit vs Anti-Habit
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(
                                    () => _selectedType = HabitType.antiHabit);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isAntiHabit
                                      ? customColors.antiHabit
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shield,
                                      size: 16,
                                      color: isAntiHabit
                                          ? Colors.white
                                          : customColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Not To Do (Anti-Habit)',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: isAntiHabit
                                            ? Colors.white
                                            : customColors.textSecondary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() =>
                                    _selectedType = HabitType.positiveHabit);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isAntiHabit
                                      ? customColors.primaryAccent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.task_alt,
                                      size: 16,
                                      color: !isAntiHabit
                                          ? Colors.white
                                          : customColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Daily Discipline',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: !isAntiHabit
                                            ? Colors.white
                                            : customColors.textSecondary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: isAntiHabit
                            ? "Forbidden Rule / Trigger *"
                            : "Daily Discipline Habit *",
                        hintText: isAntiHabit
                            ? "e.g. Don't open Instagram / TikTok before 6 PM"
                            : "e.g. Solve 2 Graph Theory problems",
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please specify a title'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Category Tag
                    TextFormField(
                      controller: _categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category Tag',
                        hintText:
                            'e.g. Social Media Lockout, Code & Build, Academics',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description / Rationale
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: isAntiHabit
                            ? 'Deterrence Strategy / Replacement Trigger'
                            : 'Habit Milestones / Target Details',
                        hintText: isAntiHabit
                            ? 'e.g. Academic Focus Block • Walk courtyard instead'
                            : 'e.g. LeetCode #133 & #207 completed',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Manual Streak Count Number Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENT STREAK COUNT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: customColors.textMuted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Manual streak correction',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: customColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: customColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: customColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                onPressed: () {
                                  if (_streakCount > 0) {
                                    setState(() => _streakCount--);
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                child: Text(
                                  '$_streakCount d',
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                onPressed: () {
                                  setState(() => _streakCount++);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Target Days Selector (S, M, T, W, T, F, S)
                    Text(
                      'TARGET DAYS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: customColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: days.map((d) {
                        final idx = d['idx'] as int;
                        final isSelected = _targetDays.contains(idx);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _targetDays.remove(idx);
                              } else {
                                _targetDays.add(idx);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? accentColor
                                  : theme.colorScheme.surfaceContainer,
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : customColors.cardBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                d['label'] as String,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : customColors.textSecondary,
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
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveHabit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(_isEditing ? 'Update Rule' : 'Lock in Vault'),
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
