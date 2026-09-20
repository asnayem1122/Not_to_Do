import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine_models.dart';

/// Abstract contract for local persistent operations.
abstract class RoutineRepository {
  Future<void> init();
  List<TimelineBlock> getTodayTimeline();
  HeroClass getHeroUpcomingClass();
  List<AcademicEvent> getAllEvents();
  List<AcademicEvent> getEventsForDay(int dayOfWeek);
  List<DayCycle> getWeeklyCycle();
  List<HabitItem> getAllHabits();
  List<HabitItem> getAntiHabits();
  List<HabitItem> getPositiveHabits();
  List<AiGapSlot> getAiGapSlots();
  SyncSettings getSyncSettings();

  // Academic Event CRUD
  Future<void> createEvent(AcademicEvent event);
  Future<void> batchCreateEvents(List<AcademicEvent> events);
  Future<void> updateEvent(AcademicEvent event);
  Future<void> deleteEvent(String id);
  Future<void> toggleEventCompletion(String id);

  // Habit CRUD & Streak Controls
  Future<void> createHabit(HabitItem habit);
  Future<void> updateHabit(HabitItem habit);
  Future<void> deleteHabit(String id);
  Future<void> toggleHabitDefend(String habitId, DateTime date);
  Future<void> manualUpdateStreak(String habitId, int newStreak);

  // Timeline Block CRUD
  Future<void> createTimelineBlock(TimelineBlock block);
  Future<void> batchCreateTimelineBlocks(List<TimelineBlock> blocks);
  Future<void> replaceAllTimelineBlocks(List<TimelineBlock> blocks);
  Future<void> updateTimelineBlock(TimelineBlock block);
  Future<void> deleteTimelineBlock(String id);
  Future<void> toggleTimelineBlockCompletion(String id);

  // Settings
  Future<void> updateSyncSettings(SyncSettings settings);
}

/// Hive-backed persistent repository with first-launch Stitch data seeding.
class HiveRoutineRepository implements RoutineRepository {
  static const String academicBoxName = 'academic_events_box';
  static const String habitsBoxName = 'habits_box';
  static const String timelineBoxName = 'timeline_blocks_box';
  static const String settingsBoxName = 'settings_box';

  Box<AcademicEvent>? _academicBox;
  Box<HabitItem>? _habitsBox;
  Box<TimelineBlock>? _timelineBox;
  Box? _settingsBox;

  Box<AcademicEvent> get academicBox => _academicBox ?? Hive.box<AcademicEvent>(academicBoxName);
  Box<HabitItem> get habitsBox => _habitsBox ?? Hive.box<HabitItem>(habitsBoxName);
  Box<TimelineBlock> get timelineBox => _timelineBox ?? Hive.box<TimelineBlock>(timelineBoxName);
  Box get settingsBox => _settingsBox ?? Hive.box(settingsBoxName);

