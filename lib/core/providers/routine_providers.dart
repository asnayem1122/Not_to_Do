import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/routine_models.dart';
import '../repositories/routine_repository.dart';
import '../services/calendar_sync_service.dart';
import '../services/notification_service.dart';
import '../services/schedule_gap_service.dart';

// Repository Provider
final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return HiveRoutineRepository();
});

// App Theme Mode Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// =========================================================================
// ACADEMIC EVENTS STATE (Hive-backed CRUD)
// =========================================================================
class AcademicEventsNotifier extends StateNotifier<List<AcademicEvent>> {
  AcademicEventsNotifier(this._repository)
      : super(_repository.getAllEvents());

  final RoutineRepository _repository;

  Future<void> reload() async {
    state = _repository.getAllEvents();
  }

  Future<void> createEvent(AcademicEvent event) async {
    await _repository.createEvent(event);
    state = _repository.getAllEvents();
  }

  Future<void> batchAddEvents(List<AcademicEvent> events) async {
    await _repository.batchCreateEvents(events);
    state = _repository.getAllEvents();
  }

  Future<void> updateEvent(AcademicEvent event) async {
    await _repository.updateEvent(event);
    state = _repository.getAllEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _repository.deleteEvent(id);
    state = _repository.getAllEvents();
  }

  Future<void> toggleCompletion(String id) async {
    await _repository.toggleEventCompletion(id);
    state = _repository.getAllEvents();
  }

  Future<bool> toggleCalendarSync(
    String id, {
    required CalendarSyncService calService,
    required NotificationService notifService,
  }) async {
    final all = _repository.getAllEvents();
    final idx = all.indexWhere((e) => e.id == id);
    if (idx == -1) return false;

    final event = all[idx];
    final newSync = !event.syncToCalendar;
    String? calId = event.calendarEventId;

    if (newSync) {
      calId = await calService.exportEventToCalendar(event.copyWith(syncToCalendar: true));
      await notifService.scheduleEventAlerts(
        event.copyWith(syncToCalendar: true, calendarEventId: calId),
      );
    } else {
      if (calId != null) {
        await calService.deleteCalendarEvent(calId);
        calId = null;
      }
      await notifService.cancelEventAlerts(id);
    }

    final updated = event.copyWith(
      syncToCalendar: newSync,
      calendarEventId: calId,
    );
    await _repository.updateEvent(updated);
    state = _repository.getAllEvents();
    return newSync;
  }
}

final academicEventsProvider =
    StateNotifierProvider<AcademicEventsNotifier, List<AcademicEvent>>((ref) {
  final repo = ref.watch(routineRepositoryProvider);
  return AcademicEventsNotifier(repo);
});

// Day Picker Provider (SUN, MON, TUE, WED, THU, FRI)
final selectedDayProvider = StateProvider<String>((ref) => 'TUE');

// Map day code to 1-7 index (1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun)
int dayCodeToIndex(String code) {
  switch (code) {
    case 'MON':
      return 1;
    case 'TUE':
      return 2;
    case 'WED':
      return 3;
    case 'THU':
      return 4;
    case 'FRI':
      return 5;
    case 'SAT':
      return 6;
    case 'SUN':
      return 7;
    default:
      return 2;
  }
}

final currentDayEventsProvider = Provider<List<AcademicEvent>>((ref) {
  final selectedDay = ref.watch(selectedDayProvider);
  final allEvents = ref.watch(academicEventsProvider);
  final dayIdx = dayCodeToIndex(selectedDay);

  final list = allEvents.where((e) => e.dayOfWeek == dayIdx).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  return list;
});

