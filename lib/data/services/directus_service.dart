import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class DirectusService {
  final Dio _dio;
  final String baseUrl = 'https://api.opcw032522.uk';
  
  String? _currentUserId;

  void setUserId(String id) {
    _currentUserId = id;
  }

  String? get currentUserId => _currentUserId;

  DirectusService() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
  }

  // ============================================================
  // USERS
  // ============================================================

  /// Check if a user exists in Directus
  Future<bool> userExists(String userId) async {
    try {
      final response = await _dio.get('/items/users/$userId');
      return response.data['data'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Create a user in Directus (for first-time login)
  Future<void> createUser(String userId) async {
    try {
      await _dio.post('/items/users', data: {
        'id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Ensure user exists, create if not
  Future<void> ensureUserExists(String userId) async {
    final exists = await userExists(userId);
    if (!exists) {
      await createUser(userId);
    }
  }

  // ============================================================
  // TODOS
  // ============================================================

  Future<List<Todo>> getTodos() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return [];
    try {
      debugPrint('Fetching todos for user: $_currentUserId');
      final response = await _dio.get('/items/todos', queryParameters: {
        'filter[user_id][_eq]': _currentUserId,
      });
      final data = response.data['data'] as List;
      debugPrint('Directus response: ${data.length} todos found');
      return data.map((e) => Todo.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load todos: $e');
    }
  }

  Future<Todo> createTodo({
    required String title,
    String? detail,
    DateTime? dueDate,
    int? duration,
    String priority = 'none',
    int? listId,

    String? recurringFrequency,
    int repeatInterval = 1,
    List<int>? customRecurringDays,
    int? order,
  }) async {
    try {
      final response = await _dio.post('/items/todos', data: {
        'title': title,
        'detail': detail,
        'is_completed': false,
        'due_date': dueDate?.toIso8601String(),
        'duration': duration,
        'priority': priority,
        'list_id': listId,
        'recurring_frequency': recurringFrequency,
        'repeat_interval': repeatInterval,
        'custom_recurring_days': customRecurringDays,
        'order': order,
        'user_id': _currentUserId,
      });
      return Todo.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception('Failed to create todo: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to create todo: $e');
    }
  }

  Future<Todo> updateTodo(int id, {
    bool? isCompleted,
    String? title,
    String? detail,
    DateTime? dueDate,
    int? duration,
    String? priority,
    int? listId,
    String? recurringFrequency,
    int? repeatInterval,
    List<int>? customRecurringDays,
    int? order,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (isCompleted != null) data['is_completed'] = isCompleted;
      if (title != null) data['title'] = title;
      if (detail != null) data['detail'] = detail;
      if (dueDate != null) data['due_date'] = dueDate.toIso8601String();
      if (duration != null) data['duration'] = duration;
      if (priority != null) data['priority'] = priority;
      if (listId != null) data['list_id'] = listId;
      if (recurringFrequency != null) data['recurring_frequency'] = recurringFrequency;
      if (repeatInterval != null) data['repeat_interval'] = repeatInterval;
      if (customRecurringDays != null) data['custom_recurring_days'] = customRecurringDays;
      if (order != null) data['order'] = order;

      final response = await _dio.patch('/items/todos/$id', data: data);
      return Todo.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update todo: $e');
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _dio.delete('/items/todos/$id');
    } catch (e) {
      throw Exception('Failed to delete todo: $e');
    }
  }

  // ============================================================
  // LISTS
  // ============================================================
  
  Future<List<TodoList>> getLists() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return [];
    try {
      debugPrint('Fetching lists for user: $_currentUserId');
      final response = await _dio.get('/items/lists', queryParameters: {
        'filter[user_id][_eq]': _currentUserId,
      });
      final data = response.data['data'] as List;
      debugPrint('Directus response: ${data.length} lists found');
      return data.map((e) => TodoList.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<TodoList> createList(String title, String color, {int? order, String sortOption = 'custom'}) async {
    try {
      final response = await _dio.post('/items/lists', data: {
        'title': title,
        'color': color,
        'order': order,
        'sort_option': sortOption,
        'user_id': _currentUserId,
      });
      return TodoList.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception('Failed to create list: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to create list: $e');
    }
  }

  Future<void> deleteList(int id) async {
    try {
      await _dio.delete('/items/lists/$id');
    } catch (e) {
      throw Exception('Failed to delete list: $e');
    }
  }

  Future<TodoList> updateList(int id, {String? title, String? color, int? order, String? sortOption}) async {
    try {
      final Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (color != null) data['color'] = color;
      if (order != null) data['order'] = order;
      if (sortOption != null) data['sort_option'] = sortOption;

      final response = await _dio.patch('/items/lists/$id', data: data);
      return TodoList.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update list: $e');
    }
  }

  // ============================================================
  // HABITS
  // ============================================================

  Future<List<Habit>> getHabits() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return [];
    try {
      final response = await _dio.get('/items/habits', queryParameters: {
        'filter[user_id][_eq]': _currentUserId,
      });
      final data = response.data['data'] as List;
      return data.map((e) => Habit.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load habits: $e');
    }
  }

  Future<Habit> createHabit({
    required String title,
    String? detail,
    String? icon,
    String? color,
    int targetCount = 1,
    String unit = 'times',
    String frequency = 'daily',
    int repeatInterval = 1,
    String goalType = 'daily',
    List<int>? customDays,
  }) async {
    try {
      final response = await _dio.post('/items/habits', data: {
        'title': title,
        'detail': detail,
        'icon': icon,
        'color': color,
        'target_count': targetCount,
        'unit': unit,
        'current_progress': 0,
        'frequency': frequency,
        'repeat_interval': repeatInterval,
        'goal_type': goalType,
        'custom_days': customDays,
        'current_streak': 0,
        'best_streak': 0,
        'user_id': _currentUserId,
      });
      return Habit.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception('Failed to create habit: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to create habit: $e');
    }
  }

  Future<Habit> updateHabit(int id, {
    String? title,
    String? detail,
    String? icon,
    String? color,
    int? targetCount,
    String? unit,
    int? currentProgress,
    String? frequency,
    List<int>? customDays,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastCompleted,
    bool clearLastCompleted = false,
    int? repeatInterval,
    String? goalType,
    DateTime? dateUpdated,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (detail != null) data['detail'] = detail;
      if (icon != null) data['icon'] = icon;
      if (color != null) data['color'] = color;
      if (targetCount != null) data['target_count'] = targetCount;
      if (unit != null) data['unit'] = unit;
      if (currentProgress != null) data['current_progress'] = currentProgress;
      if (frequency != null) data['frequency'] = frequency;
      if (repeatInterval != null) data['repeat_interval'] = repeatInterval;
      if (goalType != null) data['goal_type'] = goalType;
      if (customDays != null) data['custom_days'] = customDays;
      if (currentStreak != null) data['current_streak'] = currentStreak;
      if (bestStreak != null) data['best_streak'] = bestStreak;
      if (lastCompleted != null) {
        data['last_completed'] = lastCompleted.toIso8601String();
      } else if (clearLastCompleted) {
        data['last_completed'] = null;
      }
      // Note: We do NOT send 'date_updated' as it is a system field managed by Directus.
      // We only read it from the response.

      final response = await _dio.patch(
        '/items/habits/$id',
        data: data,
        queryParameters: {'fields': '*'},
      );
      return Habit.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update habit: $e');
    }
  }

  Future<void> deleteHabit(int id) async {
    try {
      await _dio.delete('/items/habits/$id');
    } catch (e) {
      throw Exception('Failed to delete habit: $e');
    }
  }

  // ============================================================
  // HABIT LOGS
  // ============================================================

  Future<List<HabitLog>> getHabitLogs(int habitId) async {
    try {
      final response = await _dio.get('/items/habit_logs', queryParameters: {
        'filter[habit_id][_eq]': habitId,
        'sort': '-date',
      });
      final data = response.data['data'] as List;
      return data.map((e) => HabitLog.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load habit logs: $e');
    }
  }

  Future<HabitLog> createHabitLog({
    required int habitId,
    required DateTime date,
    int completedCount = 1,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/items/habit_logs', data: {
        'habit_id': habitId,
        'date': date.toIso8601String(),
        'completed_count': completedCount,
        'notes': notes,
      });
      return HabitLog.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create habit log: $e');
    }
  }

  Future<void> deleteHabitLog(int id) async {
    try {
      await _dio.delete('/items/habit_logs/$id');
    } catch (e) {
      throw Exception('Failed to delete habit log: $e');
    }
  }

  Future<void> deleteHabitLogsForDate(int habitId, DateTime date) async {
    try {
      final logs = await getHabitLogs(habitId);
      final isUtc = date.isUtc;
      debugPrint('Deleting logs for habit $habitId on date $date (UTC: $isUtc). Found ${logs.length} total logs.');
      
      final logsToDelete = logs.where((l) {
        final isSame = isUtc 
            ? _isSameDayUtc(l.date, date) 
            : _isSameDay(l.date, date);
            
        debugPrint('Checking Log ${l.id}: Date=${l.date} vs Target=${date} -> Match: $isSame');
        return isSame;
      }).toList();
      
      debugPrint('Found ${logsToDelete.length} logs to delete for date $date.');
      
      if (logsToDelete.isEmpty) return;

      final ids = logsToDelete.map((l) => l.id).where((id) => id != null).toList();
      if (ids.isNotEmpty) {
        // Directus delete mostly confusing with list of IDs in body? 
        // Docs say DELETE /items/:collection/:id or DELETE /items/:collection with body [ids]
        // Dio delete with data often requires explicit options.
        // Assuming current implementation works:
        // await _dio.delete('/items/habit_logs', data: ids);
        // But some APIs require data to be passed in 'data' field of Options or as query.
        // Directus: DELETE /items/articles/[1,2,3] or DELETE /items/articles with payload [1,2,3]
        
        // Let's stick to simple individual deletes if batch fails, 
        // but existing code used batch delete logic. 
        // Re-using existing logic but safe-guarding:
         try {
           await _dio.delete('/items/habit_logs', data: ids);
         } catch (e) {
           debugPrint('Batch delete failed, trying individual: $e');
           for (final id in ids) {
             await deleteHabitLog(id!);
           }
         }

        debugPrint('Deleted logs with IDs: $ids');
      }
    } catch (e) {
      debugPrint('Error deleting habit logs for date: $e');
    }
  }

  Future<void> deleteAllHabitLogs(int habitId) async {
    try {
      final logs = await getHabitLogs(habitId);
      final ids = logs.map((l) => l.id).where((id) => id != null).toList();
      
      if (ids.isNotEmpty) {
        await _dio.delete('/items/habit_logs', data: ids);
      }
    } catch (e) {
      debugPrint('Error deleting all habit logs: $e');
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year && localA.month == localB.month && localA.day == localB.day;
  }
  
  bool _isSameDayUtc(DateTime a, DateTime b) {
    final utcA = a.toUtc();
    final utcB = b.toUtc();
    return utcA.year == utcB.year && utcA.month == utcB.month && utcA.day == utcB.day;
  }
}
