import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do/core/models/routine_models.dart';
import 'package:not_to_do/core/services/api_key_service.dart';
import 'package:not_to_do/core/services/routine_parser_service.dart';

void main() {
  group('RoutineParserService JSON Parsing Tests', () {
    late RoutineParserService parser;

    setUp(() {
      parser = RoutineParserService(ApiKeyService());
    });

    test('parses clean JSON array of academic events from Gemini Vision', () {
      const rawJson = '''
[
  {
    "courseCode": "CSE 3101",
    "title": "Database Management Systems",
    "type": "lecture",
    "dayOfWeek": 2,
    "startTime": "09:00",
    "endTime": "10:30",
    "room": "Room 301",
    "instructor": "Prof. Sarah Khan"
  },
  {
    "courseCode": "CSE 3102",
    "title": "Software Engineering Lab",
    "type": "lab",
    "dayOfWeek": 4,
    "startTime": "11:00",
    "endTime": "13:30",
    "room": "Lab 3",
    "instructor": "Dr. Alex Mercer",
    "syllabusNotes": "Bring diagrams"
  }
]
''';

      final events = parser.parseJsonResponse(rawJson);
      expect(events.length, 2);

      expect(events[0].courseCode, 'CSE 3101');
      expect(events[0].title, 'Database Management Systems');
      expect(events[0].type, AcademicEventType.lecture);
      expect(events[0].dayOfWeek, 2);
      expect(events[0].startTime, '09:00');
      expect(events[0].endTime, '10:30');

      expect(events[1].courseCode, 'CSE 3102');
      expect(events[1].type, AcademicEventType.sessionalLab);
      expect(events[1].dayOfWeek, 4);
      expect(events[1].syllabusNotes, 'Bring diagrams');
    });

    test('strips markdown code fences from Gemini responses', () {
      const markdownJson = '''
```json
[
  {
    "courseCode": "MATH 2205",
    "title": "Discrete Mathematics",
    "type": "tutorial",
    "dayOfWeek": "Wednesday",
    "startTime": "02:30 PM",
    "endTime": "04:00 PM",
    "room": "Room 205",
    "instructor": "TA Emily"
  }
]
```
''';

      final events = parser.parseJsonResponse(markdownJson);
      expect(events.length, 1);
      expect(events[0].courseCode, 'MATH 2205');
      expect(events[0].type, AcademicEventType.tutorial);
      expect(events[0].dayOfWeek, 3); // Wednesday = 3
      expect(events[0].startTime, '14:30'); // 2:30 PM converted to 24h
      expect(events[0].endTime, '16:00');   // 4:00 PM converted to 24h
    });

    test('throws FormatException when Gemini response is not a list', () {
      const invalidJson = '{"error": "not an array"}';
      expect(() => parser.parseJsonResponse(invalidJson), throwsFormatException);
    });
  });
}
