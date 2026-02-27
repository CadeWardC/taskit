import 'package:json_annotation/json_annotation.dart';

part 'todo_list.g.dart';

@JsonSerializable()
class TodoList {
  final int? id; // Primary Key
  final String title;
  final String? color; // Hex string
  final int? order; // Custom sort order
  @JsonKey(name: 'sort_option')
  final String? sortOption; // 'date', 'priority', 'custom'
  
  // JSON array of section names
  final List<String>? sections;
  
  // 'vertical' or 'horizontal'
  @JsonKey(name: 'section_layout')
  final String? sectionLayout;

  TodoList({
    this.id,
    required this.title,
    this.color,
    this.order,
    this.sortOption,
    this.sections,
    this.sectionLayout,
  });

  factory TodoList.fromJson(Map<String, dynamic> json) => _$TodoListFromJson(json);
  Map<String, dynamic> toJson() => _$TodoListToJson(this);
}
