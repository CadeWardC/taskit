// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoList _$TodoListFromJson(Map<String, dynamic> json) => TodoList(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  color: json['color'] as String?,
);

Map<String, dynamic> _$TodoListToJson(TodoList instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'color': instance.color,
};
