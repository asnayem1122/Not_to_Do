import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/gemini_constants.dart';
import '../models/routine_models.dart';
import 'api_key_service.dart';
import 'routine_parser_service.dart';
import 'schedule_gap_service.dart';

/// Model representing a Gemini AI generated schedule block recommendation.
class SuggestedRoutineBlock {
  final String id;
  final String title;
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  final String category;  // "positiveHabit" | "antiHabit" | "academicPrep" | "rest"
  final TimelineBlockType blockType;
  final String priority;  // "Critical" | "High" | "Medium" | "Normal"
  final String rationale;
  final String? shieldedDistraction; // e.g. "Instagram, TikTok, Steam"
  final String? referenceHabitId;

  const SuggestedRoutineBlock({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.blockType,
    required this.priority,
    required this.rationale,
    this.shieldedDistraction,
    this.referenceHabitId,
  });

  String get timeRange => '$startTime – $endTime';

  SuggestedRoutineBlock copyWith({
    String? id,
    String? title,
    String? startTime,
    String? endTime,
    String? category,
    TimelineBlockType? blockType,
    String? priority,
    String? rationale,
    String? shieldedDistraction,
    String? referenceHabitId,
  }) {
    return SuggestedRoutineBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      blockType: blockType ?? this.blockType,
      priority: priority ?? this.priority,
      rationale: rationale ?? this.rationale,
      shieldedDistraction: shieldedDistraction ?? this.shieldedDistraction,
      referenceHabitId: referenceHabitId ?? this.referenceHabitId,
    );
  }

  /// Converts this suggested block directly into a persistent TimelineBlock for Hive.
  TimelineBlock toTimelineBlock() {
    return TimelineBlock(
      id: id,
      title: title,
      startTime: startTime,
      endTime: endTime,
      type: blockType,
      referenceId: referenceHabitId,
      subtitle: category == 'antiHabit' && shieldedDistraction != null
          ? 'Blacklisted: $shieldedDistraction'
          : rationale,
      location: category == 'antiHabit'
          ? 'Shield Armed'
          : (category == 'academicPrep' ? 'Library / Study' : 'Workspace'),
      isCompleted: false,
      badgeText: category == 'antiHabit' ? 'SHIELD' : priority.toUpperCase(),
      replacementTrigger: category == 'antiHabit' ? rationale : null,
    );
  }
}

/// Service to generate schedule recommendations and distraction barriers using Gemini AI.
class AiPlannerService {
  final ApiKeyService _apiKeyService;

  AiPlannerService(this._apiKeyService);

  Future<GenerativeModel> _getModel() async {
    final apiKey = await _apiKeyService.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const GeminiApiKeyMissingException();
    }

