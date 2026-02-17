import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../data/models/todo.dart';
import '../../data/models/todo_list.dart';
import '../../data/repositories/todo_repository.dart';
import '../../data/services/local_cache_service.dart';
import 'package:flutter/foundation.dart';

class TodoProvider extends ChangeNotifier {
  final TodoRepository _repository;
  final LocalCacheService _cache;
  List<Todo> _todos = [];
  List<TodoList> _lists = [];
  bool _isLoading = false;
  String? _error;

  List<Todo> get todos => _todos;
  List<TodoList> get lists => _lists;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Track the currently selected list globally
  int? _selectedListId;
  int? get selectedListId => _selectedListId;

  void setSelectedListId(int? id) {
    _selectedListId = id;
    notifyListeners();
  }

  TodoProvider(this._repository, this._cache);

  /// Get recurring tasks
  List<Todo> get recurringTasks => _todos.where((t) => t.isRecurring).toList();

  /// Get tasks by recurring type
  List<Todo> getTasksByRecurring(String? recurring) {
    if (recurring == null) {
      return _todos.where((t) => !t.isRecurring).toList();
    }
    return _todos.where((t) => t.recurringFrequency == recurring).toList();
  }

  Future<void> fetchTodos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Load cached data first for instant UI
    if (_todos.isEmpty) {
      final cachedTodos = await _cache.getCachedTodos();
      final cachedLists = await _cache.getCachedLists();
      if (cachedTodos != null) _todos = cachedTodos;
      if (cachedLists != null) _lists = cachedLists;
      if (_todos.isNotEmpty || _lists.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        _isLoading = true;
      }
    }

    try {
      final results = await Future.wait([
        _repository.getTodos(),
        _repository.getLists(),
      ]);
      var fetchedTodos = results[0] as List<Todo>;
      _lists = results[1] as List<TodoList>;

      // Auto-delete completed tasks older than 24 hours
      final now = DateTime.now();
      final todosToDelete = <int>[];
      
      _todos = [];
      for (final todo in fetchedTodos) {
        if (todo.isCompleted && todo.dateUpdated != null) {
          final difference = now.difference(todo.dateUpdated!);
          if (difference.inHours >= 24) {
            todosToDelete.add(todo.id!);
            continue; // Skip adding to _todos list
          }
        }
        _todos.add(todo);
      }

      _sortTodos();

      debugPrint('Fetched ${_todos.length} todos and ${_lists.length} lists for user');
      
      // Execute deletions in background
      for (final id in todosToDelete) {
        _repository.deleteTodo(id).catchError((e) {
          debugPrint('Failed to auto-delete old completed task $id: $e');
        });
      }

      await _updateWidgetData();
      await _saveCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTodo({
    required String title,
    String? detail,
    DateTime? dueDate,
    int? duration,
    String priority = 'none',
    int? listId,
    String? recurringFrequency,
    int repeatInterval = 1,
    List<int>? customRecurringDays,
    String? recurring, // Deprecated
  }) async {
    try {
      final newTodo = await _repository.addTodo(
        title: title,
        detail: detail,
        dueDate: dueDate,
        duration: duration,
        priority: priority,
        listId: listId,
        recurringFrequency: recurringFrequency ?? recurring,
        repeatInterval: repeatInterval,
        customRecurringDays: customRecurringDays,
      );
      _todos.add(newTodo);
      _sortTodos();
      await _updateWidgetData();
      await _saveCache();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTodo(
    int id, {
    String? title,
    String? detail,
    DateTime? dueDate,
    int? duration,
    String? priority,
    int? listId,
    String? recurringFrequency,
    int? repeatInterval,
    List<int>? customRecurringDays,
    bool? isCompleted,
  }) async {
    try {
      final updatedTodo = await _repository.updateTodo(
        id,
        title: title,
        detail: detail,
        dueDate: dueDate,
        duration: duration,
        priority: priority,
        listId: listId,
        recurringFrequency: recurringFrequency,
        repeatInterval: repeatInterval,
        customRecurringDays: customRecurringDays,
        isCompleted: isCompleted,
      );
      
      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        _todos[index] = updatedTodo;
        _sortTodos();
        await _updateWidgetData();
        await _saveCache();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addList(String title, String color) async {
    try {
      final newList = await _repository.addList(title, color);
      _lists.add(newList);
      await _saveCache();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteList(int id) async {
    try {
      await _repository.deleteList(id);
      _lists.removeWhere((l) => l.id == id);
      // If we deleted the currently selected list, reset selection
      if (_selectedListId == id) {
        _selectedListId = null;
      }
      await _saveCache();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleTodo(int id) async {
    try {
      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        final todo = _todos[index];
        final updatedTodo = await _repository.updateTodo(
          id,
          isCompleted: !todo.isCompleted,
        );
        _todos[index] = updatedTodo;
        _sortTodos();
        await _updateWidgetData();
        await _saveCache();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _repository.deleteTodo(id);
      _todos.removeWhere((t) => t.id == id);
      await _updateWidgetData();
      await _saveCache();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _sortTodos() {
    _todos.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return (b.id ?? 0).compareTo(a.id ?? 0);
    });
  }

  Future<void> _saveCache() async {
    await _cache.cacheTodos(_todos);
    await _cache.cacheLists(_lists);
  }

  Future<void> _updateWidgetData() async {
    try {
      if (kIsWeb) return; // HomeWidget not supported on web
      
      final todoData = jsonEncode(_todos.map((e) => e.toJson()).toList());
      await HomeWidget.saveWidgetData<String>('todo_data', todoData);
      await HomeWidget.updateWidget(
        iOSName: 'TodoWidget',
        androidName: 'TodoWidgetReceiver',
      );
    } catch (e) {
      debugPrint("Error updating widget: $e");
    }
  }
}
