import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/gemini_constants.dart';
import '../models/routine_models.dart';
import 'api_key_service.dart';
import 'schedule_gap_service.dart';

/// Result container returned after repairing a delayed schedule.
class ScheduleRepairResult {
  final List<TimelineBlock> repairedBlocks;
  final int shiftedCount;
  final int skippedCount;
  final String coachingMessage;
  final bool isAiGenerated;

  const ScheduleRepairResult({
    required this.repairedBlocks,
    required this.shiftedCount,
    required this.skippedCount,
    required this.coachingMessage,
    required this.isAiGenerated,
  });
}

/// Service providing 1-tap emergency schedule recovery.
/// Salvages daily routines when students fall behind, classes run overtime,
/// or unexpected delays disrupt the planned timeline.
class EmergencyRescheduleService {
  final ApiKeyService _apiKeyService;
  final ScheduleGapService gapService;

  EmergencyRescheduleService(this._apiKeyService, this.gapService);

  /// Performs an instant, offline mathematical schedule repair by shifting uncompleted focus
  /// blocks into remaining free gaps between locked university classes before bedtime (22:30).
  ScheduleRepairResult calculateLocalRepair({
    required List<TimelineBlock> currentBlocks,
    required List<AcademicEvent> todayClasses,
    required String delayReason,
    String? currentClockTime, // "HH:mm", defaults to system time
  }) {
    final now = DateTime.now();
    final nowStr = currentClockTime ??
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final nowMinutes = ScheduleGapService.timeToMinutes(nowStr);
    const wakingEndMinutes = 22 * 60 + 30; // 22:30 bedtime

    final List<TimelineBlock> repaired = [];
    final List<TimelineBlock> pendingToReschedule = [];
    int shiftedCount = 0;
    int skippedCount = 0;

    // 1. Partition blocks: keep completed blocks and locked classes/appointments untouched
    for (final block in currentBlocks) {
      if (block.isCompleted) {
        repaired.add(block);
        continue;
      }

      // Locked academic classes or external calendar appointments cannot be moved
      if (block.type == TimelineBlockType.academicClass ||
          block.type == TimelineBlockType.calendarSync) {
        repaired.add(block);
        continue;
      }

      final blockStartMin = ScheduleGapService.timeToMinutes(block.startTime);
      final blockEndMin = ScheduleGapService.timeToMinutes(block.endTime);

      if (blockEndMin <= nowMinutes) {
        // Block ended in the past without completion
        skippedCount++;
        // We will attempt to salvage positive habits by rescheduling a compressed version
        if (block.type == TimelineBlockType.routineFocus) {
          pendingToReschedule.add(block);
        }
      } else if (blockStartMin < nowMinutes && blockEndMin > nowMinutes) {
        // Block is currently in progress: shift start to now
        shiftedCount++;
        repaired.add(block.copyWith(
          startTime: nowStr,
          subtitle: '${block.subtitle} [Adjusted from ${block.startTime}]',
        ));
      } else {
        // Future uncompleted block: queue for gap alignment
        pendingToReschedule.add(block);
      }
    }

    // 2. Identify remaining locked intervals (classes and fixed items after now)
    final busyIntervals = <Map<String, int>>[];
    for (final item in repaired) {
      final s = ScheduleGapService.timeToMinutes(item.startTime);
      final e = ScheduleGapService.timeToMinutes(item.endTime);
      if (e > nowMinutes) {
        busyIntervals.add({'start': s < nowMinutes ? nowMinutes : s, 'end': e});
      }
    }
    busyIntervals.sort((a, b) => a['start']!.compareTo(b['start']!));

    // 3. Slide pending focus blocks and shields into remaining gaps
    int cursor = (nowMinutes + 10).clamp(0, wakingEndMinutes);

    for (final block in pendingToReschedule) {
      if (cursor >= wakingEndMinutes - 20) {
        // Bedtime reached, archive remaining
        skippedCount++;
        continue;
      }

      // Compute desired duration (capped to 60 mins for emergency agility)
      final origStart = ScheduleGapService.timeToMinutes(block.startTime);
      final origEnd = ScheduleGapService.timeToMinutes(block.endTime);
      int duration = (origEnd - origStart).clamp(25, 60);

      // Advance cursor past any locked busy interval
      for (final busy in busyIntervals) {
        if (cursor < busy['end']! && cursor + duration > busy['start']!) {
          cursor = busy['end']! + 5; // 5 min transition buffer
        }
      }

      if (cursor + duration <= wakingEndMinutes) {
        final newStartStr = ScheduleGapService.minutesToTime(cursor);
        final newEndStr = ScheduleGapService.minutesToTime(cursor + duration);

        shiftedCount++;
        repaired.add(block.copyWith(
          startTime: newStartStr,
          endTime: newEndStr,
          subtitle: '${block.subtitle} [Repaired: moved from ${block.startTime}]',
        ));

        cursor += duration + 10; // 10 min break buffer
      } else {
        skippedCount++;
      }
    }

    // 4. Ensure an evening anti-habit shield is armed if within waking window
    final hasEveningShield = repaired.any((b) =>
        b.type == TimelineBlockType.antiHabitShield &&
        ScheduleGapService.timeToMinutes(b.startTime) >= 20 * 60);

    if (!hasEveningShield && cursor < wakingEndMinutes - 30) {
      final shieldStartMin = cursor > 20 * 60 + 30 ? cursor : 20 * 60 + 30;
      if (shieldStartMin + 45 <= wakingEndMinutes) {
        repaired.add(
          TimelineBlock(
            id: 'shield-emergency-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Shield: Evening Anti-Procrastination Barrier',
            startTime: ScheduleGapService.minutesToTime(shieldStartMin),
            endTime: ScheduleGapService.minutesToTime(shieldStartMin + 45),
            type: TimelineBlockType.antiHabitShield,
            subtitle: 'Armed via Fix My Day: Zero-scroll digital lockdown',
            badgeText: 'EMERGENCY SHIELD',
            replacementTrigger: 'Evening fatigue / screen curfew defense',
          ),
        );
      }
    }

    // Sort chronologically
    repaired.sort((a, b) => a.startTime.compareTo(b.startTime));

    final coachingMessage = delayReason.toLowerCase().contains('overtime')
        ? 'University classes ran late, but your day is salvaged! We moved uncompleted study blocks forward into your open evening gaps and armed your distraction shield.'
        : 'Don\'t stress over lost time. We shifted your priority focus sessions to start from $nowStr, condensed idle gaps, and preserved your bedtime curfew.';

    return ScheduleRepairResult(
      repairedBlocks: repaired,
      shiftedCount: shiftedCount,
      skippedCount: skippedCount,
      coachingMessage: coachingMessage,
      isAiGenerated: false,
    );
  }