    return GenerativeModel(
      model: GeminiConstants.primaryModel,
      apiKey: apiKey.trim(),
      generationConfig: GenerationConfig(
        temperature: 0.2,
        responseMimeType: 'application/json',
      ),
    );
  }

  /// Generates a structured routine plan for today based on free gaps, active classes, and habits.
  Future<List<SuggestedRoutineBlock>> generateRoutinePlan({
    required List<TimeGap> freeGaps,
    required List<AcademicEvent> todayEvents,
    required List<HabitItem> activeHabits,
    required String userPrompt,
  }) async {
    if (freeGaps.isEmpty) {
      return [];
    }

    final model = await _getModel();

    final eventsDescription = todayEvents.isEmpty
        ? 'No scheduled classes today (Free day).'
        : todayEvents
            .map((e) =>
                '- ${e.courseCode} ${e.title} (${e.type.displayName}): ${e.startTime} - ${e.endTime} @ ${e.room}')
            .join('\n');

    final gapsDescription = freeGaps
        .map((g) => '- ${g.startTime} - ${g.endTime} (${g.durationMinutes} mins) [${g.label}]')
        .join('\n');

    final positiveHabits = activeHabits.where((h) => !h.isAntiHabit).toList();
    final antiHabits = activeHabits.where((h) => h.isAntiHabit).toList();

    final habitsDescription = '''
POSITIVE HABITS:
${positiveHabits.map((h) => "- [id: ${h.id}] ${h.title} (Category: ${h.category}, Current Streak: ${h.streakCount}d)").join('\n')}

ANTI-HABITS TO SHIELD & LOCK OUT:
${antiHabits.map((h) => "- [id: ${h.id}] ${h.title} (Category: ${h.category}, Current Streak: ${h.streakCount}d, Rule: ${h.shieldRuleDescription})").join('\n')}
''';

    final systemPrompt = '''
You are an expert academic discipline strategist and cognitive workload optimizer for university students.
Your goal is to organize today's idle schedule gaps into productive study blocks, lab preparation windows, and proactive "Not To Do" crimson distraction shields.

SCHEDULE CONSTRAINTS:
1. ALL recommended blocks MUST fall strictly within the provided FREE GAPS.
2. NEVER schedule over or overlap with the SCHEDULED ACADEMIC EVENTS.
3. Keep individual focus blocks between 30 and 90 minutes.
4. Categorize each suggested block into one of:
   - "positiveHabit": Study, coding, problem solving, fitness, or syllabus revision matching the user's positive habits.
   - "antiHabit": A defensive distraction lockout barrier placed during vulnerable idle windows (e.g. after lunch, between classes, or late evening). Specify "shieldedDistraction" (e.g. "Instagram, TikTok, YouTube Shorts, Gaming").
   - "academicPrep": 20-30 min pre-class or lab review before a lecture.
5. Factor in the student's CUSTOM INSTRUCTIONS carefully.

TODAY'S SCHEDULED ACADEMIC EVENTS (DO NOT OVERLAP):
$eventsDescription

TODAY'S AVAILABLE FREE GAPS:
$gapsDescription

USER'S HABIT & SHIELD PROFILE:
$habitsDescription

STUDENT'S CUSTOM INSTRUCTIONS:
${userPrompt.trim().isEmpty ? "Optimize for a balanced study routine, protect vulnerable idle gaps from social media/gaming, and prepare for upcoming classes." : userPrompt}

OUTPUT JSON SPECIFICATION:
Return ONLY a valid JSON array of block objects. Do not include markdown code ticks, preambles, or explanations.
Schema:
[
  {
    "title": "String (e.g., 'Deep Work: Database Systems Query Optimization')",
    "startTime": "HH:mm (within a free gap)",
    "endTime": "HH:mm (within a free gap)",
    "category": "positiveHabit" | "antiHabit" | "academicPrep",
    "priority": "Critical" | "High" | "Medium" | "Normal",
    "rationale": "String explaining why this block is strategically placed",
    "shieldedDistraction": "String or null (comma separated list of blacklisted apps if category is antiHabit)",
    "referenceHabitId": "String or null (matching id from habit profile if applicable)"
  }
]
''';

    final response = await model.generateContent([
      Content.text(systemPrompt),
    ]);

    final rawText = response.text;
    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception('Gemini returned an empty response for routine optimization.');
    }

    return _parsePlannerResponse(rawText);
  }

  List<SuggestedRoutineBlock> _parsePlannerResponse(String rawJson) {
    String cleaned = rawJson.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final dynamic decoded = jsonDecode(cleaned);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON array of suggested routine blocks.');
    }

    final List<SuggestedRoutineBlock> blocks = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is Map<String, dynamic>) {
        final title = (item['title'] ?? 'Strategic Focus Block').toString().trim();
        final startTime = (item['startTime'] ?? '09:00').toString().trim();
        final endTime = (item['endTime'] ?? '10:00').toString().trim();
        final categoryStr = (item['category'] ?? 'positiveHabit').toString().toLowerCase().trim();
        final priority = (item['priority'] ?? 'High').toString().trim();
        final rationale = (item['rationale'] ?? '').toString().trim();
        final shieldedDistraction = item['shieldedDistraction']?.toString().trim();
        final referenceHabitId = item['referenceHabitId']?.toString().trim();

        TimelineBlockType blockType;
        String category;

        if (categoryStr.contains('anti') || categoryStr.contains('shield')) {
          category = 'antiHabit';
          blockType = TimelineBlockType.antiHabitShield;
        } else if (categoryStr.contains('prep') || categoryStr.contains('acad')) {
          category = 'academicPrep';
          blockType = TimelineBlockType.academicClass;
        } else {
          category = 'positiveHabit';
          blockType = TimelineBlockType.routineFocus;
        }

        blocks.add(SuggestedRoutineBlock(
          id: 'tb-ai-$timestamp-$i',
          title: title,
          startTime: startTime,
          endTime: endTime,
          category: category,
          blockType: blockType,
          priority: priority,
          rationale: rationale.isEmpty
              ? (category == 'antiHabit'
                  ? 'Active defense barrier against distraction breaches'
                  : 'Targeted focus interval aligned with academic goals')
              : rationale,
          shieldedDistraction:
              shieldedDistraction != null && shieldedDistraction.isNotEmpty
                  ? shieldedDistraction
                  : (category == 'antiHabit' ? 'Social Media & Games' : null),
          referenceHabitId: referenceHabitId,
        ));
      }
    }

    return blocks;
  }
}

/// Riverpod provider for AiPlannerService
final aiPlannerServiceProvider = Provider<AiPlannerService>((ref) {
  final apiKeyService = ref.watch(apiKeyServiceProvider);
  return AiPlannerService(apiKeyService);
});
