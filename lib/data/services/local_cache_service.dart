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
  static const _keyLastDailyReset = 'cache_last_daily_reset';

  // ── Daily Reset Flag ───────────────────────────────────────────

  Future<void> setLastDailyReset(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastDailyReset, date.toIso8601String());
  }

  Future<DateTime?> getLastDailyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastDailyReset);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

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

  // ── Last Open List ──────────────────────────────────────────────

  static const _keyLastOpenListId = 'cache_last_open_list_id';
  static int? _memLastOpenListId;
  static bool _lastOpenListLoaded = false;

  /// Call once at app startup to warm the in-memory mirror.
  Future<void> preloadLastOpenListId() async {
    if (_lastOpenListLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _memLastOpenListId = prefs.getInt(_keyLastOpenListId);
    _lastOpenListLoaded = true;
  }

  /// Synchronous getter — returns instantly from memory.
  int? getLastOpenListIdSync() => _memLastOpenListId;

  Future<void> setLastOpenListId(int? listId) async {
    _memLastOpenListId = listId;
    final prefs = await SharedPreferences.getInstance();
    if (listId != null) {
      await prefs.setInt(_keyLastOpenListId, listId);
    } else {
      await prefs.remove(_keyLastOpenListId);
    }
  }

  Future<int?> getLastOpenListId() async {
    if (_lastOpenListLoaded) return _memLastOpenListId;
    await preloadLastOpenListId();
    return _memLastOpenListId;
  }

  // ── Inbox Filter Mode ─────────────────────────────────────────

  static const _keyInboxFilter = 'cache_inbox_filter';

  Future<void> setInboxFilter(String filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInboxFilter, filter);
  }

  Future<String> getInboxFilter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyInboxFilter) ?? 'Today';
  }
}
