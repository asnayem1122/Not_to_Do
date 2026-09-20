import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'routine_models.g.dart';

// =========================================================================
// ACADEMIC EVENT MODEL (typeId: 0, typeId: 10)
// =========================================================================
@HiveType(typeId: 10)
enum AcademicEventType {
  @HiveField(0)
  lecture,
  @HiveField(1)
  sessionalLab,
  @HiveField(2)
  tutorial,
  @HiveField(3)
  classTest,
  @HiveField(4)
  assignment,
  @HiveField(5)
  midterm,
  @HiveField(6)
  termFinal,
}

extension AcademicEventTypeX on AcademicEventType {
  String get displayName {
    switch (this) {
      case AcademicEventType.lecture:
        return 'Lecture';
      case AcademicEventType.sessionalLab:
        return 'Sessional Lab';
      case AcademicEventType.tutorial:
        return 'Tutorial';
      case AcademicEventType.classTest:
        return 'Class Test (CT)';
      case AcademicEventType.assignment:
        return 'Assignment';
      case AcademicEventType.midterm:
        return 'Midterm Exam';
      case AcademicEventType.termFinal:
        return 'Term Final Exam';
    }
  }

  bool get isExamOrAssignment {
    return this == AcademicEventType.classTest ||
        this == AcademicEventType.assignment ||
        this == AcademicEventType.midterm ||
        this == AcademicEventType.termFinal;
  }
}

@HiveType(typeId: 0)
class AcademicEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String courseCode;

  @HiveField(3)
  final AcademicEventType type;

  @HiveField(4)
  final String room;

  @HiveField(5)
  final String instructor;

  @HiveField(6)
  final int? dayOfWeek; // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun

  @HiveField(7)
  final DateTime? specificDate;

  @HiveField(8)
  final String startTime; // "HH:mm" e.g. "09:00"

  @HiveField(9)
  final String endTime; // "HH:mm" e.g. "10:30"

  @HiveField(10)
  final String syllabusNotes;

  @HiveField(11)
  final bool isCompleted;

  @HiveField(12)
  final bool syncToCalendar;

  @HiveField(13)
  final String? calendarEventId;

  AcademicEvent({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.type,
    required this.room,
    required this.instructor,
    this.dayOfWeek,
    this.specificDate,
    required this.startTime,
    required this.endTime,
    this.syllabusNotes = '',
    this.isCompleted = false,
    this.syncToCalendar = true,
    this.calendarEventId,
  });

  String get timeRange => '$startTime - $endTime';

  AcademicEvent copyWith({
    String? id,
    String? title,
    String? courseCode,
    AcademicEventType? type,
    String? room,
    String? instructor,
    int? dayOfWeek,
    DateTime? specificDate,
    String? startTime,
    String? endTime,
    String? syllabusNotes,
    bool? isCompleted,
    bool? syncToCalendar,
    String? calendarEventId,
  }) {
    return AcademicEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      courseCode: courseCode ?? this.courseCode,
      type: type ?? this.type,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      specificDate: specificDate ?? this.specificDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      syllabusNotes: syllabusNotes ?? this.syllabusNotes,
      isCompleted: isCompleted ?? this.isCompleted,
      syncToCalendar: syncToCalendar ?? this.syncToCalendar,
      calendarEventId: calendarEventId ?? this.calendarEventId,
    );
  }
}

// =========================================================================
// HABIT ITEM MODEL (typeId: 1, typeId: 11)
// =========================================================================
@HiveType(typeId: 11)
enum HabitType {
  @HiveField(0)
  positiveHabit,
  @HiveField(1)
  antiHabit,
}

@HiveType(typeId: 1)
class HabitItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final HabitType type;

  @HiveField(3)
  final String category; // e.g. "Code & Build", "Academics", "Digital Health", "Social Media Lockout"

  @HiveField(4)
  final int streakCount;

  @HiveField(5)
  final List<DateTime> completedDates;

  @HiveField(6)
  final List<int> targetDays; // 1-7 for Mon-Sun (or 0-6 for Sun-Sat)

  @HiveField(7)
  final String shieldRuleDescription;

  HabitItem({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    this.streakCount = 0,
    List<DateTime>? completedDates,
    List<int>? targetDays,
    this.shieldRuleDescription = '',
  })  : completedDates = completedDates ?? [],
        targetDays = targetDays ?? [1, 2, 3, 4, 5, 6, 7];

  bool get isAntiHabit => type == HabitType.antiHabit;

  bool isCompletedOn(DateTime date) {
    return completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  HabitItem copyWith({
    String? id,
    String? title,
    HabitType? type,
    String? category,
    int? streakCount,
    List<DateTime>? completedDates,
    List<int>? targetDays,
    String? shieldRuleDescription,
  }) {
    return HabitItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      streakCount: streakCount ?? this.streakCount,
      completedDates: completedDates ?? this.completedDates,
      targetDays: targetDays ?? this.targetDays,
      shieldRuleDescription:
          shieldRuleDescription ?? this.shieldRuleDescription,
    );
  }
}

