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
    // Phase 1 Clean-Slate Purge: All mock seed data removed.
    // Phase 2 Onboarding flow will populate initial user-configured data.
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
    // Compute next upcoming class from real academic events
    try {
      if (Hive.isBoxOpen(academicBoxName)) {
        final now = DateTime.now();
        final todayDow = now.weekday; // 1=Mon, 2=Tue, ..., 7=Sun
        final nowMinutes = now.hour * 60 + now.minute;

        final todayEvents = Hive.box<AcademicEvent>(academicBoxName)
            .values
            .where((e) => e.dayOfWeek == todayDow && !e.isCompleted)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        for (final ev in todayEvents) {
          final parts = ev.startTime.split(':');
          if (parts.length >= 2) {
            final h = int.tryParse(parts[0]) ?? 0;
            final m = int.tryParse(parts[1]) ?? 0;
            final eventMinutes = h * 60 + m;
            if (eventMinutes > nowMinutes) {
              final diff = eventMinutes - nowMinutes;
              final startsIn = diff <= 60
                  ? 'Starts in $diff min'
                  : 'Starts in ${diff ~/ 60}h ${diff % 60}m';
              return HeroClass(
                startsIn: startsIn,
                courseCode: ev.courseCode,
                sessionType: ev.type.name,
                title: ev.title,
                location: ev.room,
                instructor: ev.instructor,
                slidesDownloaded: false,
                assignmentDueText: ev.syllabusNotes,
              );
            }
          }
        }
      }
    } catch (_) {}

    return const HeroClass(
      startsIn: 'No upcoming class',
      courseCode: '',
      sessionType: '',
      title: 'All clear for today',
      location: '',
      instructor: '',
      slidesDownloaded: false,
      assignmentDueText: '',
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
    // Phase 1: Return empty. Phase 3 will compute from todayFreeGapsProvider.
    return const [];
  }

  @override
  SyncSettings getSyncSettings() {
    try {
      if (Hive.isBoxOpen(settingsBoxName)) {
        final box = Hive.box(settingsBoxName);
        return SyncSettings(
          accountEmail: box.get('accountEmail',
              defaultValue: 'Not connected'),
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
      accountEmail: 'Not connected',
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
