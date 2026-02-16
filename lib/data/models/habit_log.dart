import 'package:json_annotation/json_annotation.dart';

part 'habit_log.g.dart';

/// Tracks individual habit completions for history and analytics
@JsonSerializable()
class HabitLog {
  final int? id;

  @JsonKey(name: 'habit_id')
  final int habitId;

  final DateTime date;

  @JsonKey(name: 'completed_count')
  final int completedCount;

  final String? notes;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  HabitLog({
    this.id,
    required this.habitId,
    required this.date,
    this.completedCount = 1,
    this.notes,
    this.createdAt,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) => _$HabitLogFromJson(json);
  Map<String, dynamic> toJson() => _$HabitLogToJson(this);
}
