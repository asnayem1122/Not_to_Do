part of 'routine_models.dart';

// **************************************************************************
// TypeAdapterGenerator for AcademicEventType (typeId: 10)
// **************************************************************************
class AcademicEventTypeAdapter extends TypeAdapter<AcademicEventType> {
  @override
  final int typeId = 10;

  @override
  AcademicEventType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AcademicEventType.lecture;
      case 1:
        return AcademicEventType.sessionalLab;
      case 2:
        return AcademicEventType.tutorial;
      case 3:
        return AcademicEventType.classTest;
      case 4:
        return AcademicEventType.assignment;
      case 5:
        return AcademicEventType.midterm;
      case 6:
        return AcademicEventType.termFinal;
      default:
        return AcademicEventType.lecture;
    }
  }

  @override
  void write(BinaryWriter writer, AcademicEventType obj) {
    switch (obj) {
      case AcademicEventType.lecture:
        writer.writeByte(0);
        break;
      case AcademicEventType.sessionalLab:
        writer.writeByte(1);
        break;
      case AcademicEventType.tutorial:
        writer.writeByte(2);
        break;
      case AcademicEventType.classTest:
        writer.writeByte(3);
        break;
      case AcademicEventType.assignment:
        writer.writeByte(4);
        break;
      case AcademicEventType.midterm:
        writer.writeByte(5);
        break;
      case AcademicEventType.termFinal:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicEventTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// TypeAdapterGenerator for AcademicEvent (typeId: 0)
// **************************************************************************
class AcademicEventAdapter extends TypeAdapter<AcademicEvent> {
  @override
  final int typeId = 0;

  @override
  AcademicEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AcademicEvent(
      id: fields[0] as String,
      title: fields[1] as String,
      courseCode: fields[2] as String,
      type: fields[3] as AcademicEventType,
      room: fields[4] as String,
      instructor: fields[5] as String,
      dayOfWeek: fields[6] as int?,
      specificDate: fields[7] as DateTime?,
      startTime: fields[8] as String,
      endTime: fields[9] as String,
      syllabusNotes: fields[10] as String? ?? '',
      isCompleted: fields[11] as bool? ?? false,
      syncToCalendar: fields[12] as bool? ?? true,
      calendarEventId: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AcademicEvent obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.courseCode)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.room)
      ..writeByte(5)
      ..write(obj.instructor)
      ..writeByte(6)
      ..write(obj.dayOfWeek)
      ..writeByte(7)
      ..write(obj.specificDate)
      ..writeByte(8)
      ..write(obj.startTime)
      ..writeByte(9)
      ..write(obj.endTime)
      ..writeByte(10)
      ..write(obj.syllabusNotes)
      ..writeByte(11)
      ..write(obj.isCompleted)
      ..writeByte(12)
      ..write(obj.syncToCalendar)
      ..writeByte(13)
      ..write(obj.calendarEventId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// TypeAdapterGenerator for HabitType (typeId: 11)
// **************************************************************************
class HabitTypeAdapter extends TypeAdapter<HabitType> {
  @override
  final int typeId = 11;

  @override
  HabitType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitType.positiveHabit;
      case 1:
        return HabitType.antiHabit;
      default:
        return HabitType.positiveHabit;
    }
  }

  @override
  void write(BinaryWriter writer, HabitType obj) {
    switch (obj) {
      case HabitType.positiveHabit:
        writer.writeByte(0);
        break;
      case HabitType.antiHabit:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// TypeAdapterGenerator for HabitItem (typeId: 1)
// **************************************************************************
class HabitItemAdapter extends TypeAdapter<HabitItem> {
  @override
  final int typeId = 1;

  @override
  HabitItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitItem(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as HabitType,
      category: fields[3] as String,
      streakCount: fields[4] as int? ?? 0,
      completedDates: (fields[5] as List?)?.cast<DateTime>(),
      targetDays: (fields[6] as List?)?.cast<int>(),
      shieldRuleDescription: fields[7] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, HabitItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.streakCount)
      ..writeByte(5)
      ..write(obj.completedDates)
      ..writeByte(6)
      ..write(obj.targetDays)
      ..writeByte(7)
      ..write(obj.shieldRuleDescription);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// TypeAdapterGenerator for TimelineBlockType (typeId: 12)
// **************************************************************************
class TimelineBlockTypeAdapter extends TypeAdapter<TimelineBlockType> {
  @override
  final int typeId = 12;

  @override
  TimelineBlockType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TimelineBlockType.academicClass;
      case 1:
        return TimelineBlockType.routineFocus;
      case 2:
        return TimelineBlockType.antiHabitShield;
      case 3:
        return TimelineBlockType.calendarSync;
      default:
        return TimelineBlockType.routineFocus;
    }
  }

  @override
  void write(BinaryWriter writer, TimelineBlockType obj) {
    switch (obj) {
      case TimelineBlockType.academicClass:
        writer.writeByte(0);
        break;
      case TimelineBlockType.routineFocus:
        writer.writeByte(1);
        break;
      case TimelineBlockType.antiHabitShield:
        writer.writeByte(2);
        break;
      case TimelineBlockType.calendarSync:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineBlockTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// TypeAdapterGenerator for TimelineBlock (typeId: 2)
// **************************************************************************
class TimelineBlockAdapter extends TypeAdapter<TimelineBlock> {
  @override
  final int typeId = 2;

  @override
  TimelineBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimelineBlock(
      id: fields[0] as String,
      title: fields[1] as String,
      startTime: fields[2] as String,
      endTime: fields[3] as String,
      type: fields[4] as TimelineBlockType,
      referenceId: fields[5] as String?,
      subtitle: fields[6] as String? ?? '',
      location: fields[7] as String?,
      isCompleted: fields[8] as bool? ?? false,
      streakDays: fields[9] as int?,
      replacementTrigger: fields[10] as String?,
      badgeText: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TimelineBlock obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.referenceId)
      ..writeByte(6)
      ..write(obj.subtitle)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.streakDays)
      ..writeByte(10)
      ..write(obj.replacementTrigger)
      ..writeByte(11)
      ..write(obj.badgeText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
