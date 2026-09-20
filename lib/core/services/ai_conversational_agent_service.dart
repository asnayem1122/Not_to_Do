import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/routine_models.dart';
import 'ai_planner_service.dart';
import 'api_key_service.dart';
import 'routine_parser_service.dart';
import 'schedule_gap_service.dart';

/// Represents a single conversational turn in the AI Routine Guard dialogue.
class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<SuggestedRoutineBlock>? suggestedBlocksSnapshot;

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestedBlocksSnapshot,
  });

  AiChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    List<SuggestedRoutineBlock>? suggestedBlocksSnapshot,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      suggestedBlocksSnapshot:
          suggestedBlocksSnapshot ?? this.suggestedBlocksSnapshot,
    );
  }
}

/// The response bundle containing both natural language conversational reasoning
/// and the updated structured schedule blocks.
class ConversationalRoutineResponse {
  final String replyText;
  final List<SuggestedRoutineBlock> updatedBlocks;

  const ConversationalRoutineResponse({
    required this.replyText,
    required this.updatedBlocks,
  });
}

/// Conversational Memory Agent Service.
/// Manages multi-turn refinement sessions with Gemini AI for daily routine planning,
/// free-gap allocation, and anti-habit distraction barriers.
class AiConversationalAgentService {
  final ApiKeyService _apiKeyService;

  ChatSession? _chatSession;
  List<AiChatMessage> _messageHistory = [];
  List<SuggestedRoutineBlock> _currentBlocks = [];

  List<TimeGap> _lastGaps = [];
  List<AcademicEvent> _lastEvents = [];
  List<TimelineBlock> _lastExternalAppointments = [];
  List<HabitItem> _lastHabits = [];

  AiConversationalAgentService(this._apiKeyService);

  List<AiChatMessage> get messageHistory =>
      List.unmodifiable(_messageHistory);

  List<SuggestedRoutineBlock> get currentBlocks =>
      List.unmodifiable(_currentBlocks);

  /// Clears the current chat session and history.
  void resetSession() {
    _chatSession = null;
    _messageHistory = [];
    _currentBlocks = [];
  }

  /// Manually updates the bounds of a block in the current working list.
  void updateBlockTime(int index, String newStartTime, String newEndTime) {
    if (index >= 0 && index < _currentBlocks.length) {
      _currentBlocks[index] = _currentBlocks[index].copyWith(
        startTime: newStartTime,
        endTime: newEndTime,
      );
    }
  }

  /// Dismisses a block from the current working list.
  SuggestedRoutineBlock? dismissBlock(int index) {
    if (index >= 0 && index < _currentBlocks.length) {
      return _currentBlocks.removeAt(index);
    }
    return null;
  }

  /// Restores a dismissed block back into the working list.
  void restoreBlock(int index, SuggestedRoutineBlock block) {
    if (index >= 0 && index <= _currentBlocks.length) {
      _currentBlocks.insert(index, block);
    } else {
      _currentBlocks.add(block);
    }
  }

  /// Overwrites the current working blocks directly.
  void setBlocks(List<SuggestedRoutineBlock> blocks) {
    _currentBlocks = List.from(blocks);
  }

  /// Initializes a new multi-turn conversational routine session with full context.
  Future<ConversationalRoutineResponse> startNewSession({
    required List<TimeGap> freeGaps,
    required List<AcademicEvent> todayEvents,
    List<TimelineBlock> externalAppointments = const [],
    required List<HabitItem> activeHabits,
    String? initialPrompt,
  }) async {
    _lastGaps = freeGaps;
    _lastEvents = todayEvents;
    _lastExternalAppointments = externalAppointments;
    _lastHabits = activeHabits;
    _messageHistory = [];
    _currentBlocks = [];

    final apiKey = await _apiKeyService.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      // Return a rich offline demonstration session if API key is not yet configured
      return _buildOfflineFallbackSession(initialPrompt);
    }