  /// Safely opens a Hive box with timeout and corruption recovery.
  static Future<Box<T>> openBoxWithRecovery<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    try {
      return await Hive.openBox<T>(boxName).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Hive box "$boxName" failed to open or corrupted ($e). Attempting recovery...');
      try {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<T>(boxName);
      } catch (recoveryErr) {
        debugPrint('Critical recovery error for "$boxName": $recoveryErr');
        rethrow;
      }
    }
  }

  /// Opens all boxes required by HiveRoutineRepository in parallel.
  static Future<void> openAllBoxes() async {
    await Future.wait([
      openBoxWithRecovery<AcademicEvent>(academicBoxName),
      openBoxWithRecovery<HabitItem>(habitsBoxName),
      openBoxWithRecovery<TimelineBlock>(timelineBoxName),
      openBoxWithRecovery(settingsBoxName),
    ]).timeout(const Duration(seconds: 5));
  }

  @override
  Future<void> init() async {
    if (!Hive.isBoxOpen(academicBoxName) ||
        !Hive.isBoxOpen(habitsBoxName) ||
        !Hive.isBoxOpen(timelineBoxName) ||
        !Hive.isBoxOpen(settingsBoxName)) {
      await openAllBoxes();
    }

    _academicBox = Hive.box<AcademicEvent>(academicBoxName);
    _habitsBox = Hive.box<HabitItem>(habitsBoxName);
    _timelineBox = Hive.box<TimelineBlock>(timelineBoxName);
    _settingsBox = Hive.box(settingsBoxName);

    await _seedInitialDataIfEmpty();
  }

  Future<void> _seedInitialDataIfEmpty() async {
    // 1. Seed Academic Events if empty
    if (academicBox.isEmpty) {
      final initialEvents = [
        // Tuesday (dayOfWeek: 2)
        AcademicEvent(
          id: 'ae-tue-1',
          courseCode: 'CSE 3101',
          title: 'Database Systems',
          type: AcademicEventType.lecture,
          startTime: '09:00',
          endTime: '10:30',
          room: 'Room 301, North Tower',
          instructor: 'Prof. Sarah Khan',
          dayOfWeek: 2,
          isCompleted: true,
          syncToCalendar: true,
        ),
        AcademicEvent(
          id: 'ae-tue-2',
          courseCode: 'CSE 3102',
          title: 'Software Engineering Lab',
          type: AcademicEventType.sessionalLab,
          startTime: '11:00',
          endTime: '13:30',
          room: 'Lab 3, Software Wing',
          instructor: 'Dr. Alex Mercer',
          dayOfWeek: 2,
          syllabusNotes: 'Bring Project Wireframes & verified Git repo push',
          isCompleted: false,
          syncToCalendar: true,
        ),
        AcademicEvent(
          id: 'ae-tue-3',
          courseCode: 'MATH 2205',
          title: 'Discrete Mathematics',
          type: AcademicEventType.tutorial,
          startTime: '14:30',
          endTime: '16:00',
          room: 'Room 205',
          instructor: 'TA Emily Thornton',
          dayOfWeek: 2,
          isCompleted: false,
          syncToCalendar: true,
        ),

        // Monday (dayOfWeek: 1)
        AcademicEvent(
          id: 'ae-mon-1',
          courseCode: 'CSE 2101',
          title: 'Object Oriented Programming',
          type: AcademicEventType.lecture,
          startTime: '09:00',
          endTime: '10:30',
          room: 'Room 401',
          instructor: 'Dr. Hasan Ali',
          dayOfWeek: 1,
          isCompleted: true,
          syncToCalendar: true,
        ),
        AcademicEvent(
          id: 'ae-mon-2',
          courseCode: 'MATH 2101',
          title: 'Linear Algebra & Matrices',
          type: AcademicEventType.lecture,
          startTime: '11:00',
          endTime: '12:30',
          room: 'Hall B',
          instructor: 'Prof. David Clark',
          dayOfWeek: 1,
          isCompleted: true,
          syncToCalendar: true,
        ),
        AcademicEvent(
          id: 'ae-mon-3',
          courseCode: 'CSE 2102',
          title: 'OOP Java Lab',
          type: AcademicEventType.sessionalLab,
          startTime: '13:30',
          endTime: '15:30',
          room: 'Lab 2',
          instructor: 'TA Michael Vance',
          dayOfWeek: 1,
          isCompleted: false,
          syncToCalendar: true,
        ),
        AcademicEvent(
          id: 'ae-mon-4',
          courseCode: 'ENG 1101',
          title: 'Technical Communication',
          type: AcademicEventType.lecture,
          startTime: '16:00',
          endTime: '17:00',
          room: 'Room 102',
          instructor: 'Ms. Clara Oswald',
          dayOfWeek: 1,
          isCompleted: false,
          syncToCalendar: true,
        ),

        // Wednesday (dayOfWeek: 3)
        AcademicEvent(
          id: 'ae-wed-1',
          courseCode: 'CSE 3201',
          title: 'Operating Systems',
          type: AcademicEventType.lecture,
          startTime: '10:00',
          endTime: '11:30',
          room: 'Room 305',
          instructor: 'Prof. Alan Turing',
          dayOfWeek: 3,
          isCompleted: false,
          syncToCalendar: true,
        ),
        AcademicEvent(
          id: 'ae-wed-2',
          courseCode: 'CSE 3202',
          title: 'Operating Systems Kernel Lab',
          type: AcademicEventType.sessionalLab,
          startTime: '14:00',
          endTime: '16:00',
          room: 'Lab 1, Systems Wing',
          instructor: 'Dr. Linus Vance',
          dayOfWeek: 3,
          isCompleted: false,
          syncToCalendar: true,
        ),

        // Thursday (dayOfWeek: 4)
        AcademicEvent(
          id: 'ae-thu-1',
          courseCode: 'CSE 3101',
          title: 'Database Systems (Relational Model)',
          type: AcademicEventType.lecture,
          startTime: '09:00',
          endTime: '10:30',
          room: 'Room 301',
          instructor: 'Prof. Sarah Khan',
          dayOfWeek: 4,
          isCompleted: false,
          syncToCalendar: true,
        ),
        AcademicEvent(
          id: 'ae-thu-2',
          courseCode: 'CSE 3301',
          title: 'Computer Networks',
          type: AcademicEventType.lecture,
          startTime: '11:00',
          endTime: '12:30',
          room: 'Hall A',
          instructor: 'Dr. Robert Metcalfe',
          dayOfWeek: 4,
          isCompleted: false,
          syncToCalendar: true,
        ),
        AcademicEvent(
          id: 'ae-thu-3',
          courseCode: 'MATH 2205',
          title: 'Discrete Mathematics Problem Set',
          type: AcademicEventType.tutorial,
          startTime: '13:30',
          endTime: '15:00',
          room: 'Room 205',
          instructor: 'TA Emily Thornton',
          dayOfWeek: 4,
          isCompleted: false,
          syncToCalendar: true,
        ),
        AcademicEvent(
          id: 'ae-thu-4',
          courseCode: 'CSE 3302',
          title: 'Cisco Packet Tracer Lab',
          type: AcademicEventType.sessionalLab,
          startTime: '15:30',
          endTime: '17:00',
          room: 'Networks Lab',
          instructor: 'Engr. John Doe',
          dayOfWeek: 4,
          isCompleted: false,
          syncToCalendar: true,
        ),

        // Friday (dayOfWeek: 5)
        AcademicEvent(
          id: 'ae-fri-1',
          courseCode: 'CSE 3401',
          title: 'Artificial Intelligence & Search Algorithms',
          type: AcademicEventType.lecture,
          startTime: '09:30',
          endTime: '11:30',
          room: 'Auditorium 1',
          instructor: 'Prof. Stuart Russell',
          dayOfWeek: 5,
          isCompleted: false,
          syncToCalendar: true,
        ),
      ];

      for (final ev in initialEvents) {
        await academicBox.put(ev.id, ev);
      }
    }

    // 2. Seed Habits if empty
    if (habitsBox.isEmpty) {
      final initialHabits = [
        HabitItem(
          id: 'h-anti-1',
          title: "Don't open Instagram / TikTok before 6 PM",
          type: HabitType.antiHabit,
          category: 'Social Media Lockout',
          streakCount: 9,
          shieldRuleDescription:
              'Academic Focus Block • Priority 1 Perimeter Guard',
          targetDays: [1, 2, 3, 4, 5, 6, 7],
          completedDates: [
            DateTime.now().subtract(const Duration(days: 1)),
            DateTime.now(),
          ],
        ),
        HabitItem(
          id: 'h-anti-2',
          title: "Don't sleep past 7:30 AM",
          type: HabitType.antiHabit,
          category: 'Morning Momentum',
          streakCount: 14,
          shieldRuleDescription:
              'Verified at 6:45 AM today (45m before target perimeter)',
          targetDays: [1, 2, 3, 4, 5],
          completedDates: [DateTime.now()],
        ),
        HabitItem(
          id: 'h-anti-3',
          title: 'No gaming during semester exam prep weeks',
          type: HabitType.antiHabit,
          category: 'Focus Protocol',
          streakCount: 21,
          shieldRuleDescription:
              '12 days left until finals complete • Steam app sandbox locked',
          targetDays: [1, 2, 3, 4, 5, 6, 7],
        ),
        HabitItem(
          id: 'h-pos-1',
          title: 'Solve 2 Graph Theory problems',
          type: HabitType.positiveHabit,
          category: 'CS 301 Core Practice',
          streakCount: 6,
          shieldRuleDescription:
              'LeetCode #133 (Clone Graph), #207 (Course Schedule) completed',
          targetDays: [1, 2, 3, 4, 5, 6, 7],
          completedDates: [
            DateTime.now().subtract(const Duration(days: 6)),
            DateTime.now().subtract(const Duration(days: 5)),
            DateTime.now().subtract(const Duration(days: 4)),
            DateTime.now().subtract(const Duration(days: 3)),
            DateTime.now().subtract(const Duration(days: 2)),
            DateTime.now().subtract(const Duration(days: 1)),
          ],
        ),
        HabitItem(
          id: 'h-pos-2',
          title: 'Drink 2.5L Water during lectures',
          type: HabitType.positiveHabit,
          category: 'Biometric Readiness',
          streakCount: 5,
          shieldRuleDescription:
              '1.8L / 2.5L target logged • 700ml remaining before 8 PM',
          targetDays: [1, 2, 3, 4, 5],
          completedDates: [DateTime.now()],
        ),
      ];

      for (final h in initialHabits) {
        await habitsBox.put(h.id, h);
      }
    }

    // 3. Seed Timeline Blocks if empty
    if (timelineBox.isEmpty) {
      final initialTimeline = [
        TimelineBlock(
          id: 'tb-1',
          title: 'Data Structures: Graph Theory Lecture',
          startTime: '08:30 AM',
          endTime: '10:00 AM',
          type: TimelineBlockType.academicClass,
          location: 'Hall 101',
          subtitle: 'CSE 2201 • Covered Dijkstra and topological sorting',
          isCompleted: true,
          badgeText: 'Completed',
        ),
        TimelineBlock(
          id: 'tb-2',
          title: 'LeetCode & Competitive Track',
          startTime: '11:00 AM',
          endTime: '12:00 PM',
          type: TimelineBlockType.routineFocus,
          subtitle: 'Target achieved: 2 DP Problems Solved cleanly',
          isCompleted: true,
          badgeText: 'Routine Focus',
        ),
        TimelineBlock(
          id: 'tb-3',
          title: 'Doomscrolling or Social Reels during Lunch Break',
          startTime: '01:00 PM',
          endTime: '02:00 PM',
          type: TimelineBlockType.antiHabitShield,
          subtitle: 'Lunch break digital detox guard',
          streakDays: 7,
          replacementTrigger:
              'Walk around courtyard + 10 pages physical book reading.',
          badgeText: '🔥 7d clean streak',
        ),
        TimelineBlock(
          id: 'tb-4',
          title: 'Study Group: Distributed Systems Project',
          startTime: '03:00 PM',
          endTime: '04:30 PM',
          type: TimelineBlockType.calendarSync,
          location: 'Central Library Discussion Room A',
          subtitle: 'G-Cal Synced team collaboration session',
          badgeText: 'Google Calendar',
        ),
      ];

      for (final tb in initialTimeline) {
        await timelineBox.put(tb.id, tb);
      }
    }
  }

  // ==========================================
  // READ OPERATIONS (Fault-Tolerant & ANR-Safe)
  // ==========================================
  @override
  List<TimelineBlock> getTodayTimeline() {
    try {
      if (Hive.isBoxOpen(timelineBoxName)) {
        return Hive.box<TimelineBlock>(timelineBoxName).values.toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  HeroClass getHeroUpcomingClass() {
    return const HeroClass(
      startsIn: 'Starts in 20 min',
      courseCode: 'CSE 2201',
      sessionType: 'Lab Session',
      title: 'Algorithms & Data Structures Lab',
      location: 'Room 402, Academic Bldg 2',
      instructor: 'Prof. Rahman',
      slidesDownloaded: true,
      assignmentDueText: 'Assignment 3 Due Today',
    );
  }

  @override
  List<AcademicEvent> getAllEvents() {
    try {
      if (Hive.isBoxOpen(academicBoxName)) {
        return Hive.box<AcademicEvent>(academicBoxName).values.toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  List<AcademicEvent> getEventsForDay(int dayOfWeek) {
    try {
      if (Hive.isBoxOpen(academicBoxName)) {
        return Hive.box<AcademicEvent>(academicBoxName)
            .values
            .where((e) => e.dayOfWeek == dayOfWeek)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      }
    } catch (_) {}
    return [];
  }

  @override
  List<DayCycle> getWeeklyCycle() {
    // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
    final days = [
      {'code': 'SUN', 'index': 7},
      {'code': 'MON', 'index': 1},
      {'code': 'TUE', 'index': 2},
      {'code': 'WED', 'index': 3},
      {'code': 'THU', 'index': 4},
      {'code': 'FRI', 'index': 5},
    ];

    List<AcademicEvent> all = getAllEvents();
    return days.map((d) {
      final idx = d['index'] as int;
      final count = all.where((e) => e.dayOfWeek == idx).length;
      final label = count == 0 ? 'Off' : '$count cls';
      return DayCycle(
        day: d['code'] as String,
        classCountLabel: label,
        classCount: count,
        dayIndex: idx,
      );
    }).toList();
  }

  @override
  List<HabitItem> getAllHabits() {
    try {
      if (Hive.isBoxOpen(habitsBoxName)) {
        return Hive.box<HabitItem>(habitsBoxName).values.toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  List<HabitItem> getAntiHabits() {
    try {
      if (Hive.isBoxOpen(habitsBoxName)) {
        return Hive.box<HabitItem>(habitsBoxName)
            .values
            .where((h) => h.type == HabitType.antiHabit)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  List<HabitItem> getPositiveHabits() {
    try {
      if (Hive.isBoxOpen(habitsBoxName)) {
        return Hive.box<HabitItem>(habitsBoxName)
            .values
            .where((h) => h.type == HabitType.positiveHabit)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  List<AiGapSlot> getAiGapSlots() {
    return const [
      AiGapSlot(
        id: 'gap-1',
        gapName: 'GAP 1: 10:30 AM – 11:00 AM',
        tag: '30 min buffer',
        recommendation:
            'Recommended: Review Data Structure Lab slides & Hydrate before Algorithms discussion.',
      ),
      AiGapSlot(
        id: 'gap-2',
        gapName: 'GAP 2: 01:30 PM – 02:30 PM',
        tag: '60 min post-lab',
        recommendation:
            'Recommended: 45 min LeetCode Graph Theory session. Distraction shield fully enforced.',
      ),
    ];
  }

  @override
  SyncSettings getSyncSettings() {
    try {
      if (Hive.isBoxOpen(settingsBoxName)) {
        final box = Hive.box(settingsBoxName);
        return SyncSettings(
          accountEmail: box.get('accountEmail',
              defaultValue: 'alex.student@university.edu'),
          lastSyncTime:
              box.get('lastSyncTime', defaultValue: '4m ago'),
          is2WayLiveSyncActive:
              box.get('is2WayLiveSyncActive', defaultValue: true),
          autoPushRoutine:
              box.get('autoPushRoutine', defaultValue: true),
          autoBlockDistractions:
              box.get('autoBlockDistractions', defaultValue: true),
          classReminderAlerts:
              box.get('classReminderAlerts', defaultValue: true),
        );
      }
    } catch (_) {}

    return const SyncSettings(
      accountEmail: 'alex.student@university.edu',
      lastSyncTime: 'Just now',
      is2WayLiveSyncActive: true,
      autoPushRoutine: true,
      autoBlockDistractions: true,
      classReminderAlerts: true,
    );
  }

  // ==========================================
  // WRITE & CRUD OPERATIONS
  // ==========================================
  @override
  Future<void> createEvent(AcademicEvent event) async {
    await academicBox.put(event.id, event);
  }

  @override
  Future<void> batchCreateEvents(List<AcademicEvent> events) async {
    final entries = {for (final e in events) e.id: e};
    await academicBox.putAll(entries);
  }

  @override
  Future<void> updateEvent(AcademicEvent event) async {
    await academicBox.put(event.id, event);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await academicBox.delete(id);
  }

  @override
  Future<void> toggleEventCompletion(String id) async {
    final ev = academicBox.get(id);
    if (ev != null) {
      final updated = ev.copyWith(isCompleted: !ev.isCompleted);
      await academicBox.put(id, updated);
    }
  }

  @override
  Future<void> createHabit(HabitItem habit) async {
    await habitsBox.put(habit.id, habit);
  }

  @override
  Future<void> updateHabit(HabitItem habit) async {
    await habitsBox.put(habit.id, habit);
  }

  @override
  Future<void> deleteHabit(String id) async {
    await habitsBox.delete(id);
  }

  @override
  Future<void> toggleHabitDefend(String habitId, DateTime date) async {
    final habit = habitsBox.get(habitId);
    if (habit != null) {
      final isAlreadyCompleted = habit.isCompletedOn(date);
      final updatedDates = List<DateTime>.from(habit.completedDates);
      int newStreak = habit.streakCount;

      if (isAlreadyCompleted) {
        updatedDates.removeWhere((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
        if (newStreak > 0) newStreak--;
      } else {
        updatedDates.add(date);
        newStreak++;
      }

      final updated = habit.copyWith(
        completedDates: updatedDates,
        streakCount: newStreak,
      );
      await habitsBox.put(habitId, updated);
    }
  }

  @override
  Future<void> manualUpdateStreak(String habitId, int newStreak) async {
    final habit = habitsBox.get(habitId);
    if (habit != null) {
      final updated = habit.copyWith(streakCount: newStreak.clamp(0, 9999));
      await habitsBox.put(habitId, updated);
    }
  }

  @override
  Future<void> createTimelineBlock(TimelineBlock block) async {
    await timelineBox.put(block.id, block);
  }

  @override
  Future<void> batchCreateTimelineBlocks(List<TimelineBlock> blocks) async {
    final entries = {for (final b in blocks) b.id: b};
    await timelineBox.putAll(entries);
  }

  @override
  Future<void> replaceAllTimelineBlocks(List<TimelineBlock> blocks) async {
    await timelineBox.clear();
    final entries = {for (final b in blocks) b.id: b};
    await timelineBox.putAll(entries);
  }

  @override
  Future<void> updateTimelineBlock(TimelineBlock block) async {
    await timelineBox.put(block.id, block);
  }

  @override
  Future<void> deleteTimelineBlock(String id) async {
    await timelineBox.delete(id);
  }

  @override
  Future<void> toggleTimelineBlockCompletion(String id) async {
    final block = timelineBox.get(id);
    if (block != null) {
      final updated = block.copyWith(isCompleted: !block.isCompleted);
      await timelineBox.put(id, updated);
    }
  }

  @override
  Future<void> updateSyncSettings(SyncSettings settings) async {
    await settingsBox.put('accountEmail', settings.accountEmail);
    await settingsBox.put('lastSyncTime', settings.lastSyncTime);
    await settingsBox.put(
        'is2WayLiveSyncActive', settings.is2WayLiveSyncActive);
    await settingsBox.put('autoPushRoutine', settings.autoPushRoutine);
    await settingsBox.put(
        'autoBlockDistractions', settings.autoBlockDistractions);
    await settingsBox.put(
        'classReminderAlerts', settings.classReminderAlerts);
  }
}