final weeklyCycleProvider = Provider<List<DayCycle>>((ref) {
  final allEvents = ref.watch(academicEventsProvider);
  final days = [
    {'code': 'SUN', 'index': 7},
    {'code': 'MON', 'index': 1},
    {'code': 'TUE', 'index': 2},
    {'code': 'WED', 'index': 3},
    {'code': 'THU', 'index': 4},
    {'code': 'FRI', 'index': 5},
  ];

  return days.map((d) {
    final idx = d['index'] as int;
    final count = allEvents.where((e) => e.dayOfWeek == idx).length;
    final label = count == 0 ? 'Off' : '$count cls';
    return DayCycle(
      day: d['code'] as String,
      classCountLabel: label,
      classCount: count,
      dayIndex: idx,
    );
  }).toList();
});

final isLiveSyncedBarActiveProvider = StateProvider<bool>((ref) => true);

// =========================================================================
// HABIT ITEM STATE (Hive-backed CRUD & Manual Streak Controls)
// =========================================================================
class HabitsNotifier extends StateNotifier<List<HabitItem>> {
  HabitsNotifier(this._repository) : super(_repository.getAllHabits());

  final RoutineRepository _repository;

  Future<void> reload() async {
    state = _repository.getAllHabits();
  }

  Future<void> createHabit(HabitItem habit) async {
    await _repository.createHabit(habit);
    state = _repository.getAllHabits();
  }

  Future<void> updateHabit(HabitItem habit) async {
    await _repository.updateHabit(habit);
    state = _repository.getAllHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    state = _repository.getAllHabits();
  }

  Future<void> toggleDefend(String id, DateTime date) async {
    await _repository.toggleHabitDefend(id, date);
    state = _repository.getAllHabits();
  }

  Future<void> manualUpdateStreak(String id, int newStreak) async {
    await _repository.manualUpdateStreak(id, newStreak);
    state = _repository.getAllHabits();
  }
}

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, List<HabitItem>>((ref) {
  final repo = ref.watch(routineRepositoryProvider);
  return HabitsNotifier(repo);
});

final antiHabitsProvider = Provider<List<HabitItem>>((ref) {
  final all = ref.watch(habitsProvider);
  return all.where((h) => h.type == HabitType.antiHabit).toList();
});

final positiveHabitsProvider = Provider<List<HabitItem>>((ref) {
  final all = ref.watch(habitsProvider);
  return all.where((h) => h.type == HabitType.positiveHabit).toList();
});

// =========================================================================
// TODAY TIMELINE STATE (Hive-backed CRUD)
// =========================================================================
enum TimelineFilter { all, classes, habits, defended }

final timelineFilterProvider =
    StateProvider<TimelineFilter>((ref) => TimelineFilter.all);

class TimelineNotifier extends StateNotifier<List<TimelineBlock>> {
  TimelineNotifier(this._repository) : super(_repository.getTodayTimeline());

  final RoutineRepository _repository;

  Future<void> reload() async {
    state = _repository.getTodayTimeline();
  }

  Future<void> toggleBlockCompletion(String id) async {
    await _repository.toggleTimelineBlockCompletion(id);
    state = _repository.getTodayTimeline();
  }

  Future<void> addBlock(TimelineBlock newBlock) async {
    await _repository.createTimelineBlock(newBlock);
    state = _repository.getTodayTimeline();
  }

  Future<void> batchAddBlocks(List<TimelineBlock> blocks) async {
    await _repository.batchCreateTimelineBlocks(blocks);
    state = _repository.getTodayTimeline();
  }

  Future<void> replaceAllBlocks(List<TimelineBlock> blocks) async {
    await _repository.replaceAllTimelineBlocks(blocks);
    state = _repository.getTodayTimeline();
  }

  Future<void> updateBlock(TimelineBlock block) async {
    await _repository.updateTimelineBlock(block);
    state = _repository.getTodayTimeline();
  }

  Future<void> deleteBlock(String id) async {
    await _repository.deleteTimelineBlock(id);
    state = _repository.getTodayTimeline();
  }
}

final timelineBlocksProvider =
    StateNotifierProvider<TimelineNotifier, List<TimelineBlock>>((ref) {
  final repo = ref.watch(routineRepositoryProvider);
  return TimelineNotifier(repo);
});