// =========================================================================
// TIMELINE BLOCK MODEL (typeId: 2, typeId: 12)
// =========================================================================
@HiveType(typeId: 12)
enum TimelineBlockType {
  @HiveField(0)
  academicClass,
  @HiveField(1)
  routineFocus,
  @HiveField(2)
  antiHabitShield,
  @HiveField(3)
  calendarSync,
}

@HiveType(typeId: 2)
class TimelineBlock extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String startTime;

  @HiveField(3)
  final String endTime;

  @HiveField(4)
  final TimelineBlockType type;

  @HiveField(5)
  final String? referenceId;

  @HiveField(6)
  final String subtitle;

  @HiveField(7)
  final String? location;

  @HiveField(8)
  final bool isCompleted;

  @HiveField(9)
  final int? streakDays;

  @HiveField(10)
  final String? replacementTrigger;

  @HiveField(11)
  final String? badgeText;

  TimelineBlock({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.referenceId,
    this.subtitle = '',
    this.location,
    this.isCompleted = false,
    this.streakDays,
    this.replacementTrigger,
    this.badgeText,
  });

  String get timeRange => '$startTime – $endTime';

  TimelineBlock copyWith({
    String? id,
    String? title,
    String? startTime,
    String? endTime,
    TimelineBlockType? type,
    String? referenceId,
    String? subtitle,
    String? location,
    bool? isCompleted,
    int? streakDays,
    String? replacementTrigger,
    String? badgeText,
  }) {
    return TimelineBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      subtitle: subtitle ?? this.subtitle,
      location: location ?? this.location,
      isCompleted: isCompleted ?? this.isCompleted,
      streakDays: streakDays ?? this.streakDays,
      replacementTrigger: replacementTrigger ?? this.replacementTrigger,
      badgeText: badgeText ?? this.badgeText,
    );
  }
}

// =========================================================================
// SUPPORTING UI & DASHBOARD MODELS
// =========================================================================
@immutable
class HeroClass {
  final String startsIn;
  final String courseCode;
  final String sessionType;
  final String title;
  final String location;
  final String instructor;
  final bool slidesDownloaded;
  final String? assignmentDueText;

  const HeroClass({
    required this.startsIn,
    required this.courseCode,
    required this.sessionType,
    required this.title,
    required this.location,
    required this.instructor,
    this.slidesDownloaded = true,
    this.assignmentDueText,
  });
}

@immutable
class DayCycle {
  final String day;
  final String classCountLabel;
  final int classCount;
  final int dayIndex; // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun

  const DayCycle({
    required this.day,
    required this.classCountLabel,
    required this.classCount,
    required this.dayIndex,
  });
}

@immutable
class AiGapSlot {
  final String id;
  final String gapName;
  final String tag;
  final String recommendation;
  final bool isEnforced;

  const AiGapSlot({
    required this.id,
    required this.gapName,
    required this.tag,
    required this.recommendation,
    this.isEnforced = true,
  });
}

@immutable
class SyncSettings {
  final String accountEmail;
  final String lastSyncTime;
  final bool is2WayLiveSyncActive;
  final bool autoPushRoutine;
  final bool autoBlockDistractions;
  final bool classReminderAlerts;

  const SyncSettings({
    required this.accountEmail,
    required this.lastSyncTime,
    this.is2WayLiveSyncActive = true,
    this.autoPushRoutine = true,
    this.autoBlockDistractions = true,
    this.classReminderAlerts = true,
  });

  SyncSettings copyWith({
    String? accountEmail,
    String? lastSyncTime,
    bool? is2WayLiveSyncActive,
    bool? autoPushRoutine,
    bool? autoBlockDistractions,
    bool? classReminderAlerts,
  }) {
    return SyncSettings(
      accountEmail: accountEmail ?? this.accountEmail,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      is2WayLiveSyncActive: is2WayLiveSyncActive ?? this.is2WayLiveSyncActive,
      autoPushRoutine: autoPushRoutine ?? this.autoPushRoutine,
      autoBlockDistractions: autoBlockDistractions ?? this.autoBlockDistractions,
      classReminderAlerts: classReminderAlerts ?? this.classReminderAlerts,
    );
  }
}
