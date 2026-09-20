import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do/core/models/routine_models.dart';
import 'package:not_to_do/core/services/api_key_service.dart';
import 'package:not_to_do/core/services/emergency_reschedule_service.dart';
import 'package:not_to_do/core/services/schedule_gap_service.dart';

void main() {
  group('EmergencyRescheduleService Tests', () {
    late EmergencyRescheduleService service;

    setUp(() {
      service = EmergencyRescheduleService(
        ApiKeyService(),
        const ScheduleGapService(),
      );
    });

    test('preserves locked academic classes and completed blocks at original times', () {
      final blocks = [
        TimelineBlock(
          id: 'locked-class-1',
          title: 'Algorithms Lecture',
          startTime: '10:00',
          endTime: '11:30',
          type: TimelineBlockType.academicClass,
        ),
        TimelineBlock(
          id: 'completed-block-1',
          title: 'Morning Problem Set',
          startTime: '08:00',
          endTime: '09:00',
          type: TimelineBlockType.routineFocus,
          isCompleted: true,
        ),
        TimelineBlock(
          id: 'uncompleted-block-1',
          title: 'LeetCode Practice (Delayed)',
          startTime: '09:15',
          endTime: '10:00',
          type: TimelineBlockType.routineFocus,
          isCompleted: false,
        ),
      ];

      final result = service.calculateLocalRepair(
        currentBlocks: blocks,
        todayClasses: [],
        delayReason: 'Running 45m late',
        currentClockTime: '11:45',
      );

      // Verify locked class is preserved
      final locked = result.repairedBlocks.firstWhere((b) => b.id == 'locked-class-1');
      expect(locked.startTime, '10:00');
      expect(locked.endTime, '11:30');

      // Verify completed block is preserved
      final completed = result.repairedBlocks.firstWhere((b) => b.id == 'completed-block-1');
      expect(completed.startTime, '08:00');
      expect(completed.endTime, '09:00');
      expect(completed.isCompleted, isTrue);

      // Verify uncompleted focus block is shifted after 11:45
      final shifted = result.repairedBlocks.firstWhere((b) => b.id == 'uncompleted-block-1');
      final shiftedStartMin = ScheduleGapService.timeToMinutes(shifted.startTime);
      expect(shiftedStartMin >= ScheduleGapService.timeToMinutes('11:45'), isTrue);
    });

    test('repaired blocks never surpass bedtime curfew (22:30)', () {
      final blocks = [
        TimelineBlock(
          id: 'late-block-1',
          title: 'Night Revision 1',
          startTime: '21:00',
          endTime: '22:00',
          type: TimelineBlockType.routineFocus,
        ),
        TimelineBlock(
          id: 'late-block-2',
          title: 'Night Revision 2',
          startTime: '22:00',
          endTime: '23:00',
          type: TimelineBlockType.routineFocus,
        ),
      ];

      final result = service.calculateLocalRepair(
        currentBlocks: blocks,
        todayClasses: [],
        delayReason: 'Distraction slip late evening',
        currentClockTime: '21:45',
      );

      final bedtimeMinutes = ScheduleGapService.timeToMinutes('22:30');
      for (final block in result.repairedBlocks) {
        final endMin = ScheduleGapService.timeToMinutes(block.endTime);
        expect(endMin <= bedtimeMinutes, isTrue,
            reason: 'Block ${block.title} ends at ${block.endTime} which exceeds $bedtimeMinutes min');
      }
    });
  });
}
