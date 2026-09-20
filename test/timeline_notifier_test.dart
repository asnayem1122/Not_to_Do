import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do/core/models/routine_models.dart';
import 'package:not_to_do/core/providers/routine_providers.dart';
import 'package:not_to_do/core/repositories/routine_repository.dart';

class FakeRoutineRepository implements RoutineRepository {
  List<TimelineBlock> blocks = [];

  @override
  Future<void> init() async {}

  @override
  List<TimelineBlock> getTodayTimeline() => List.unmodifiable(blocks);

  @override
  Future<void> replaceAllTimelineBlocks(List<TimelineBlock> newBlocks) async {
    blocks = List.from(newBlocks);
  }

  @override
  Future<void> createTimelineBlock(TimelineBlock block) async {
    blocks.add(block);
  }

  @override
  Future<void> batchCreateTimelineBlocks(List<TimelineBlock> newBlocks) async {
    blocks.addAll(newBlocks);
  }

  @override
  Future<void> toggleTimelineBlockCompletion(String id) async {
    final idx = blocks.indexWhere((b) => b.id == id);
    if (idx != -1) {
      blocks[idx] = blocks[idx].copyWith(isCompleted: !blocks[idx].isCompleted);
    }
  }

  @override
  Future<void> updateTimelineBlock(TimelineBlock block) async {
    final idx = blocks.indexWhere((b) => b.id == block.id);
    if (idx != -1) blocks[idx] = block;
  }

  @override
  Future<void> deleteTimelineBlock(String id) async {
    blocks.removeWhere((b) => b.id == id);
  }

  // Stubs for remaining interface methods
  @override
  List<AcademicEvent> getAllEvents() => [];
  @override
  List<AcademicEvent> getEventsForDay(int dayOfWeek) => [];
  @override
  HeroClass getHeroUpcomingClass() => const HeroClass(
        startsIn: '20 min',
        courseCode: 'CSE 101',
        sessionType: 'Lecture',
        title: 'Intro',
        location: '101',
        instructor: 'Prof',
        slidesDownloaded: true,
        assignmentDueText: '',
      );
  @override
  List<DayCycle> getWeeklyCycle() => [];
  @override
  List<HabitItem> getAllHabits() => [];
  @override
  List<HabitItem> getAntiHabits() => [];
  @override
  List<HabitItem> getPositiveHabits() => [];
  @override
  List<AiGapSlot> getAiGapSlots() => [];
  @override
  SyncSettings getSyncSettings() => const SyncSettings(
        accountEmail: 'test@uni.edu',
        lastSyncTime: 'Now',
        is2WayLiveSyncActive: true,
        autoPushRoutine: true,
        autoBlockDistractions: true,
        classReminderAlerts: true,
      );

  @override
  Future<void> createEvent(AcademicEvent event) async {}
  @override
  Future<void> batchCreateEvents(List<AcademicEvent> events) async {}
  @override
  Future<void> updateEvent(AcademicEvent event) async {}
  @override
  Future<void> deleteEvent(String id) async {}
  @override
  Future<void> toggleEventCompletion(String id) async {}
  @override
  Future<void> createHabit(HabitItem habit) async {}
  @override
  Future<void> updateHabit(HabitItem habit) async {}
  @override
  Future<void> deleteHabit(String id) async {}
  @override
  Future<void> toggleHabitDefend(String habitId, DateTime date) async {}
  @override
  Future<void> manualUpdateStreak(String habitId, int newStreak) async {}
  @override
  Future<void> updateSyncSettings(SyncSettings settings) async {}
}

void main() {
  group('TimelineNotifier Tests', () {
    late FakeRoutineRepository fakeRepo;
    late TimelineNotifier notifier;

    setUp(() {
      fakeRepo = FakeRoutineRepository();
      fakeRepo.blocks = [
        TimelineBlock(
          id: 'tb-1',
          title: 'Initial Class',
          startTime: '09:00',
          endTime: '10:30',
          type: TimelineBlockType.academicClass,
        ),
      ];
      notifier = TimelineNotifier(fakeRepo);
    });

    test('initial state contains repository blocks', () {
      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, 'tb-1');
    });

    test('replaceAllBlocks atomically replaces all timeline blocks', () async {
      final List<TimelineBlock> newBlocks = [
        TimelineBlock(
          id: 'tb-fix-1',
          title: 'Repaired Focus Session',
          startTime: '11:00',
          endTime: '12:00',
          type: TimelineBlockType.routineFocus,
        ),
        TimelineBlock(
          id: 'tb-fix-2',
          title: 'Anti-Habit Shield',
          startTime: '12:00',
          endTime: '13:00',
          type: TimelineBlockType.antiHabitShield,
        ),
      ];

      await notifier.replaceAllBlocks(newBlocks);

      expect(notifier.state.length, 2);
      expect(notifier.state[0].id, 'tb-fix-1');
      expect(notifier.state[1].id, 'tb-fix-2');
      expect(fakeRepo.blocks.length, 2);
    });

    test('toggleCompletion flips block completion status', () async {
      expect(notifier.state.first.isCompleted, isFalse);

      await notifier.toggleBlockCompletion('tb-1');
      expect(notifier.state.first.isCompleted, isTrue);

      await notifier.toggleBlockCompletion('tb-1');
      expect(notifier.state.first.isCompleted, isFalse);
    });

    test('batchAddBlocks appends new blocks to existing timeline', () async {
      final List<TimelineBlock> added = [
        TimelineBlock(
          id: 'tb-add-1',
          title: 'Evening Study',
          startTime: '18:00',
          endTime: '19:30',
          type: TimelineBlockType.routineFocus,
        ),
      ];

      await notifier.batchAddBlocks(added);
      expect(notifier.state.length, 2);
      expect(notifier.state.any((b) => b.id == 'tb-add-1'), isTrue);
    });
  });
}
