import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/routine_models.dart';

class TwoWaySyncResult {
  final int exportedCount;
  final List<TimelineBlock> importedBlocks;
  final String? calendarName;

  const TwoWaySyncResult({
    required this.exportedCount,
    required this.importedBlocks,
    this.calendarName,
  });
}

class CalendarSyncService {
  final DeviceCalendarPlugin _deviceCalendar;
  final List<String> _pendingSyncQueue = [];

  CalendarSyncService({DeviceCalendarPlugin? deviceCalendar})
      : _deviceCalendar = deviceCalendar ?? DeviceCalendarPlugin();

  List<String> get pendingSyncQueue => List.unmodifiable(_pendingSyncQueue);
  bool get hasPendingSync => _pendingSyncQueue.isNotEmpty;

  void enqueuePendingSync(String id) {
    if (!_pendingSyncQueue.contains(id)) {
      _pendingSyncQueue.add(id);
    }
  }

  void clearPendingSync(String id) {
    _pendingSyncQueue.remove(id);
  }

  /// Reconciles all pending offline synchronization mutations
  Future<int> reconcilePendingQueue(
    List<AcademicEvent> allEvents,
    Future<void> Function(String eventId, String calendarId) onEventSynced,
  ) async {
    if (_pendingSyncQueue.isEmpty) return 0;

    int reconciledCount = 0;
    final queueCopy = List<String>.from(_pendingSyncQueue);

    for (final eventId in queueCopy) {
      final event = allEvents.where((e) => e.id == eventId).firstOrNull;
      if (event != null) {
        final calId = await exportEventToCalendar(event);
        if (calId != null) {
          await onEventSynced(event.id, calId);
          _pendingSyncQueue.remove(eventId);
          reconciledCount++;
        }
      } else {
        _pendingSyncQueue.remove(eventId);
      }
    }
    return reconciledCount;
  }

  /// Validates and requests native calendar read/write permissions.
  Future<bool> requestCalendarPermissions() async {
    try {
      // 1. Check via permission_handler
      final status = await Permission.calendarFullAccess.status;
      if (!status.isGranted) {
        final request = await Permission.calendarFullAccess.request();
        if (!request.isGranted) {
          // Fallback to basic calendar permission for older Android/iOS
          final basicRequest = await Permission.calendar.request();
          if (!basicRequest.isGranted) {
            return false;
          }
        }
      }

      // 2. Double-check via device_calendar plugin
      var permissionsGranted = await _deviceCalendar.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendar.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          return false;
        }
      }

