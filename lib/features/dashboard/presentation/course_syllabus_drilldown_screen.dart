import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class CourseSyllabusDrilldownScreen extends StatefulWidget {
  final String courseCode;
  final String courseTitle;
  final String instructor;
  final String room;

  const CourseSyllabusDrilldownScreen({
    super.key,
    this.courseCode = 'CS 301',
    this.courseTitle = 'Design & Analysis of Algorithms',
    this.instructor = 'Prof. Dr. A. Vance',
    this.room = 'Lab 402 • Turing Hall',
  });

  @override
  State<CourseSyllabusDrilldownScreen> createState() =>
      _CourseSyllabusDrilldownScreenState();
}

class _CourseSyllabusDrilldownScreenState
    extends State<CourseSyllabusDrilldownScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'All Modules',
    'Graph Theory',
    'Dynamic Prog.',
    'Greedy Alg.',
    'Divide & Conquer'
  ];

  final Set<int> _completedWeeks = {7};
  final Set<int> _completedProblemSets = {1, 2, 3};

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: customColors.academic.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: customColors.academic.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    widget.courseCode,
                    style: GoogleFonts.jetBrainsMono(
                      color: customColors.academic,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '4.0 Credits • Fall 2026',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: customColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.courseTitle,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Share Syllabus',
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syllabus link copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Course Resources',
            icon: const Icon(Icons.folder_open_outlined, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // URGENT EXAM COUNTDOWN ALERT
            // ==========================================
            _buildUrgentExamAlert(context),
            const SizedBox(height: 16),

            // ==========================================
            // TELEMETRY & PROGRESS BAR
            // ==========================================
            _buildTelemetryGrid(context),
            const SizedBox(height: 20),

            // ==========================================
            // MODULES & LECTURE ROADMAP
            // ==========================================
            _buildSectionHeader(
              context,
              title: 'Modules & Lecture Roadmap',
              badge: 'WEEKS 1–16',
            ),
            const SizedBox(height: 10),
            _buildFilterChips(context),
            const SizedBox(height: 12),
            _buildSyllabusRoadmapList(context),
            const SizedBox(height: 24),

            // ==========================================
            // PROBLEM SET & LAB SUBMISSIONS
            // ==========================================
            _buildSectionHeader(
              context,
              title: 'Deliverables & Lab Queue',
              badge: '4 OF 6 SUBMITTED',
            ),
            const SizedBox(height: 10),
            _buildProblemSetTracker(context),
            const SizedBox(height: 24),

            // ==========================================
            // EXAM PREPARATION VAULT
            // ==========================================
            _buildSectionHeader(
              context,
              title: 'Exam Preparation Vault',
              badge: 'CHEATSHEETS & PAPERS',
            ),
            const SizedBox(height: 10),
            _buildExamVaultGrid(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentExamAlert(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: customColors.antiHabit.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: customColors.antiHabit.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: customColors.antiHabit.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.timer_outlined,
              size: 20,
              color: customColors.antiHabit,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MIDTERM EXAM IN 4 DAYS',
                      style: GoogleFonts.jetBrainsMono(
                        color: customColors.antiHabit,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: customColors.antiHabit,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '30% OF GRADE',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Monday, 10:00 AM • Room 402 • 90 Mins (Formula Cheatsheet Allowed)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: customColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showExamSimulationModal(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: customColors.antiHabit,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Launch Midterm Simulation',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showCheatsheetModal(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: customColors.cardBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: customColors.cardBorder),
                        ),
                        child: Text(
                          'View Cheat Table',
                          style: GoogleFonts.plusJakartaSans(
                            color: customColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: customColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTelemetryMetric(
                  context,
                  label: 'SYLLABUS COVERAGE',
                  value: '64%',
                  subvalue: 'Week 9 of 16',
                  color: customColors.primaryAccent,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: customColors.cardBorder,
              ),
              Expanded(
                child: _buildTelemetryMetric(
                  context,
                  label: 'ATTENDANCE',
                  value: '92%',
                  subvalue: '23 / 25 Sessions',
                  color: customColors.academic,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: customColors.cardBorder,
              ),
              Expanded(
                child: _buildTelemetryMetric(
                  context,
                  label: 'CURRENT SCORE',
                  value: '185/200',
                  subvalue: 'Proj. Grade: A (3.94)',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: 0.64,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainer,
              valueColor:
                  AlwaysStoppedAnimation<Color>(customColors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetric(
    BuildContext context, {
    required String label,
    required String value,
    required String subvalue,
    required Color color,
  }) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: customColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          subvalue,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: customColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final customColors = AppColors.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilterIndex = index);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? customColors.primaryAccent.withValues(alpha: 0.12)
                      : customColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? customColors.primaryAccent
                        : customColors.cardBorder,
                  ),
                ),
                child: Text(
                  _filters[index],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? customColors.primaryAccent
                        : customColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSyllabusRoadmapList(BuildContext context) {
    final customColors = AppColors.of(context);

    final modules = [
      {
        'week': 7,
        'title': 'Divide & Conquer & Master Theorem',
        'sub': "Strassen's Matrix Mult, Closest Pair, Master Method",
        'status': 'Completed',
        'tag': 'Divide & Conquer',
        'slides': 'Lecture 13 & 14 Slides.pdf',
        'reading': 'CLRS Ch. 4 (pp. 65–110)',
      },
      {
        'week': 8,
        'title': 'Graph Algorithms I: BFS, DFS & Topo Sort',
        'sub': 'Connected components, DAG cycle detection, BFS tree',
        'status': 'Active Node',
        'tag': 'Graph Theory',
        'slides': 'Lecture 15 Slides.pdf',
        'reading': 'CLRS Ch. 22',
      },
      {
        'week': 9,
        'title': "Graph Algorithms II: Dijkstra's & MST",
        'sub': 'Bellman-Ford, Prim & Kruskal greedy algorithms',
        'status': 'Upcoming',
        'tag': 'Graph Theory',
        'slides': 'Lecture 16 Slides.pdf',
        'reading': 'CLRS Ch. 23–24',
      },
      {
        'week': 10,
        'title': 'Dynamic Programming I: Optimal Substructure',
        'sub': 'Memoization vs Tabulation, 0/1 Knapsack, LCS',
        'status': 'Upcoming',
        'tag': 'Dynamic Prog.',
        'slides': 'Lecture 17 Slides.pdf',
        'reading': 'CLRS Ch. 15',
      },
    ];

    return Column(
      children: modules.map((m) {
        final week = m['week'] as int;
        final isCompleted = _completedWeeks.contains(week);
        final status = m['status'] as String;
        final isActive = status == 'Active Node';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: customColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? customColors.academic.withValues(alpha: 0.6)
                  : customColors.cardBorder,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isActive,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (isCompleted) {
                      _completedWeeks.remove(week);
                    } else {
                      _completedWeeks.add(week);
                    }
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? customColors.primaryAccent
                        : customColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? customColors.primaryAccent
                          : customColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text(
                            '$week',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: customColors.textSecondary,
                            ),
                          ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      m['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: customColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? customColors.academic.withValues(alpha: 0.12)
                          : isCompleted
                              ? customColors.primaryAccent
                                  .withValues(alpha: 0.12)
                              : customColors.cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCompleted
                          ? 'COMPLETED'
                          : isActive
                              ? 'ACTIVE'
                              : 'WEEK $week',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isCompleted
                            ? customColors.primaryAccent
                            : isActive
                                ? customColors.academic
                                : customColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                m['sub'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: customColors.textSecondary,
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: customColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _buildResourceRow(
                        context,
                        icon: Icons.picture_as_pdf_outlined,
                        title: m['slides'] as String,
                        actionText: 'View Slides',
                        color: customColors.academic,
                      ),
                      const Divider(height: 1),
                      _buildResourceRow(
                        context,
                        icon: Icons.menu_book_outlined,
                        title: m['reading'] as String,
                        actionText: 'Read Ch.',
                        color: customColors.primaryAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResourceRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String actionText,
    required Color color,
  }) {
    final customColors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: customColors.textSecondary,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening $title...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                actionText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemSetTracker(BuildContext context) {
    final customColors = AppColors.of(context);

    final deliverables = [
      {
        'id': 1,
        'name': 'PS #1: Asymptotic Analysis & Recurrences',
        'due': 'Completed • Score: 48/50',
        'status': 'Graded',
        'color': customColors.primaryAccent,
      },
      {
        'id': 2,
        'name': 'PS #2: Divide & Conquer Implementations',
        'due': 'Completed • Score: 50/50',
        'status': 'Graded',
        'color': customColors.primaryAccent,
      },
      {
        'id': 3,
        'name': 'Lab 3: Graph Traversal in C++ & Benchmarking',
        'due': 'Completed • Score: 47/50',
        'status': 'Graded',
        'color': customColors.primaryAccent,
      },
      {
        'id': 4,
        'name': 'PS #4: Dynamic Programming & Optimal Substructure',
        'due': 'Due: Friday 23:59 • Weight: 10%',
        'status': 'In Progress',
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 5,
        'name': 'PS #5: Greedy Algorithms & Huffman Coding',
        'due': 'Due: Next Week • Assigned',
        'status': 'Pending',
        'color': customColors.textMuted,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: customColors.cardBorder),
      ),
      child: Column(
        children: deliverables.map((d) {
          final id = d['id'] as int;
          final isDone = _completedProblemSets.contains(id);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: customColors.cardBorder.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (isDone) {
                        _completedProblemSets.remove(id);
                      } else {
                        _completedProblemSets.add(id);
                      }
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDone
                          ? customColors.primaryAccent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDone
                            ? customColors.primaryAccent
                            : customColors.cardBorder,
                        width: 1.5,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isDone
                              ? customColors.textMuted
                              : customColors.textPrimary,
                        ),
                      ),
                      Text(
                        d['due'] as String,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: customColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (d['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    d['status'] as String,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: d['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExamVaultGrid(BuildContext context) {
    final customColors = AppColors.of(context);

    final vaultItems = [
      {
        'title': '2025 Midterm Exam + Key',
        'type': 'PDF Solutions (45 pgs)',
        'icon': Icons.description_outlined,
        'action': () => _showPdfViewerModal(context, '2025 Midterm Exam'),
      },
      {
        'title': 'Master Theorem Matrix',
        'type': 'Formula Cheatsheet',
        'icon': Icons.calculate_outlined,
        'action': () => _showCheatsheetModal(context),
      },
      {
        'title': 'Graph Complexity O(V+E)',
        'type': 'Review Summary Card',
        'icon': Icons.hub_outlined,
        'action': () => _showCheatsheetModal(context),
      },
      {
        'title': 'Timed 90-Min Mock Exam',
        'type': 'Interactive Simulator',
        'icon': Icons.quiz_outlined,
        'action': () => _showExamSimulationModal(context),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemCount: vaultItems.length,
      itemBuilder: (context, index) {
        final item = vaultItems[index];
        return InkWell(
          onTap: item['action'] as VoidCallback,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: customColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: customColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 20,
                  color: customColors.academic,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: customColors.textPrimary,
                      ),
                    ),
                    Text(
                      item['type'] as String,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: customColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String badge,
  }) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badge,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: customColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showCheatsheetModal(BuildContext context) {
    final customColors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Master Theorem Quick Reference',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: customColors.cardBorder),
                  ),
                  child: Text(
                    'T(n) = a T(n/b) + f(n)\n\n'
                    '• Case 1: If f(n) = O(n^(log_b(a) - ε)) → T(n) = Θ(n^(log_b(a)))\n'
                    '• Case 2: If f(n) = Θ(n^(log_b(a)) * log^k(n)) → T(n) = Θ(n^(log_b(a)) * log^(k+1)(n))\n'
                    '• Case 3: If f(n) = Ω(n^(log_b(a) + ε)) and a*f(n/b) <= c*f(n) → T(n) = Θ(f(n))',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      height: 1.5,
                      color: customColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close Cheat Table'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExamSimulationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.quiz, size: 36, color: Color(0xFF38BDF8)),
                const SizedBox(height: 12),
                Text(
                  'Launch 90-Min Midterm Simulation',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Includes 5 algorithmic proof problems, runtime analysis questions, and dynamic programming pseudocode prompts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulation armed: 90-minute timer started.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Start Timed Exam Mode'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPdfViewerModal(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing $title (Solutions PDF)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
