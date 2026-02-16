import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../data/models/todo.dart';
import '../../data/models/todo_list.dart';
import '../../data/repositories/todo_repository.dart';
import 'package:flutter/foundation.dart';

class TodoProvider extends ChangeNotifier {
  final TodoRepository _repository;
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

  TodoProvider(this._repository);

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

      // Sort: Incomplete first, then by ID (newest last usually, or we can sort by ID desc for newest first)
      // The user asked for "completed at the bottom".
      _todos.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1; // Completed items go to the bottom
        }
        // Secondary sort: by ID (assuming higher ID = newer)
        // Or duplicate existing order. Let's sort by ID descending (newest on top)
        return (b.id ?? 0).compareTo(a.id ?? 0);
      });

      debugPrint('Fetched ${_todos.length} todos and ${_lists.length} lists for user');
      
      // Execute deletions in background
      for (final id in todosToDelete) {
        _repository.deleteTodo(id).catchError((e) {
          debugPrint('Failed to auto-delete old completed task $id: $e');
        });
      }

      await _updateWidgetData();
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
      // Re-sort
      _todos.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return (b.id ?? 0).compareTo(a.id ?? 0);
      });
      await _updateWidgetData();
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
        // Re-sort
        _todos.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return (b.id ?? 0).compareTo(a.id ?? 0);
        });
        await _updateWidgetData();
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
        // Re-sort
        _todos.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return (b.id ?? 0).compareTo(a.id ?? 0);
        });
        await _updateWidgetData();
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
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
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
