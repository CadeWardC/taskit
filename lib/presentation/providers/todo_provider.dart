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
      _todos = results[0] as List<Todo>;
      _lists = results[1] as List<TodoList>;

      debugPrint('Fetched ${_todos.length} todos and ${_lists.length} lists for user');
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
      await _updateWidgetData();
      notifyListeners();
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
