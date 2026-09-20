import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/routine_models.dart';
import 'api_key_service.dart';

class GeminiApiKeyMissingException implements Exception {
  final String message;
  const GeminiApiKeyMissingException([
    this.message = 'Gemini API Key is not configured. Please set your key in Settings.',
  ]);

  @override
  String toString() => message;
}

class RoutineParserService {
  final ApiKeyService _apiKeyService;

  RoutineParserService(this._apiKeyService);

  static const String _promptInstructions = '''
You are an expert multimodal academic timetable & routine vision parser for university students.
Analyze the provided schedule image, document, or syllabus text (including photos of printed paper routines on notice boards, classroom whiteboard grids, and semester PDF tables).
Extract every individual class, laboratory sessional, tutorial, test, or milestone into a clean structured JSON array.

EXTRACTION & INFERENCE RULES:
1. MULTIMODAL GRID ALIGNMENT: Timetables often appear as grid matrices where days (Mon-Sun) are rows/columns and time intervals (e.g. 08:30-10:00, 10:00-11:30) are header cells. Cross-reference row and column headers accurately.
2. "courseCode": Course code (e.g. "CSE 3101", "MATH 2205", "PHY 1101", "EEE 2102"). Infer from context or course titles if abbreviated.
3. "title": Course name or topic (e.g. "Database Systems", "Software Engineering Lab", "Discrete Mathematics").
4. "room": Room or laboratory identifier (e.g. "Room 402", "Lab 3, Software Wing", "Hall B"). Default to "TBA" if not specified.
5. "instructor": Teacher, Professor, or TA initials/name (e.g. "Prof. Sarah Khan", "SK", "Dr. Vance"). Default to "TBA" if unknown.
6. "type": Must be one of:
   - "lecture" (Standard theoretical class)
   - "sessionalLab" (Lab, practical, workshop, project sessional)
   - "tutorial" (Discussion or problem solving session)
   - "classTest" (Class test, quiz, CT)
   - "assignment" (Assignment deadline/slot)
   - "midterm" (Midterm examination)
   - "termFinal" (Term final examination)
7. "dayOfWeek": Integer representing the weekly cycle day (1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun).
8. "startTime": 24-hour time format "HH:mm" (e.g. "09:00", "13:30").
9. "endTime": 24-hour time format "HH:mm" (e.g. "10:30", "15:30").
10. "syllabusNotes": Any special instructions, lab prerequisites, or assignment notes.

OUTPUT FORMAT:
Return ONLY a valid JSON array of objects without markdown formatting or commentary.
Example:
[
  {
    "courseCode": "CSE 3101",
    "title": "Database Systems",
    "type": "lecture",
    "room": "Room 301",
    "instructor": "Prof. Sarah Khan",
    "dayOfWeek": 2,
    "startTime": "09:00",
    "endTime": "10:30",
    "syllabusNotes": "Relational algebra & SQL queries"
  }
]
''';

  Future<GenerativeModel> _getModel() async {
    final apiKey = await _apiKeyService.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const GeminiApiKeyMissingException();
    }

