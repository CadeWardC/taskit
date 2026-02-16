import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/directus_service.dart';

class HabitRepository {
  final DirectusService _service;

  HabitRepository(this._service);

  Future<List<Habit>> getHabits() => _service.getHabits();

  Future<Habit> addHabit({
    required String title,
    String? detail,
    String? icon,
    String? color,
    int targetCount = 1,
    String frequency = 'daily',
    int repeatInterval = 1,
    String goalType = 'daily',
    List<int>? customDays,
  }) => _service.createHabit(
        title: title,
        detail: detail,
        icon: icon,
        color: color,
        targetCount: targetCount,
        frequency: frequency,
        repeatInterval: repeatInterval,
        goalType: goalType,
        customDays: customDays,
      );

  Future<Habit> updateHabit(int id, {
    String? title,
    String? detail,
    String? icon,
    String? color,
    int? targetCount,
    int? currentProgress,
    String? frequency,
    int? repeatInterval,
    String? goalType,
    List<int>? customDays,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastCompleted,
    bool clearLastCompleted = false,
  }) => _service.updateHabit(
        id,
        title: title,
        detail: detail,
        icon: icon,
        color: color,
        targetCount: targetCount,
        currentProgress: currentProgress,
        frequency: frequency,
        repeatInterval: repeatInterval,
        goalType: goalType,
        customDays: customDays,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        lastCompleted: lastCompleted,
        clearLastCompleted: clearLastCompleted,
      );

  Future<void> deleteHabit(int id) => _service.deleteHabit(id);

  // Logs
  Future<List<HabitLog>> getHabitLogs(int habitId) => _service.getHabitLogs(habitId);
  
  Future<HabitLog> logCompletion({
    required int habitId,
    required DateTime date,
    int completedCount = 1,
    String? notes,
  }) => _service.createHabitLog(
        habitId: habitId,
        date: date,
        completedCount: completedCount,
        notes: notes,
      );
}
