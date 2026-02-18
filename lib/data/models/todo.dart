import 'package:json_annotation/json_annotation.dart';

part 'todo.g.dart';

@JsonSerializable()
class Todo {
  final int? id;
  final String title;
  final String? detail;
  
  @JsonKey(name: 'is_completed')
  final bool isCompleted;

  @JsonKey(name: 'due_date')
  final DateTime? dueDate;

  @JsonKey(name: 'date_updated')
  final DateTime? dateUpdated;

  // Duration in minutes
  final int? duration;

  // 'high', 'medium', 'low', 'none'
  final String priority;

  @JsonKey(name: 'list_id')
  final int? listId;

  // Recurring: null, 'daily', 'weekly', 'monthly'
  @JsonKey(name: 'recurring_frequency')
  final String? recurringFrequency;

  @JsonKey(name: 'repeat_interval')
  final int repeatInterval;

  @JsonKey(name: 'custom_recurring_days')
  final List<int>? customRecurringDays;

  // Order for custom sorting
  final int? order;

  Todo({
    this.id,
    required this.title,
    this.detail,
    this.isCompleted = false,
    this.dueDate,
    this.dateUpdated,
    this.duration,
    this.priority = 'none',
    this.listId,
    this.recurringFrequency,
    this.repeatInterval = 1,
    this.customRecurringDays,
    this.order,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
  Map<String, dynamic> toJson() => _$TodoToJson(this);

  Todo copyWith({
    int? id,
    String? title,
    String? detail,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? dateUpdated,
    int? duration,
    String? priority,
    int? listId,
    String? recurringFrequency,
    int? repeatInterval,
    List<int>? customRecurringDays,
    int? order,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      duration: duration ?? this.duration,
      priority: priority ?? this.priority,
      listId: listId ?? this.listId,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      customRecurringDays: customRecurringDays ?? this.customRecurringDays,
      order: order ?? this.order,
    );
  }

  /// Check if this is a recurring task
  bool get isRecurring => recurringFrequency != null;
}