final filteredTimelineProvider = Provider<List<TimelineBlock>>((ref) {
  final blocks = ref.watch(timelineBlocksProvider);
  final filter = ref.watch(timelineFilterProvider);

  switch (filter) {
    case TimelineFilter.classes:
      return blocks
          .where((b) =>
              b.type == TimelineBlockType.academicClass ||
              b.type == TimelineBlockType.calendarSync)
          .toList();
    case TimelineFilter.habits:
      return blocks
          .where((b) => b.type == TimelineBlockType.routineFocus)
          .toList();
    case TimelineFilter.defended:
      return blocks
          .where((b) => b.type == TimelineBlockType.antiHabitShield)
          .toList();
    case TimelineFilter.all:
      return blocks;
  }
});

final heroClassProvider = Provider<HeroClass>((ref) {
  return ref.watch(routineRepositoryProvider).getHeroUpcomingClass();
});

// =========================================================================
// SYNC & AI GUARD SETTINGS (Hive-backed)
// =========================================================================
class SyncSettingsNotifier extends StateNotifier<SyncSettings> {
  SyncSettingsNotifier(this._repository) : super(_repository.getSyncSettings());

  final RoutineRepository _repository;

  Future<void> toggleAutoPush() async {
    state = state.copyWith(autoPushRoutine: !state.autoPushRoutine);
    await _repository.updateSyncSettings(state);
  }

  Future<void> toggleAutoBlock() async {
    state = state.copyWith(autoBlockDistractions: !state.autoBlockDistractions);
    await _repository.updateSyncSettings(state);
  }

  Future<void> toggleReminders() async {
    state = state.copyWith(classReminderAlerts: !state.classReminderAlerts);
    await _repository.updateSyncSettings(state);
  }

  Future<void> refreshSync() async {
    state = state.copyWith(lastSyncTime: 'Just now');
    await _repository.updateSyncSettings(state);
  }

  Future<TwoWaySyncResult> performTwoWaySync({
    required CalendarSyncService calService,
    required NotificationService notifService,
    required TimelineNotifier timelineNotifier,
    required AcademicEventsNotifier academicNotifier,
  }) async {
    final allEvents = _repository.getAllEvents();
    final result = await calService.performTwoWaySync(
      eventsToExport: allEvents,
      onEventSynced: (eventId, calendarEventId) async {
        final ev = allEvents.firstWhere((e) => e.id == eventId);
        final updated = ev.copyWith(calendarEventId: calendarEventId);
        await _repository.updateEvent(updated);
        await notifService.scheduleEventAlerts(updated);
      },
    );

    if (result.importedBlocks.isNotEmpty) {
      await timelineNotifier.batchAddBlocks(result.importedBlocks);
    }

    await academicNotifier.reload();

    state = state.copyWith(
      lastSyncTime: 'Just now',
      accountEmail: result.calendarName ?? state.accountEmail,
    );
    await _repository.updateSyncSettings(state);

    return result;
  }
}

final syncSettingsProvider =
    StateNotifierProvider<SyncSettingsNotifier, SyncSettings>((ref) {
  final repo = ref.watch(routineRepositoryProvider);
  return SyncSettingsNotifier(repo);
});

final aiGapSlotsProvider = Provider<List<AiGapSlot>>((ref) {
  return ref.watch(routineRepositoryProvider).getAiGapSlots();
});

/// Dynamically calculates today's unallocated schedule gaps using ScheduleGapService
/// merging locked academic classes and imported Google Calendar events.
final todayFreeGapsProvider = Provider<List<TimeGap>>((ref) {
  final gapService = ref.watch(scheduleGapServiceProvider);
  final todayEvents = ref.watch(currentDayEventsProvider);
  final timelineBlocks = ref.watch(timelineBlocksProvider);

  // Extract external appointments imported from Google Calendar
  final externalBusy = timelineBlocks
      .where((b) => b.type == TimelineBlockType.calendarSync)
      .toList();

  return gapService.findFreeGaps(
    todayEvents,
    busyBlocks: externalBusy,
  );
});

