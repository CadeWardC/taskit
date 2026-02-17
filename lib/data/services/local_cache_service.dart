import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

/// Persists app data locally using SharedPreferences so the UI can
/// display cached content immediately while a network refresh runs.
class LocalCacheService {
  static const _keyTodos = 'cache_todos';
  static const _keyLists = 'cache_lists';
  static const _keyHabits = 'cache_habits';
  static const _keyHabitLogsPrefix = 'cache_habit_logs_';

  // ── Todos ──────────────────────────────────────────────────────

  Future<void> cacheTodos(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(todos.map((t) => t.toJson()).toList());
    await prefs.setString(_keyTodos, json);
  }

  Future<List<Todo>?> getCachedTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTodos);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // ── Lists ──────────────────────────────────────────────────────

  Future<void> cacheLists(List<TodoList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(lists.map((l) => l.toJson()).toList());
    await prefs.setString(_keyLists, json);
  }

  Future<List<TodoList>?> getCachedLists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLists);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => TodoList.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // ── Habits ─────────────────────────────────────────────────────

  Future<void> cacheHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_keyHabits, json);
  }

  Future<List<Habit>?> getCachedHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyHabits);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // ── Habit Logs ─────────────────────────────────────────────────

  Future<void> cacheHabitLogs(int habitId, List<HabitLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(logs.map((l) => l.toJson()).toList());
    await prefs.setString('$_keyHabitLogsPrefix$habitId', json);
  }

  Future<List<HabitLog>?> getCachedHabitLogs(int habitId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyHabitLogsPrefix$habitId');
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => HabitLog.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
}
