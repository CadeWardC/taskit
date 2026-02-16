// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Todo _$TodoFromJson(Map<String, dynamic> json) => Todo(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  detail: json['detail'] as String?,
  isCompleted: json['is_completed'] as bool? ?? false,
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
  duration: (json['duration'] as num?)?.toInt(),
  priority: json['priority'] as String? ?? 'none',
  listId: (json['list_id'] as num?)?.toInt(),
  recurringFrequency: json['recurring_frequency'] as String?,
  repeatInterval: (json['repeat_interval'] as num?)?.toInt() ?? 1,
  customRecurringDays: (json['custom_recurring_days'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$TodoToJson(Todo instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'detail': instance.detail,
  'is_completed': instance.isCompleted,
  'due_date': instance.dueDate?.toIso8601String(),
  'duration': instance.duration,
  'priority': instance.priority,
  'list_id': instance.listId,
  'recurring_frequency': instance.recurringFrequency,
  'repeat_interval': instance.repeatInterval,
  'custom_recurring_days': instance.customRecurringDays,
};
