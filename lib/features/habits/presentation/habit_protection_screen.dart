import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/routine_models.dart';
import '../../../core/providers/routine_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_top_header.dart';
import 'widgets/add_habit_sheet.dart';

class HabitProtectionScreen extends ConsumerWidget {
  const HabitProtectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final antiHabits = ref.watch(antiHabitsProvider);
    final positiveHabits = ref.watch(positiveHabitsProvider);

    return Scaffold(
      appBar: const AppTopHeader(
        subtitle: "The 'Not To Do' & Habit Protection Vault",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // HEADER & CONTEXT
            // ==========================================
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: customColors.antiHabit.withOpacity(0.15),
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
                          color: customColors.antiHabit,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Defensive Perimeter Active',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: customColors.antiHabit,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'Fall 2024 Exam Prep',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: customColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Habit Protection Vault',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Guarding student focus through deliberate anti-habits and uncompromised academic routine.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: customColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // DEFENSIVE STREAK BANNER
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
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: customColors.primaryAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.shield,
                      size: 26,
                      color: customColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '18 Days Active Defense',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
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
                                'TOP 4%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: customColors.onPrimaryFixed,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Optimal impulse friction status across all monitors',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: customColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ==========================================
            // DUAL METRIC SUMMARY BENTO
            // ==========================================
            Row(
              children: [
                // Positive Routine Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
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
                            Text(
                              'DAILY ROUTINES',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: customColors.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: customColors.primaryAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: 0.83,
                                    strokeWidth: 4,
                                    backgroundColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        customColors.primaryAccent),
                                  ),
                                  Text(
                                    '83%',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${positiveHabits.length} of ${positiveHabits.length + 1}',
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Disciplines Met',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: customColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+1 from yesterday',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: customColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Anti-Habits Integrity Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
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
                            Text(
                              'ANTI-HABITS',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: customColors.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                            Icon(
                              Icons.security,
                              size: 16,
                              color: customColors.antiHabit,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: customColors.antiHabit.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.gpp_good,
                                size: 24,
                                color: customColors.antiHabit,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '100%',
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: customColors.antiHabit,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${antiHabits.length}/${antiHabits.length} Shielded',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: customColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Zero Breaches Logged',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: customColors.antiHabit,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==========================================
            // FORBIDDEN ANTI-HABITS SECTION
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Anti-Habits (Forbidden)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: customColors.antiHabit.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'HIGH FRICTION',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: customColors.antiHabit,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${antiHabits.length} Rules Locked',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: customColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Anti-Habits List (Tap to Edit)
            if (antiHabits.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: customColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: customColors.cardBorder),
                ),
                child: Center(
                  child: Text(
                    'No anti-habits declared yet. Tap below to declare one!',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              )
            else
              ...antiHabits.map((habit) => _buildAntiHabitCard(
                    context,
                    ref,
                    habit: habit,
                  )),
            const SizedBox(height: 18),

            // ==========================================
            // DAILY POSITIVE DISCIPLINES SECTION
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Daily Positive Disciplines',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: customColors.primaryFixed,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'ROUTINE TRACKER',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: customColors.onPrimaryFixed,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${positiveHabits.length} Active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: customColors.primaryAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Disciplines List (Tap to Edit)
            if (positiveHabits.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: customColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: customColors.cardBorder),
                ),
                child: Center(
                  child: Text(
                    'No positive routines yet. Declare your first discipline below!',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              )
            else
              ...positiveHabits.map((discipline) => _buildDisciplineCard(
                    context,
                    ref,
                    habit: discipline,
                  )),
            const SizedBox(height: 18),

            // ==========================================
            // STICKY DECLARED ACTION FOOTER
            // ==========================================
            ElevatedButton.icon(
              onPressed: () {
                AddEditHabitSheet.show(context, initialIsAntiHabit: true);
              },
              icon: const Icon(Icons.add_moderator, size: 20),
              label: const Text('Declare New Anti-Habit / Rule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: customColors.primaryAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enforces impulse deterrence and syncs barriers to calendar blocks',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: customColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAntiHabitCard(
    BuildContext context,
    WidgetRef ref, {
    required HabitItem habit,
  }) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isDefendedToday = habit.isCompletedOn(today);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: customColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TAP TO EDIT
            AddEditHabitSheet.show(
              context,
              habitToEdit: habit,
              initialIsAntiHabit: true,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 4px left crimson border
                  Container(width: 4, color: customColors.antiHabit),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: tag and streak pill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      customColors.antiHabit.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  habit.category.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: customColors.antiHabit,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 16,
                                    color: customColors.antiHabit,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${habit.streakCount}d Streak',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: customColors.antiHabit,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Title
                          Text(
                            habit.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Description
                          if (habit.shieldRuleDescription.isNotEmpty)
                            Text(
                              habit.shieldRuleDescription,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: customColors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 12),

                          // Action / Status strip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isDefendedToday
                                        ? Icons.check_circle
                                        : Icons.shield_outlined,
                                    size: 16,
                                    color: isDefendedToday
                                        ? customColors.primaryAccent
                                        : customColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isDefendedToday
                                        ? 'Shield Maintained Today'
                                        : 'Awaiting Today Check-in',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: isDefendedToday
                                          ? customColors.primaryAccent
                                          : customColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),

                              // Tactile Defend Button
                              InkWell(
                                onTap: () {
                                  ref
                                      .read(habitsProvider.notifier)
                                      .toggleDefend(habit.id, today);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isDefendedToday
                                          ? 'Checked out of today defense.'
                                          : 'Impulse resisted! Streak incremented to ${habit.streakCount + 1} days.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: customColors.antiHabit,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDefendedToday
                                        ? customColors.antiHabit
                                        : customColors.antiHabit
                                            .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        size: 14,
                                        color: isDefendedToday
                                            ? Colors.white
                                            : customColors.antiHabit,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isDefendedToday
                                            ? 'Defended'
                                            : 'Defend Shield',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: isDefendedToday
                                              ? Colors.white
                                              : customColors.antiHabit,
                                          fontWeight: FontWeight.w800,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisciplineCard(
    BuildContext context,
    WidgetRef ref, {
    required HabitItem habit,
  }) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final now = DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: customColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TAP TO EDIT
            AddEditHabitSheet.show(
              context,
              habitToEdit: habit,
              initialIsAntiHabit: false,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: customColors.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      habit.category.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: customColors.primaryAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 18,
                        color: customColors.primaryAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.streakCount}d Streak',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: customColors.primaryAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                habit.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              if (habit.shieldRuleDescription.isNotEmpty)
                Text(
                  habit.shieldRuleDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: customColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 12),

              // Weekly Consistency Dot Matrix
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Consistency',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: customColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${habit.completedDates.length} Days Logged',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: customColors.primaryAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 7 Day Consistency Indicators (Sunday through Saturday)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  // Calculate date for day i of this current week (Sunday = 0 to Sat = 6)
                  final currentWeekday = now.weekday % 7; // Sunday = 0, Mon = 1, ...
                  final targetDate =
                      now.subtract(Duration(days: currentWeekday - i));
                  final isDone = habit.isCompletedOn(targetDate);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () {
                          ref
                              .read(habitsProvider.notifier)
                              .toggleDefend(habit.id, targetDate);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Column(
                          children: [
                            Text(
                              dayLabels[i],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: customColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? customColors.primaryAccent
                                    : theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
