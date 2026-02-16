// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HabitLog _$HabitLogFromJson(Map<String, dynamic> json) => HabitLog(
  id: (json['id'] as num?)?.toInt(),
  habitId: (json['habit_id'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  completedCount: (json['completed_count'] as num?)?.toInt() ?? 1,
  notes: json['notes'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$HabitLogToJson(HabitLog instance) => <String, dynamic>{
  'id': instance.id,
  'habit_id': instance.habitId,
  'date': instance.date.toIso8601String(),
  'completed_count': instance.completedCount,
  'notes': instance.notes,
  'created_at': instance.createdAt?.toIso8601String(),
};
