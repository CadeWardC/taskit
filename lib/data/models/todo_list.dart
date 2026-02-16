import 'package:json_annotation/json_annotation.dart';

part 'todo_list.g.dart';

@JsonSerializable()
class TodoList {
  final int? id; // Primary Key
  final String title;
  final String? color; // Hex string

  TodoList({
    this.id,
    required this.title,
    this.color,
  });

  factory TodoList.fromJson(Map<String, dynamic> json) => _$TodoListFromJson(json);
  Map<String, dynamic> toJson() => _$TodoListToJson(this);
}
