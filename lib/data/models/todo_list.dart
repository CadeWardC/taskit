import 'package:json_annotation/json_annotation.dart';

part 'todo_list.g.dart';

@JsonSerializable()
class TodoList {
  final int? id; // Primary Key
  final String title;
  final String? color; // Hex string
  final int? order; // Custom sort order
  final String? sortOption; // 'date', 'priority', 'custom'

  TodoList({
    this.id,
    required this.title,
    this.color,
    this.order,
    this.sortOption,
  });

  factory TodoList.fromJson(Map<String, dynamic> json) => _$TodoListFromJson(json);
  Map<String, dynamic> toJson() => _$TodoListToJson(this);
}
