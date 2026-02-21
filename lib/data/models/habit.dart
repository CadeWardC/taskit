import 'package:json_annotation/json_annotation.dart';

part 'habit.g.dart';

@JsonSerializable()
class Habit {
  final int? id;
  final String title;
  final String? detail;
  final String? icon; // Emoji or icon name
  final String? color; // Hex color

  @JsonKey(name: 'target_count')
  final int targetCount; // Goal per period (e.g., 8 glasses)

  @JsonKey(name: 'current_progress')
  final int currentProgress; // Today's count

  // 'daily', 'weekly', 'monthly'
  final String frequency;

  @JsonKey(name: 'repeat_interval')
  final int repeatInterval; // e.g., Every 2 weeks

  // 'daily', 'period'
  // daily: targetCount is per day
  // period: targetCount is per frequency period (e.g., 3 times per week)
  @JsonKey(name: 'goal_type')
  final String goalType;

  // For custom: [1,3,5] = Mon/Wed/Fri (1=Mon, 7=Sun)
  @JsonKey(name: 'custom_days')
  final List<int>? customDays;

  @JsonKey(name: 'current_streak')
  final int currentStreak;

  @JsonKey(name: 'best_streak')
  final int bestStreak;

  @JsonKey(name: 'last_completed')
  final DateTime? lastCompleted;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'unit')
  final String unit;

  @JsonKey(name: 'date_updated')
  final DateTime? dateUpdated;

  Habit({
    this.id,
    required this.title,
    this.detail,
    this.icon,
    this.color,
    this.targetCount = 1,
    this.unit = 'times',
    this.currentProgress = 0,
    this.frequency = 'daily',
    this.repeatInterval = 1,
    this.goalType = 'daily',
    this.customDays,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompleted,
    this.createdAt,
    this.dateUpdated,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as int?,
      title: json['title'] as String? ?? 'Untitled',
      detail: json['detail'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      targetCount: int.tryParse(json['target_count'].toString()) ?? 1,
      currentProgress: int.tryParse(json['current_progress'].toString()) ?? 0,
      frequency: json['frequency'] as String? ?? 'daily',
      repeatInterval: int.tryParse(json['repeat_interval'].toString()) ?? 1,
      goalType: json['goal_type'] as String? ?? 'daily',
      customDays: (json['custom_days'] as List<dynamic>?)
          ?.map((e) => int.tryParse(e.toString()) ?? 0)
          .toList(),
      currentStreak: int.tryParse(json['current_streak'].toString()) ?? 0,
      bestStreak: int.tryParse(json['best_streak'].toString()) ?? 0,
      lastCompleted: json['last_completed'] != null
          ? DateTime.tryParse(json['last_completed'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      unit: json['unit'] as String? ?? 'times',
      dateUpdated: json['date_updated'] != null
          ? DateTime.tryParse(json['date_updated'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => _$HabitToJson(this);

  Habit copyWith({
    int? id,
    String? title,
    String? detail,
    String? icon,
    String? color,
    int? targetCount,
    String? unit,
    int? currentProgress,
    String? frequency,
    int? repeatInterval,
    String? goalType,
    List<int>? customDays,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastCompleted,
    DateTime? createdAt,
    DateTime? dateUpdated,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      targetCount: targetCount ?? this.targetCount,
      currentProgress: currentProgress ?? this.currentProgress,
      frequency: frequency ?? this.frequency,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      goalType: goalType ?? this.goalType,
      customDays: customDays ?? this.customDays,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      createdAt: createdAt ?? this.createdAt,
      dateUpdated: dateUpdated ?? this.dateUpdated,
      unit: unit ?? this.unit,
    );
  }

  /// Check if habit is completed for today/period
  bool get isCompleted {
    if (goalType == 'daily') {
      return currentProgress >= targetCount;
    } else {
      // Period goal logic handled in provider usually, but here for consistency
      return currentProgress >= targetCount;
    }
  }

  bool get isCompletedToday => isCompleted;

  /// Progress percentage (0.0 - 1.0)
  double get progressPercent => (currentProgress / targetCount).clamp(0.0, 1.0);
}