    final systemInstruction = _buildSystemPrompt(
      freeGaps: freeGaps,
      todayEvents: todayEvents,
      externalAppointments: externalAppointments,
      activeHabits: activeHabits,
    );

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey.trim(),
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.3,
      ),
    );

    _chatSession = model.startChat();

    final userMessageText = (initialPrompt != null && initialPrompt.trim().isNotEmpty)
        ? initialPrompt.trim()
        : 'Analyze today\'s free gaps and generate an optimal daily routine with deep focus blocks and Not To Do distraction shields.';

    final userMsg = AiChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}-user',
      text: userMessageText,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messageHistory.add(userMsg);

    try {
      final response = await _chatSession!.sendMessage(
        Content.text(
          '''
User Request: $userMessageText

Please formulate the schedule. In your response:
1. Provide a concise, motivating explanation of the daily strategy (2-4 sentences).
2. Follow with a markdown JSON block ```json [ ... ] ``` containing the list of suggested routine blocks adhering strictly to the required schema.
''',
        ),
      ).timeout(const Duration(seconds: 15));

      final rawReply = response.text ?? '';
      final parsed = _parseResponse(rawReply);

      _currentBlocks = parsed.updatedBlocks;

      final aiMsg = AiChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}-ai',
        text: parsed.replyText,
        isUser: false,
        timestamp: DateTime.now(),
        suggestedBlocksSnapshot: List.from(_currentBlocks),
      );
      _messageHistory.add(aiMsg);

      return parsed;
    } catch (e) {
      if (e is GeminiApiKeyMissingException) rethrow;
      // If network fails or parsing issues, provide offline fallback
      return _buildOfflineFallbackSession(initialPrompt);
    }
  }

  /// Sends a conversational refinement message to fine-tune the current routine.
  Future<ConversationalRoutineResponse> sendRefinementMessage(
    String userPrompt,
  ) async {
    final userText = userPrompt.trim();
    if (userText.isEmpty) {
      return ConversationalRoutineResponse(
        replyText: 'Please enter an instruction or prompt.',
        updatedBlocks: _currentBlocks,
      );
    }

    final userMsg = AiChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}-user',
      text: userText,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messageHistory.add(userMsg);

    if (_chatSession == null) {
      // Re-initialize session if it expired or was not yet started
      return startNewSession(
        freeGaps: _lastGaps,
        todayEvents: _lastEvents,
        externalAppointments: _lastExternalAppointments,
        activeHabits: _lastHabits,
        initialPrompt: userText,
      );
    }

    try {
      final currentBlocksJson = jsonEncode(_currentBlocks.map((b) => {
            'id': b.id,
            'title': b.title,
            'startTime': b.startTime,
            'endTime': b.endTime,
            'category': b.category,
            'priority': b.priority,
            'rationale': b.rationale,
            'shieldedDistraction': b.shieldedDistraction,
            'referenceHabitId': b.referenceHabitId,
          }).toList());

      final promptPayload = '''
User Refinement: "$userText"

CURRENT SUGGESTED BLOCKS:
$currentBlocksJson

Please adjust the schedule according to the user's request while strictly respecting the free gaps and scheduled classes.
Remember to respond with:
1. A supportive, clear summary explaining the changes made.
2. The full updated JSON array in ```json [ ... ] ``` code fences.
''';

      final response = await _chatSession!
          .sendMessage(Content.text(promptPayload))
          .timeout(const Duration(seconds: 15));
      final rawReply = response.text ?? '';
      final parsed = _parseResponse(rawReply);

      if (parsed.updatedBlocks.isNotEmpty) {
        _currentBlocks = parsed.updatedBlocks;
      }

      final aiMsg = AiChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}-ai',
        text: parsed.replyText,
        isUser: false,
        timestamp: DateTime.now(),
        suggestedBlocksSnapshot: List.from(_currentBlocks),
      );
      _messageHistory.add(aiMsg);

      return ConversationalRoutineResponse(
        replyText: parsed.replyText,
        updatedBlocks: _currentBlocks,
      );
    } catch (e) {
      // Fallback response on error
      final errorReply = 'I encountered an issue connecting to Gemini ($e). Your current schedule remains preserved.';
      final aiMsg = AiChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}-ai',
        text: errorReply,
        isUser: false,
        timestamp: DateTime.now(),
        suggestedBlocksSnapshot: List.from(_currentBlocks),
      );
      _messageHistory.add(aiMsg);

      return ConversationalRoutineResponse(
        replyText: errorReply,
        updatedBlocks: _currentBlocks,
      );
    }
  }

  /// Constructs the comprehensive prompt with academic commitments, external appointments, and habits.
  String _buildSystemPrompt({
    required List<TimeGap> freeGaps,
    required List<AcademicEvent> todayEvents,
    required List<TimelineBlock> externalAppointments,
    required List<HabitItem> activeHabits,
  }) {
    final eventsStr = todayEvents.isEmpty
        ? 'None (Open academic day).'
        : todayEvents
            .map((e) => '- ${e.courseCode} ${e.title} (${e.type.displayName}): ${e.startTime} - ${e.endTime} @ ${e.room}')
            .join('\n');

    final externalStr = externalAppointments.isEmpty
        ? 'None.'
        : externalAppointments
            .map((b) => '- ${b.title}: ${b.startTime} - ${b.endTime} (${b.subtitle})')
            .join('\n');

    final gapsStr = freeGaps.isEmpty
        ? 'None detected.'
        : freeGaps
            .map((g) => '- ${g.startTime} - ${g.endTime} (${g.durationMinutes} mins) [${g.label}]')
            .join('\n');

    final positiveHabits = activeHabits.where((h) => !h.isAntiHabit).toList();
    final antiHabits = activeHabits.where((h) => h.isAntiHabit).toList();

    return '''
You are the "Not To Do" AI Routine Guard & Academic Discipline Strategist for university students.
Your mission is to defensively protect student focus, shield against procrastination and high-dopamine digital distractions, and allocate free schedule gaps into high-impact study sessions.

OPERATING PRINCIPLES:
1. STRICT GAP ADHERENCE: All suggested blocks MUST fall strictly within the provided FREE GAPS.
2. ZERO OVERLAP: NEVER schedule over or overlap with University Classes or External Calendar appointments.
3. ANTI-HABIT SHIELDS: Place defensive "Not To Do" distraction barriers during vulnerable fatigue windows (e.g. post-lunch, late evening, or between consecutive lectures). Identify specific blacklisted apps/triggers (e.g. "Instagram, TikTok, YouTube Shorts, Steam, Discord").
4. CONVERSATIONAL MEMORY: Maintain context across turns. When the student asks to adjust, move, lengthen, or delete blocks, adapt gracefully and provide constructive academic advice.

TODAY'S LOCKED ACADEMIC EVENTS (DO NOT OVERLAP):
$eventsStr

TODAY'S EXTERNAL CALENDAR APPOINTMENTS (DO NOT OVERLAP):
$externalStr

TODAY'S DETECTED FREE GAPS (ALLOCATE ONLY WITHIN THESE):
$gapsStr

POSITIVE HABITS TO FOSTER:
${positiveHabits.map((h) => "- [id: ${h.id}] ${h.title} (Category: ${h.category}, Streak: ${h.streakCount}d)").join('\n')}

ANTI-HABITS TO DEFEND AGAINST:
${antiHabits.map((h) => "- [id: ${h.id}] ${h.title} (Rule: ${h.shieldRuleDescription}, Streak: ${h.streakCount}d)").join('\n')}

REQUIRED RESPONSE FORMAT:
Always respond with friendly, direct conversational commentary first, followed by a valid JSON block enclosed in ```json and ``` code fences.

JSON Schema:
[
  {
    "title": "String (e.g., 'Deep Work: Operating Systems Process Scheduling')",
    "startTime": "HH:mm",
    "endTime": "HH:mm",
    "category": "positiveHabit" | "antiHabit" | "academicPrep",
    "priority": "Critical" | "High" | "Medium" | "Normal",
    "rationale": "String explaining the strategic reason",
    "shieldedDistraction": "String or null (comma separated list of blocked apps)",
    "referenceHabitId": "String or null"
  }
]
''';
  }

  /// Parses Gemini's raw multi-turn response into conversational text and routine blocks.
  ConversationalRoutineResponse _parseResponse(String raw) {
    String replyText = raw.trim();
    List<SuggestedRoutineBlock> blocks = [];

    final jsonBlockRegExp = RegExp(r'```(?:json)?\s*(\[\s*[\s\S]*?\s*\])\s*```');
    final match = jsonBlockRegExp.firstMatch(raw);

    if (match != null) {
      final jsonString = match.group(1);
      replyText = raw.replaceRange(match.start, match.end, '').trim();

      if (jsonString != null) {
        try {
          final dynamic decoded = jsonDecode(jsonString);
          if (decoded is List) {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            for (var i = 0; i < decoded.length; i++) {
              final item = decoded[i];
              if (item is Map<String, dynamic>) {
                final title = (item['title'] ?? 'Strategic Focus Block').toString().trim();
                final startTime = (item['startTime'] ?? '10:00').toString().trim();
                final endTime = (item['endTime'] ?? '11:00').toString().trim();
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

                blocks.add(
                  SuggestedRoutineBlock(
                    id: 'ai-block-$timestamp-$i',
                    title: title,
                    startTime: startTime,
                    endTime: endTime,
                    category: category,
                    blockType: blockType,
                    priority: priority,
                    rationale: rationale.isEmpty
                        ? (category == 'antiHabit'
                            ? 'Defensive distraction barrier armed'
                            : 'Dedicated deep work session')
                        : rationale,
                    shieldedDistraction:
                        shieldedDistraction != null && shieldedDistraction.isNotEmpty
                            ? shieldedDistraction
                            : (category == 'antiHabit' ? 'Instagram, TikTok, Gaming' : null),
                    referenceHabitId: referenceHabitId,
                  ),
                );
              }
            }
          }
        } catch (_) {
          // Keep existing blocks if JSON decoding had partial truncation
        }
      }
    }

    if (replyText.isEmpty) {
      replyText = 'I have adjusted today\'s routine to protect your focus and optimize your study blocks.';
    }

    return ConversationalRoutineResponse(
      replyText: replyText,
      updatedBlocks: blocks.isNotEmpty ? blocks : _currentBlocks,
    );
  }

  /// Builds a deterministic, rich offline session when API key is unconfigured or in demo mode.
  ConversationalRoutineResponse _buildOfflineFallbackSession(String? prompt) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final isExam = prompt?.toLowerCase().contains('exam') ?? false;
    final isLab = prompt?.toLowerCase().contains('lab') ?? false;

    final List<SuggestedRoutineBlock> defaultBlocks = isExam
        ? [
            SuggestedRoutineBlock(
              id: 'demo-$timestamp-1',
              title: 'Midterm Prep: Algorithms Proof Review',
              startTime: '10:30',
              endTime: '12:00',
              category: 'academicPrep',
              blockType: TimelineBlockType.academicClass,
              priority: 'Critical',
              rationale: 'Deep dive into divide-and-conquer recurrence relations.',
            ),
            SuggestedRoutineBlock(
              id: 'demo-$timestamp-2',
              title: 'Shield: High-Dopamine App Lockout',
              startTime: '14:00',
              endTime: '15:30',
              category: 'antiHabit',
              blockType: TimelineBlockType.antiHabitShield,
              priority: 'Critical',
              rationale: 'Protect afternoon study momentum from phone checking.',
              shieldedDistraction: 'Instagram, Reels, TikTok, YouTube Shorts',
            ),
            SuggestedRoutineBlock(
              id: 'demo-$timestamp-3',
              title: 'Exam Practice: Timed Problem Solving',
              startTime: '16:00',
              endTime: '17:30',
              category: 'positiveHabit',
              blockType: TimelineBlockType.routineFocus,
              priority: 'High',
              rationale: 'Simulated 90-minute closed-book problem set.',
            ),
          ]
        : (isLab
            ? [
                SuggestedRoutineBlock(
                  id: 'demo-$timestamp-1',
                  title: 'Lab Prep: Git Push & Test Suite Run',
                  startTime: '11:00',
                  endTime: '12:00',
                  category: 'academicPrep',
                  blockType: TimelineBlockType.academicClass,
                  priority: 'High',
                  rationale: 'Verify automated grading test scripts before lab session.',
                ),
                SuggestedRoutineBlock(
                  id: 'demo-$timestamp-2',
                  title: 'Shield: Social Media Barrier',
                  startTime: '14:30',
                  endTime: '16:00',
                  category: 'antiHabit',
                  blockType: TimelineBlockType.antiHabitShield,
                  priority: 'Critical',
                  rationale: 'Zero distraction zone during post-lab code consolidation.',
                  shieldedDistraction: 'Discord, Reddit, Steam',
                ),
                SuggestedRoutineBlock(
                  id: 'demo-$timestamp-3',
                  title: 'Deep Focus: Software Architecture Diagram',
                  startTime: '17:00',
                  endTime: '18:30',
                  category: 'positiveHabit',
                  blockType: TimelineBlockType.routineFocus,
                  priority: 'High',
                  rationale: 'Refine system component diagram for semester submission.',
                ),
              ]
            : [
                SuggestedRoutineBlock(
                  id: 'demo-$timestamp-1',
                  title: 'Deep Focus: Software Engineering Wireframes',
                  startTime: '11:00',
                  endTime: '12:30',
                  category: 'positiveHabit',
                  blockType: TimelineBlockType.routineFocus,
                  priority: 'High',
                  rationale: 'Targeted design consolidation in morning open slot.',
                ),
                SuggestedRoutineBlock(
                  id: 'demo-$timestamp-2',
                  title: 'Shield: High-Dopamine Distraction Barrier',
                  startTime: '14:30',
                  endTime: '16:00',
                  category: 'antiHabit',
                  blockType: TimelineBlockType.antiHabitShield,
                  priority: 'Critical',
                  rationale: 'Carving defensive shield during post-lunch energy dip.',
                  shieldedDistraction: 'Instagram, TikTok, YouTube Shorts, Gaming',
                ),
                SuggestedRoutineBlock(
                  id: 'demo-$timestamp-3',
                  title: 'Pre-Lecture Review: Operating Systems',
                  startTime: '16:30',
                  endTime: '17:30',
                  category: 'academicPrep',
                  blockType: TimelineBlockType.academicClass,
                  priority: 'Medium',
                  rationale: 'Review CPU scheduling algorithms before tomorrow lecture.',
                ),
              ]);

    _currentBlocks = defaultBlocks;

    final greeting = prompt != null && prompt.isNotEmpty
        ? 'I\'ve tailored today\'s schedule for "${prompt.trim()}". I allocated ${defaultBlocks.length} strategic blocks to protect your focus and keep your anti-habit shields active.'
        : 'Welcome! I analyzed today\'s timetable and detected your open focus windows. Here is a balanced plan with study intervals and a crimson anti-habit shield.';

    final userMsg = AiChatMessage(
      id: 'demo-$timestamp-user',
      text: prompt ?? 'Plan my day with focus blocks and distraction shields',
      isUser: true,
      timestamp: DateTime.now(),
    );
    final aiMsg = AiChatMessage(
      id: 'demo-$timestamp-ai',
      text: greeting,
      isUser: false,
      timestamp: DateTime.now(),
      suggestedBlocksSnapshot: List.from(defaultBlocks),
    );

    _messageHistory = [userMsg, aiMsg];

    return ConversationalRoutineResponse(
      replyText: greeting,
      updatedBlocks: defaultBlocks,
    );
  }
}

/// Riverpod provider for AiConversationalAgentService
final aiConversationalAgentServiceProvider =
    Provider<AiConversationalAgentService>((ref) {
  final apiKeyService = ref.watch(apiKeyServiceProvider);
  return AiConversationalAgentService(apiKeyService);
});