    return GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey.trim(),
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
      ),
    );
  }

  /// Downscales high-resolution camera images to a max dimension of 1560px
  /// to prevent Out-Of-Memory (OOM) and OEM Low-Memory Killer (LMK) aborts.
  static Future<Uint8List> downscaleImageIfNeeded(
    Uint8List rawBytes, {
    int maxDimension = 1560,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(rawBytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      final width = image.width;
      final height = image.height;

      if (width <= maxDimension && height <= maxDimension) {
        return rawBytes;
      }

      int targetWidth;
      int targetHeight;
      if (width >= height) {
        targetWidth = maxDimension;
        targetHeight = (height * (maxDimension / width)).round();
      } else {
        targetHeight = maxDimension;
        targetWidth = (width * (maxDimension / height)).round();
      }

      final resizedCodec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final resizedFrame = await resizedCodec.getNextFrame();
      final resizedImage = resizedFrame.image;

      final byteData =
          await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Image downsampling fallback: $e');
    }
    return rawBytes;
  }

  /// Parse academic events from an image (photo of paper routine, screenshot)
  Future<List<AcademicEvent>> parseFromImage(
    Uint8List imageBytes,
    String mimeType,
  ) async {
    final processedBytes = await downscaleImageIfNeeded(imageBytes);
    final mime = processedBytes.length != imageBytes.length ? 'image/png' : mimeType;

    final model = await _getModel();
    final prompt = TextPart(_promptInstructions);
    final imagePart = DataPart(mime, processedBytes);

    final response = await model.generateContent([
      Content.multi([prompt, imagePart]),
    ]).timeout(const Duration(seconds: 20));

    final rawText = response.text;
    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception('Gemini returned an empty response for the image.');
    }

    return _parseJsonResponse(rawText);
  }

  /// Parse academic events from a document (PDF bytes or text file)
  Future<List<AcademicEvent>> parseFromDocument(
    Uint8List fileBytes,
    String fileName,
    String mimeType,
  ) async {
    final model = await _getModel();
    final prompt = TextPart(_promptInstructions);

    if (mimeType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf')) {
      final pdfPart = DataPart('application/pdf', fileBytes);
      final response = await model.generateContent([
        Content.multi([prompt, pdfPart]),
      ]).timeout(const Duration(seconds: 20));
      final rawText = response.text;
      if (rawText == null || rawText.trim().isEmpty) {
        throw Exception('Gemini returned an empty response for the PDF document.');
      }
      return _parseJsonResponse(rawText);
    } else {
      // Treat as plain text / CSV / Markdown
      final textContent = utf8.decode(fileBytes, allowMalformed: true);
      return parseFromText(textContent);
    }
  }

  /// Parse academic events from raw text pasted by the user
  Future<List<AcademicEvent>> parseFromText(String rawScheduleText) async {
    final model = await _getModel();
    final prompt = '$_promptInstructions\n\nINPUT SCHEDULE TEXT TO PARSE:\n$rawScheduleText';

    final response = await model.generateContent([
      Content.text(prompt),
    ]).timeout(const Duration(seconds: 20));

    final rawText = response.text;
    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception('Gemini returned an empty response for the text input.');
    }

    return _parseJsonResponse(rawText);
  }

  /// Exposes response parser for testing and local verification
  @visibleForTesting
  List<AcademicEvent> parseJsonResponse(String rawJson) => _parseJsonResponse(rawJson);

  /// Clean, sanitize, and convert JSON string into a list of AcademicEvent objects
  List<AcademicEvent> _parseJsonResponse(String rawJson) {
    String cleaned = rawJson.trim();
    // Strip markdown code fences if model included them despite instructions
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
      throw const FormatException('Expected a JSON array of academic events.');
    }

    final List<AcademicEvent> events = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is Map<String, dynamic>) {
        final event = _mapToAcademicEvent(item, 'ae-ai-$timestamp-$i');
        events.add(event);
      }
    }

    return events;
  }

  AcademicEvent _mapToAcademicEvent(Map<String, dynamic> json, String generatedId) {
    final courseCode = (json['courseCode'] ?? '').toString().trim().toUpperCase();
    final title = (json['title'] ?? '').toString().trim();
    final room = (json['room'] ?? 'TBA').toString().trim();
    final instructor = (json['instructor'] ?? 'TBA').toString().trim();
    final syllabusNotes = (json['syllabusNotes'] ?? '').toString().trim();

    // Map Type
    final typeStr = (json['type'] ?? 'lecture').toString().toLowerCase().trim();
    final type = _resolveType(typeStr);

    // Map Day of Week (1-7)
    final dayOfWeek = _resolveDayOfWeek(json['dayOfWeek']);

    // Map Times
    final startTime = _normalizeTime(json['startTime'] ?? '09:00');
    final endTime = _normalizeTime(json['endTime'] ?? '10:30');

    return AcademicEvent(
      id: generatedId,
      courseCode: courseCode.isEmpty ? 'CLASS' : courseCode,
      title: title.isEmpty ? 'Academic Session' : title,
      type: type,
      room: room.isEmpty ? 'TBA' : room,
      instructor: instructor.isEmpty ? 'TBA' : instructor,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      syllabusNotes: syllabusNotes,
      isCompleted: false,
      syncToCalendar: true,
    );
  }

  AcademicEventType _resolveType(String typeStr) {
    if (typeStr.contains('lecture') ||
        typeStr.contains('theory') ||
        typeStr.startsWith('lec')) {
      return AcademicEventType.lecture;
    }
    if (typeStr.contains('lab') ||
        typeStr.contains('sessional') ||
        typeStr.contains('practical')) {
      return AcademicEventType.sessionalLab;
    }
    if (typeStr.contains('tutorial') || typeStr.contains('discussion')) {
      return AcademicEventType.tutorial;
    }
    if (typeStr.contains('test') ||
        typeStr.contains('quiz') ||
        typeStr == 'ct' ||
        typeStr.contains('class test')) {
      return AcademicEventType.classTest;
    }
    if (typeStr.contains('assign') ||
        typeStr.contains('hw') ||
        typeStr.contains('homework') ||
        typeStr.contains('project')) {
      return AcademicEventType.assignment;
    }
    if (typeStr.contains('mid') || typeStr.contains('midterm')) {
      return AcademicEventType.midterm;
    }
    if (typeStr.contains('final') ||
        typeStr.contains('term') ||
        typeStr.contains('sem')) {
      return AcademicEventType.termFinal;
    }
    return AcademicEventType.lecture;
  }

  int? _resolveDayOfWeek(dynamic day) {
    if (day == null) return null;
    if (day is int) {
      return (day >= 1 && day <= 7) ? day : null;
    }
    final str = day.toString().trim().toUpperCase();
    if (str.startsWith('MON')) return 1;
    if (str.startsWith('TUE')) return 2;
    if (str.startsWith('WED')) return 3;
    if (str.startsWith('THU')) return 4;
    if (str.startsWith('FRI')) return 5;
    if (str.startsWith('SAT')) return 6;
    if (str.startsWith('SUN')) return 7;

    final parsed = int.tryParse(str);
    if (parsed != null && parsed >= 1 && parsed <= 7) {
      return parsed;
    }
    return null;
  }

  String _normalizeTime(dynamic rawTime) {
    if (rawTime == null) return '09:00';
    String time = rawTime.toString().trim().toUpperCase();

    // Check for 12-hour format e.g. "9:00 AM" or "02:30 PM"
    final amPmRegex = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');
    final match = amPmRegex.firstMatch(time);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = match.group(2)!;
      final period = match.group(3)!;
      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return '${hour.toString().padLeft(2, '0')}:$minute';
    }

    // Check 24-hour format e.g. "9:00" or "09:00:00"
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    return '09:00';
  }
}

/// Provider for RoutineParserService
final routineParserServiceProvider = Provider<RoutineParserService>((ref) {
  final apiKeyService = ref.watch(apiKeyServiceProvider);
  return RoutineParserService(apiKeyService);
});
