// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Habit _$HabitFromJson(Map<String, dynamic> json) => Habit(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  detail: json['detail'] as String?,
  icon: json['icon'] as String?,
  color: json['color'] as String?,
  targetCount: (json['target_count'] as num?)?.toInt() ?? 1,
  currentProgress: (json['current_progress'] as num?)?.toInt() ?? 0,
  frequency: json['frequency'] as String? ?? 'daily',
  repeatInterval: (json['repeat_interval'] as num?)?.toInt() ?? 1,
  goalType: json['goal_type'] as String? ?? 'daily',
  customDays: (json['custom_days'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
  lastCompleted: json['last_completed'] == null
      ? null
      : DateTime.parse(json['last_completed'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$HabitToJson(Habit instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'detail': instance.detail,
  'icon': instance.icon,
  'color': instance.color,
  'target_count': instance.targetCount,
  'current_progress': instance.currentProgress,
  'frequency': instance.frequency,
  'repeat_interval': instance.repeatInterval,
  'goal_type': instance.goalType,
  'custom_days': instance.customDays,
  'current_streak': instance.currentStreak,
  'best_streak': instance.bestStreak,
  'last_completed': instance.lastCompleted?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
};
