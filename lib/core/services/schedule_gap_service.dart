import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/routine_models.dart';

/// Represents an unallocated, idle time gap between scheduled classes/events.
class TimeGap {
  final String startTime; // "HH:mm" in 24h format
  final String endTime;   // "HH:mm" in 24h format
  final int durationMinutes;
  final String label;

  const TimeGap({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.label,
  });

  String get displayRange => '$startTime – $endTime ($durationMinutes mins)';

  @override
  String toString() => displayRange;
}

/// Internal helper interval for merging busy slots
class _Interval {
  final int start;
  final int end;

  const _Interval(this.start, this.end);
}

/// Service to detect idle schedule gaps during waking hours.
class ScheduleGapService {
  final String wakingStartTime; // default "07:30"
  final String wakingEndTime;   // default "22:30"
  final int minGapMinutes;      // default 20 minutes

  const ScheduleGapService({
    this.wakingStartTime = '07:30',
    this.wakingEndTime = '22:30',
    this.minGapMinutes = 20,
  });

  /// Converts "HH:mm" to minutes from midnight.
  static int timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return (h * 60) + m;
    }
    return 0;
  }

  /// Converts minutes from midnight back to "HH:mm" 24h format.
  static String minutesToTime(int minutes) {
    final h = (minutes ~/ 60).clamp(0, 23);
    final m = (minutes % 60).clamp(0, 59);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Analyzes a list of AcademicEvents and optional busy TimelineBlocks (e.g. Google Calendar sync items)
  /// and extracts all non-overlapping idle intervals longer than [minGapMinutes].
  List<TimeGap> findFreeGaps(
    List<AcademicEvent> events, {
    List<TimelineBlock> busyBlocks = const [],
  }) {
    final wakingStartMin = timeToMinutes(wakingStartTime);
    final wakingEndMin = timeToMinutes(wakingEndTime);

    if (wakingEndMin <= wakingStartMin) {
      return [];
    }

    // 1. Convert events and busy blocks into intervals clamped within waking hours
    final rawIntervals = <_Interval>[];

    // Academic events
    for (final event in events) {
      final startMin = timeToMinutes(event.startTime);
      final endMin = timeToMinutes(event.endTime);

      if (endMin <= startMin) continue; // Malformed event time
      if (endMin <= wakingStartMin || startMin >= wakingEndMin) continue; // Outside waking hours

      final clampedStart = startMin < wakingStartMin ? wakingStartMin : startMin;
      final clampedEnd = endMin > wakingEndMin ? wakingEndMin : endMin;

      rawIntervals.add(_Interval(clampedStart, clampedEnd));
    }

    // External calendar appointments / busy blocks
    for (final block in busyBlocks) {
      final startMin = timeToMinutes(block.startTime);
      final endMin = timeToMinutes(block.endTime);

      if (endMin <= startMin) continue;
      if (endMin <= wakingStartMin || startMin >= wakingEndMin) continue;

      final clampedStart = startMin < wakingStartMin ? wakingStartMin : startMin;
      final clampedEnd = endMin > wakingEndMin ? wakingEndMin : endMin;

      rawIntervals.add(_Interval(clampedStart, clampedEnd));
    }

    if (rawIntervals.isEmpty) {
      final duration = wakingEndMin - wakingStartMin;
      if (duration >= minGapMinutes) {
        return [
          TimeGap(
            startTime: wakingStartTime,
            endTime: wakingEndTime,
            durationMinutes: duration,
            label: 'Full Day Open Focus Window',
          ),
        ];
      }
      return [];
    }

    // 2. Sort intervals chronologically by start
    rawIntervals.sort((a, b) => a.start.compareTo(b.start));

    // 3. Merge overlapping or adjacent busy intervals
    final merged = <_Interval>[rawIntervals.first];
    for (int i = 1; i < rawIntervals.length; i++) {
      final current = rawIntervals[i];
      final previous = merged.last;

      if (current.start <= previous.end) {
        // Overlapping or touching: extend the previous interval
        final newEnd = current.end > previous.end ? current.end : previous.end;
        merged[merged.length - 1] = _Interval(previous.start, newEnd);
      } else {
        merged.add(current);
      }
    }

    // 4. Calculate idle gaps between merged busy blocks
    final gaps = <TimeGap>[];

    // Gap 1: from waking start to first busy block
    final firstBusy = merged.first;
    if (firstBusy.start - wakingStartMin >= minGapMinutes) {
      gaps.add(TimeGap(
        startTime: wakingStartTime,
        endTime: minutesToTime(firstBusy.start),
        durationMinutes: firstBusy.start - wakingStartMin,
        label: _generateLabel(wakingStartMin, firstBusy.start),
      ));
    }

    // Intermediate gaps between classes/appointments
    for (int i = 0; i < merged.length - 1; i++) {
      final currentEnd = merged[i].end;
      final nextStart = merged[i + 1].start;
      final gapDuration = nextStart - currentEnd;

      if (gapDuration >= minGapMinutes) {
        gaps.add(TimeGap(
          startTime: minutesToTime(currentEnd),
          endTime: minutesToTime(nextStart),
          durationMinutes: gapDuration,
          label: _generateLabel(currentEnd, nextStart),
        ));
      }
    }

    // Final gap: from last busy block to waking end
    final lastBusy = merged.last;
    if (wakingEndMin - lastBusy.end >= minGapMinutes) {
      gaps.add(TimeGap(
        startTime: minutesToTime(lastBusy.end),
        endTime: wakingEndTime,
        durationMinutes: wakingEndMin - lastBusy.end,
        label: _generateLabel(lastBusy.end, wakingEndMin),
      ));
    }

    return gaps;
  }

  String _generateLabel(int startMin, int endMin) {
    final startHour = startMin / 60.0;
    if (startHour < 11.5) {
      return 'Morning Open Focus Window';
    } else if (startHour < 14.5) {
      return 'Mid-day Intermission Gap';
    } else if (startHour < 17.5) {
      return 'Afternoon Study & Lab Prep';
    } else {
      return 'Evening Deep Work & Shield Window';
    }
  }
}

/// Riverpod provider for ScheduleGapService
final scheduleGapServiceProvider = Provider<ScheduleGapService>((ref) {
  return const ScheduleGapService();
});
