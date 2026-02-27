// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoList _$TodoListFromJson(Map<String, dynamic> json) => TodoList(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  color: json['color'] as String?,
  order: (json['order'] as num?)?.toInt(),
  sortOption: json['sort_option'] as String?,
  sections: (json['sections'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  sectionLayout: json['section_layout'] as String?,
);

Map<String, dynamic> _$TodoListToJson(TodoList instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'color': instance.color,
  'order': instance.order,
  'sort_option': instance.sortOption,
  'sections': instance.sections,
  'section_layout': instance.sectionLayout,
};