      return true;
    } catch (_) {
      // Gracefully handle web or desktop where plugin might not have native permissions
      return false;
    }
  }

  /// Finds the primary writable calendar (preferring Google Calendar accounts).
  Future<Calendar?> retrievePrimaryCalendar() async {
    try {
      final calendarsResult = await _deviceCalendar.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        return null;
      }

      final writable = calendarsResult.data!.where((c) => c.isReadOnly == false).toList();
      if (writable.isEmpty) return null;

      // Prefer Google Calendar
      final googleCal = writable.firstWhere(
        (c) =>
            (c.accountName?.toLowerCase().contains('gmail') ?? false) ||
            (c.accountType?.toLowerCase().contains('google') ?? false) ||
            (c.isDefault ?? false),
        orElse: () => writable.first,
      );

      return googleCal;
    } catch (_) {
      return null;
    }
  }

  /// Exports an AcademicEvent to the device calendar.
  /// Returns the persistent calendarEventId if successful.
  Future<String?> exportEventToCalendar(AcademicEvent event) async {
    final hasPerms = await requestCalendarPermissions();
    if (!hasPerms) return null;

    final calendar = await retrievePrimaryCalendar();
    if (calendar == null || calendar.id == null) return null;

    try {
      final now = tz.TZDateTime.now(tz.local);
      final startTimeParts = event.startTime.split(':');
      final endTimeParts = event.endTime.split(':');

      final startHour = int.tryParse(startTimeParts[0]) ?? 9;
      final startMin = int.tryParse(startTimeParts.length > 1 ? startTimeParts[1] : '0') ?? 0;

      final endHour = int.tryParse(endTimeParts[0]) ?? 10;
      final endMin = int.tryParse(endTimeParts.length > 1 ? endTimeParts[1] : '30') ?? 30;

      tz.TZDateTime eventStart;
      tz.TZDateTime eventEnd;

      if (event.specificDate != null) {
        final d = event.specificDate!;
        eventStart = tz.TZDateTime(tz.local, d.year, d.month, d.day, startHour, startMin);
        eventEnd = tz.TZDateTime(tz.local, d.year, d.month, d.day, endHour, endMin);
      } else if (event.dayOfWeek != null) {
        // Calculate the next date matching event.dayOfWeek (1=Mon ... 7=Sun)
        final targetWeekday = event.dayOfWeek!;
        int daysAhead = targetWeekday - now.weekday;
        if (daysAhead < 0) daysAhead += 7;

        final targetDate = now.add(Duration(days: daysAhead));
        eventStart = tz.TZDateTime(tz.local, targetDate.year, targetDate.month, targetDate.day, startHour, startMin);
        eventEnd = tz.TZDateTime(tz.local, targetDate.year, targetDate.month, targetDate.day, endHour, endMin);
      } else {
        eventStart = tz.TZDateTime(tz.local, now.year, now.month, now.day, startHour, startMin);
        eventEnd = tz.TZDateTime(tz.local, now.year, now.month, now.day, endHour, endMin);
      }

      final deviceEvent = Event(
        calendar.id,
        eventId: event.calendarEventId,
        title: '${event.courseCode}: ${event.title}',
        description: 'Type: ${event.type.displayName}\nRoom: ${event.room}\nInstructor: ${event.instructor}\nNotes: ${event.syllabusNotes}\n[Synced by Not To Do App]',
        location: event.room,
        start: eventStart,
        end: eventEnd,
        reminders: [
          Reminder(minutes: 15),
          if (event.type.isExamOrAssignment) ...[
            Reminder(minutes: 120), // 2 hours prior
            Reminder(minutes: 1440), // 24 hours prior
          ],
        ],
      );

      // Add weekly recurrence for regular academic lectures/labs
      if (event.dayOfWeek != null && !event.type.isExamOrAssignment) {
        final dayOfWeekEnum = _mapIntToDayOfWeek(event.dayOfWeek!);
        if (dayOfWeekEnum != null) {
          deviceEvent.recurrenceRule = RecurrenceRule(
            RecurrenceFrequency.Weekly,
            daysOfWeek: [dayOfWeekEnum],
          );
        }
      }

      final result = await _deviceCalendar.createOrUpdateEvent(deviceEvent);
      if (result != null && result.isSuccess && result.data != null) {
        clearPendingSync(event.id);
        return result.data;
      }

      // Check if unauthorized or token expired: attempt silent refresh
      final isAuthError = result?.errors.any((e) {
            final msg = e.errorMessage.toLowerCase();
            return msg.contains('unauthorized') ||
                msg.contains('401') ||
                msg.contains('token') ||
                msg.contains('permission');
          }) ??
          false;

      if (isAuthError) {
        final refreshed = await requestCalendarPermissions();
        if (refreshed) {
          final retryResult =
              await _deviceCalendar.createOrUpdateEvent(deviceEvent);
          if (retryResult != null &&
              retryResult.isSuccess &&
              retryResult.data != null) {
            clearPendingSync(event.id);
            return retryResult.data;
          }
        }
      }

      enqueuePendingSync(event.id);
    } catch (_) {
      enqueuePendingSync(event.id);
    }

    return null;
  }

  /// Deletes a previously exported event from the device calendar.
  Future<bool> deleteCalendarEvent(String? calendarEventId) async {
    if (calendarEventId == null || calendarEventId.isEmpty) return false;

    final hasPerms = await requestCalendarPermissions();
    if (!hasPerms) return false;

    final calendar = await retrievePrimaryCalendar();
    if (calendar == null || calendar.id == null) return false;

    try {
      final result = await _deviceCalendar.deleteEvent(calendar.id, calendarEventId);
      return result.isSuccess && (result.data ?? false);
    } catch (_) {
      return false;
    }
  }

  /// Fetches non-app personal events scheduled for today and converts them into TimelineBlocks.
  Future<List<TimelineBlock>> importTodayExternalEvents() async {
    final hasPerms = await requestCalendarPermissions();
    if (!hasPerms) return [];

    final calendar = await retrievePrimaryCalendar();
    if (calendar == null || calendar.id == null) return [];

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day, 0, 0);
      final endDate = DateTime(now.year, now.month, now.day, 23, 59);

      final eventsResult = await _deviceCalendar.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(startDate: startDate, endDate: endDate),
      );

      if (!eventsResult.isSuccess || eventsResult.data == null) {
        return [];
      }

      final List<TimelineBlock> externalBlocks = [];
      for (final event in eventsResult.data!) {
        // Skip events created by this app
        final desc = event.description ?? '';
        if (desc.contains('[Synced by Not To Do App]')) {
          continue;
        }

        final start = event.start;
        final end = event.end;
        if (start == null || end == null) continue;

        final startTimeStr =
            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
        final endTimeStr =
            '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

        externalBlocks.add(
          TimelineBlock(
            id: 'ext-${event.eventId ?? DateTime.now().millisecondsSinceEpoch}',
            title: event.title ?? 'External Appointment',
            startTime: startTimeStr,
            endTime: endTimeStr,
            type: TimelineBlockType.calendarSync,
            subtitle: 'Imported from Google Calendar',
            location: event.location,
            badgeText: 'EXTERNAL',
          ),
        );
      }

      return externalBlocks;
    } catch (_) {
      return [];
    }
  }

  /// Performs an end-to-end two-way sync: exports active academic events and imports external events.
  Future<TwoWaySyncResult> performTwoWaySync({
    required List<AcademicEvent> eventsToExport,
    required Future<void> Function(String eventId, String calendarId) onEventSynced,
  }) async {
    final hasPerms = await requestCalendarPermissions();
    if (!hasPerms) {
      return const TwoWaySyncResult(exportedCount: 0, importedBlocks: []);
    }

    final calendar = await retrievePrimaryCalendar();
    int exportedCount = 0;

    for (final event in eventsToExport) {
      if (event.syncToCalendar) {
        final calId = await exportEventToCalendar(event);
        if (calId != null) {
          exportedCount++;
          await onEventSynced(event.id, calId);
        }
      }
    }

    final imported = await importTodayExternalEvents();

    return TwoWaySyncResult(
      exportedCount: exportedCount,
      importedBlocks: imported,
      calendarName: calendar?.name ?? 'Google Calendar',
    );
  }

  /// Exports a list of suggested/approved TimelineBlocks (focus blocks, anti-habit shields)
  /// directly to the device Google Calendar.
  Future<int> exportTimelineBlocksToCalendar(List<TimelineBlock> blocks) async {
    final hasPerms = await requestCalendarPermissions();
    if (!hasPerms) return 0;

    final calendar = await retrievePrimaryCalendar();
    if (calendar == null || calendar.id == null) return 0;

    final now = tz.TZDateTime.now(tz.local);
    int exported = 0;

    for (final block in blocks) {
      // Don't re-export blocks that are already external appointments
      if (block.type == TimelineBlockType.calendarSync) continue;

      final startParts = block.startTime.split(':');
      final endParts = block.endTime.split(':');
      final startHour = int.tryParse(startParts[0]) ?? 9;
      final startMin = int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0;
      final endHour = int.tryParse(endParts[0]) ?? 10;
      final endMin = int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0;

      final eventStart = tz.TZDateTime(tz.local, now.year, now.month, now.day, startHour, startMin);
      final eventEnd = tz.TZDateTime(tz.local, now.year, now.month, now.day, endHour, endMin);

      final isShield = block.type == TimelineBlockType.antiHabitShield;
      final titlePrefix = isShield ? '🛡️ [SHIELD]' : '⚡ [FOCUS]';

      final description = [
        'Category: ${isShield ? "Anti-Habit Distraction Barrier" : "Focus Routine Block"}',
        if (block.subtitle.isNotEmpty) 'Details: ${block.subtitle}',
        if (block.replacementTrigger != null && block.replacementTrigger!.isNotEmpty)
          'Intervention Trigger: ${block.replacementTrigger}',
        if (block.location != null && block.location!.isNotEmpty) 'Location: ${block.location}',
        '[Synced by Not To Do App]',
      ].join('\n');

      final deviceEvent = Event(
        calendar.id,
        title: '$titlePrefix ${block.title}',
        description: description,
        location: block.location,
        start: eventStart,
        end: eventEnd,
        reminders: [
          Reminder(minutes: 10),
        ],
      );

      try {
        final result = await _deviceCalendar.createOrUpdateEvent(deviceEvent);
        if (result != null && result.isSuccess) {
          exported++;
        }
      } catch (_) {}
    }

    return exported;
  }

  DayOfWeek? _mapIntToDayOfWeek(int day) {
    switch (day) {
      case 1:
        return DayOfWeek.Monday;
      case 2:
        return DayOfWeek.Tuesday;
      case 3:
        return DayOfWeek.Wednesday;
      case 4:
        return DayOfWeek.Thursday;
      case 5:
        return DayOfWeek.Friday;
      case 6:
        return DayOfWeek.Saturday;
      case 7:
        return DayOfWeek.Sunday;
      default:
        return null;
    }
  }
}

/// Riverpod provider for CalendarSyncService
final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  return CalendarSyncService();
});
