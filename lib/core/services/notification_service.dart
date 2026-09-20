import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/routine_models.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? notificationsPlugin})
      : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  static const String channelLectures = 'academic_lectures';
  static const String channelAssessments = 'academic_assessments';
  static const String channelDeadlines = 'assignment_deadlines';
  static const String channelHabits = 'habit_defense';

  /// Initializes timezone data, notification settings, and Android channels.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz_data.initializeTimeZones();
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Create 4 distinct Android Notification Channels
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          channelLectures,
          'Academic Lectures & Labs',
          description: '15-minute advance alerts for lectures and sessional labs',
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          channelAssessments,
          'Academic Assessments & Exams',
          description: 'Multi-stage alerts for Class Tests, Midterms, and Finals',
          importance: Importance.max,
          enableVibration: true,
        ),
      );

      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          channelDeadlines,
          'Assignment Deadlines',
          description: 'Timely reminders for upcoming coursework and assignment deadlines',
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          channelHabits,
          'Habit Defense Check-in',
          description: 'Evening 9:00 PM check-in to defend streaks and maintain discipline',
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      // Request notification permissions for Android 13+ (non-blocking)
      try {
        await androidImpl.requestNotificationsPermission();
      } catch (e) {
        debugPrint('Error requesting notification permission: $e');
      }
    }

    _isInitialized = true;
  }

  /// Fault-tolerant zoned schedule that falls back to inexact mode if exact alarms are denied.
  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: uiLocalNotificationDateInterpretation,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      debugPrint('[NotificationService] Exact alarm failed ($e). Falling back to inexactAllowWhileIdle.');
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: uiLocalNotificationDateInterpretation,
          matchDateTimeComponents: matchDateTimeComponents,
        );
      } catch (fallbackError) {
        debugPrint('[NotificationService] Inexact schedule failed: $fallbackError');
      }
    }
  }

  int _calcId(String key, int offset) {
    return (key.hashCode ^ offset) & 0x7FFFFFFF;
  }

  /// Schedules granular alerts for an AcademicEvent based on its category.
  Future<void> scheduleEventAlerts(AcademicEvent event) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    final startTimeParts = event.startTime.split(':');
    final startHour = int.tryParse(startTimeParts[0]) ?? 9;
    final startMin =
        int.tryParse(startTimeParts.length > 1 ? startTimeParts[1] : '0') ?? 0;

    if (event.type.isExamOrAssignment) {
      // -------------------------------------------------------------
      // ASSESSMENTS & EXAMS: Multi-stage alerts (24h prior, 2h prior)
      // -------------------------------------------------------------
      final targetDate = event.specificDate ?? DateTime.now();
      final examTime = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        startHour,
        startMin,
      );

      // Alert 1: 24 hours prior
      final alert24h = examTime.subtract(const Duration(hours: 24));
      if (alert24h.isAfter(now)) {
        await _safeZonedSchedule(
          id: _calcId(event.id, 24),
          title: 'Tomorrow: ${event.type.displayName} • ${event.courseCode}',
          body: '${event.title} in Room ${event.room}. Starts at ${event.startTime}.',
          scheduledDate: alert24h,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              channelAssessments,
              'Academic Assessments & Exams',
              importance: Importance.max,
              priority: Priority.max,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // Alert 2: 2 hours prior
      final alert2h = examTime.subtract(const Duration(hours: 2));
      if (alert2h.isAfter(now)) {
        await _safeZonedSchedule(
          id: _calcId(event.id, 2),
          title: 'Starting Soon: ${event.courseCode} ${event.type.displayName}',
          body: 'Hall gates open in 2 hours. Venue: ${event.room}.',
          scheduledDate: alert2h,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              channelAssessments,
              'Academic Assessments & Exams',
              importance: Importance.max,
              priority: Priority.max,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } else {
      // -------------------------------------------------------------
      // REGULAR LECTURE / LAB: 15 minutes in advance
      // -------------------------------------------------------------
      if (event.dayOfWeek != null) {
        final alertId = _calcId(event.id, 15);

        // Find next occurrence of weekday
        int daysAhead = event.dayOfWeek! - now.weekday;
        if (daysAhead < 0) daysAhead += 7;

        var classDateTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          startHour,
          startMin,
        ).add(Duration(days: daysAhead));

        final alertTime = classDateTime.subtract(const Duration(minutes: 15));
        final scheduledTime =
            alertTime.isBefore(now) ? alertTime.add(const Duration(days: 7)) : alertTime;

        await _safeZonedSchedule(
          id: alertId,
          title: 'Upcoming: ${event.courseCode} (${event.title})',
          body: 'Room: ${event.room} • Starts at ${event.startTime}.',
          scheduledDate: scheduledTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              channelLectures,
              'Academic Lectures & Labs',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  /// Cancels all scheduled alerts associated with an event ID.
  Future<void> cancelEventAlerts(String eventId) async {
    await initialize();
    await _notificationsPlugin.cancel(_calcId(eventId, 15));
    await _notificationsPlugin.cancel(_calcId(eventId, 2));
    await _notificationsPlugin.cancel(_calcId(eventId, 24));
    await _notificationsPlugin.cancel(_calcId(eventId, 6));
  }

  /// Schedules daily repeating evening habit check-in at 21:00 (9:00 PM).
  Future<void> scheduleHabitDefenseAlert() async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21, // 9:00 PM
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _safeZonedSchedule(
      id: 999999, // Unique ID for daily habit defense
      title: 'Defend Your Streaks 🔥',
      body: 'Review your anti-habits and confirm today\'s protected disciplines.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelHabits,
          'Habit Defense Check-in',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels the daily habit defense notification.
  Future<void> cancelHabitDefenseAlert() async {
    await initialize();
    await _notificationsPlugin.cancel(999999);
  }

  /// Schedules 10-minute advance notifications for approved timeline focus blocks and anti-habit shields.
  Future<void> scheduleTimelineBlockAlerts(List<TimelineBlock> blocks) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);

    for (final block in blocks) {
      if (block.type == TimelineBlockType.calendarSync) continue;

      final startParts = block.startTime.split(':');
      final startHour = int.tryParse(startParts[0]) ?? 9;
      final startMin = int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0;

      final blockStart = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        startHour,
        startMin,
      );

      final alertTime = blockStart.subtract(const Duration(minutes: 10));
      if (alertTime.isAfter(now)) {
        final isShield = block.type == TimelineBlockType.antiHabitShield;
        final channelId = isShield ? channelHabits : channelLectures;
        final channelName = isShield ? 'Habit Defense Check-in' : 'Academic Focus Blocks';

        final title = isShield
            ? '🛡️ Not To Do Shield Arms in 10m: ${block.title}'
            : '⚡ Focus Session Starting: ${block.title}';

        final body = isShield
            ? (block.subtitle.isNotEmpty
                ? block.subtitle
                : 'Distraction lock armed. Defend your streak!')
            : 'Scheduled for ${block.startTime} – ${block.endTime}. Prepare your workspace.';

        final alertId = _calcId(block.id, 10);

        await _safeZonedSchedule(
          id: alertId,
          title: title,
          body: body,
          scheduledDate: alertTime,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Reschedules all active academic alerts.
  Future<void> rescheduleAllActiveAlerts({
    required List<AcademicEvent> events,
    required SyncSettings settings,
  }) async {
    await initialize();

    // Cancel existing class alerts
    await _notificationsPlugin.cancelAll();

    // Re-schedule daily habit defense if enabled
    if (settings.autoBlockDistractions) {
      await scheduleHabitDefenseAlert();
    }

    // Re-schedule lecture alerts if enabled
    if (settings.classReminderAlerts) {
      for (final event in events) {
        await scheduleEventAlerts(event);
      }
    }
  }
}

/// Riverpod provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
