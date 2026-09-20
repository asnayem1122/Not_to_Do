import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do/core/models/routine_models.dart';
import 'package:not_to_do/core/services/schedule_gap_service.dart';

void main() {
  group('ScheduleGapService Tests', () {
    const service = ScheduleGapService(
      wakingStartTime: '07:30',
      wakingEndTime: '22:30',
      minGapMinutes: 20,
    );

    test('timeToMinutes and minutesToTime conversions are reciprocal', () {
      expect(ScheduleGapService.timeToMinutes('00:00'), 0);
      expect(ScheduleGapService.timeToMinutes('07:30'), 450);
      expect(ScheduleGapService.timeToMinutes('22:30'), 1350);

      expect(ScheduleGapService.minutesToTime(0), '00:00');
      expect(ScheduleGapService.minutesToTime(450), '07:30');
      expect(ScheduleGapService.minutesToTime(1350), '22:30');
    });

    test('detects idle free gap between scheduled classes', () {
      final classes = [
        AcademicEvent(
          id: '1',
          title: 'Database Systems',
          courseCode: 'CSE 3101',
          type: AcademicEventType.lecture,
          startTime: '09:00',
          endTime: '10:30',
          room: '301',
          instructor: 'Dr. Khan',
          dayOfWeek: 1,
        ),
        AcademicEvent(
          id: '2',
          title: 'Software Engineering',
          courseCode: 'CSE 3102',
          type: AcademicEventType.lecture,
          startTime: '12:00',
          endTime: '13:30',
          room: '302',
          instructor: 'Dr. Alex',
          dayOfWeek: 1,
        ),
      ];

      final gaps = service.findFreeGaps(classes);

      // Expect gap before first class: 07:30 - 09:00 (90 min)
      // Gap between classes: 10:30 - 12:00 (90 min)
      // Gap after last class: 13:30 - 22:30 (540 min)
      expect(gaps.length, 3);
      expect(gaps[0].startTime, '07:30');
      expect(gaps[0].endTime, '09:00');
      expect(gaps[0].durationMinutes, 90);

      expect(gaps[1].startTime, '10:30');
      expect(gaps[1].endTime, '12:00');
      expect(gaps[1].durationMinutes, 90);

      expect(gaps[2].startTime, '13:30');
      expect(gaps[2].endTime, '22:30');
      expect(gaps[2].durationMinutes, 540);
    });

    test('merges overlapping and adjacent busy events correctly', () {
      final classes = [
        AcademicEvent(
          id: '1',
          title: 'Class A',
          courseCode: 'CSE 1',
          type: AcademicEventType.lecture,
          startTime: '10:00',
          endTime: '11:30',
          room: '101',
          instructor: 'Inst A',
          dayOfWeek: 1,
        ),
        AcademicEvent(
          id: '2',
          title: 'Class B (Overlapping)',
          courseCode: 'CSE 2',
          type: AcademicEventType.sessionalLab,
          startTime: '11:00',
          endTime: '12:30',
          room: '102',
          instructor: 'Inst B',
          dayOfWeek: 1,
        ),
      ];

      final gaps = service.findFreeGaps(classes);

      // Overlapping busy: 10:00 - 12:30 merged
      expect(gaps.any((g) => g.startTime == '07:30' && g.endTime == '10:00'), isTrue);
      expect(gaps.any((g) => g.startTime == '12:30' && g.endTime == '22:30'), isTrue);
    });

    test('ignores gaps shorter than minGapMinutes', () {
      final classes = [
        AcademicEvent(
          id: '1',
          title: 'Class A',
          courseCode: 'CSE 1',
          type: AcademicEventType.lecture,
          startTime: '07:30',
          endTime: '10:00',
          room: '101',
          instructor: 'Inst A',
          dayOfWeek: 1,
        ),
        AcademicEvent(
          id: '2',
          title: 'Class B (15m gap)',
          courseCode: 'CSE 2',
          type: AcademicEventType.lecture,
          startTime: '10:15',
          endTime: '22:30',
          room: '102',
          instructor: 'Inst B',
          dayOfWeek: 1,
        ),
      ];

      final gaps = service.findFreeGaps(classes);
      // 10:00 to 10:15 is 15 minutes, which is < minGapMinutes (20)
      expect(gaps.isEmpty, isTrue);
    });
  });
}