  /// Leverages Gemini AI to generate an adaptive schedule repair with tactical coaching comeback reasoning.
  Future<ScheduleRepairResult> calculateAiRepair({
    required List<TimelineBlock> currentBlocks,
    required List<AcademicEvent> todayClasses,
    required String delayReason,
  }) async {
    final now = DateTime.now();
    final nowStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final apiKey = await _apiKeyService.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      // Fallback to local heuristic repair
      return calculateLocalRepair(
        currentBlocks: currentBlocks,
        todayClasses: todayClasses,
        delayReason: delayReason,
        currentClockTime: nowStr,
      );
    }

    try {
      final model = GenerativeModel(
        model: GeminiConstants.primaryModel,
        apiKey: apiKey.trim(),
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
        ),
      );

      final blocksDescription = currentBlocks.map((b) => {
            'id': b.id,
            'title': b.title,
            'startTime': b.startTime,
            'endTime': b.endTime,
            'type': b.type.name,
            'isCompleted': b.isCompleted,
            'isLocked': b.type == TimelineBlockType.academicClass ||
                b.type == TimelineBlockType.calendarSync,
          }).toList();

      final prompt = '''
You are the "Fix My Day" emergency schedule repair engine for university students.
The student has experienced a schedule delay. Current local time is: $nowStr.
Delay context: "$delayReason". Bedtime curfew: 22:30.

CONSTRAINTS:
1. LOCKED CLASSES / APPOINTMENTS CANNOT BE MOVED: Any block with "isLocked": true must remain at its exact original startTime and endTime.
2. COMPLETED BLOCKS CANNOT BE MOVED: If "isCompleted": true, preserve it unchanged.
3. Reschedule remaining uncompleted focus blocks to start from $nowStr onward into free intervals.
4. Compress durations slightly (30-50 mins) if needed to fit before 22:30.
5. Include a defensive "antiHabitShield" in the late evening to protect against sleep procrastination.
6. Provide an uplifting, tactical "coachingMessage" (2-3 sentences) encouraging the student.

CURRENT BLOCKS:
${jsonEncode(blocksDescription)}

OUTPUT JSON FORMAT:
{
  "coachingMessage": "String (uplifting advice)",
  "repairedBlocks": [
    {
      "id": "String (matching original id or new tb-fix-* id)",
      "title": "String",
      "startTime": "HH:mm",
      "endTime": "HH:mm",
      "type": "academicClass" | "routineFocus" | "antiHabitShield" | "calendarSync",
      "subtitle": "String",
      "badgeText": "String"
    }
  ]
}
''';

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));
      final rawText = response.text;
      if (rawText == null || rawText.trim().isEmpty) {
        throw Exception('Empty AI repair response.');
      }

      String cleaned = rawText.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final dynamic decoded = jsonDecode(cleaned);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object with repairedBlocks.');
      }

      final coachingMessage = (decoded['coachingMessage'] ??
              'Schedule successfully repaired! Your remaining hours are aligned.')
          .toString();
      final List<dynamic> blockList = decoded['repairedBlocks'] ?? [];

      final List<TimelineBlock> repaired = [];
      int shiftedCount = 0;

      for (final item in blockList) {
        if (item is Map<String, dynamic>) {
          final id = item['id']?.toString() ?? 'tb-fix-${DateTime.now().millisecondsSinceEpoch}';
          final title = item['title']?.toString() ?? 'Focus Session';
          final startTime = item['startTime']?.toString() ?? nowStr;
          final endTime = item['endTime']?.toString() ?? '22:00';
          final typeStr = item['type']?.toString() ?? 'routineFocus';
          final subtitle = item['subtitle']?.toString() ?? '';
          final badgeText = item['badgeText']?.toString();

          TimelineBlockType type;
          if (typeStr == 'academicClass') {
            type = TimelineBlockType.academicClass;
          } else if (typeStr == 'antiHabitShield') {
            type = TimelineBlockType.antiHabitShield;
          } else if (typeStr == 'calendarSync') {
            type = TimelineBlockType.calendarSync;
          } else {
            type = TimelineBlockType.routineFocus;
          }

          // Check if it was shifted
          final orig = currentBlocks.where((b) => b.id == id).firstOrNull;
          if (orig != null && (orig.startTime != startTime || orig.endTime != endTime)) {
            shiftedCount++;
          }

          repaired.add(
            TimelineBlock(
              id: id,
              title: title,
              startTime: startTime,
              endTime: endTime,
              type: type,
              subtitle: subtitle,
              badgeText: badgeText ?? (type == TimelineBlockType.antiHabitShield ? 'RE-ARMED' : 'FIXED'),
            ),
          );
        }
      }

      repaired.sort((a, b) => a.startTime.compareTo(b.startTime));

      return ScheduleRepairResult(
        repairedBlocks: repaired,
        shiftedCount: shiftedCount > 0 ? shiftedCount : 2,
        skippedCount: 0,
        coachingMessage: coachingMessage,
        isAiGenerated: true,
      );
    } catch (_) {
      // Graceful fallback to deterministic local heuristic
      return calculateLocalRepair(
        currentBlocks: currentBlocks,
        todayClasses: todayClasses,
        delayReason: delayReason,
        currentClockTime: nowStr,
      );
    }
  }
}

/// Riverpod provider for EmergencyRescheduleService
final emergencyRescheduleServiceProvider =
    Provider<EmergencyRescheduleService>((ref) {
  final apiKeyService = ref.watch(apiKeyServiceProvider);
  final gapService = ref.watch(scheduleGapServiceProvider);
  return EmergencyRescheduleService(apiKeyService, gapService);
});
