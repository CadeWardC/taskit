import '../models/todo.dart';
import '../models/todo_list.dart';
import '../services/directus_service.dart';

class TodoRepository {
  final DirectusService _service;

  TodoRepository(this._service);

  Future<List<Todo>> getTodos() => _service.getTodos();
  
  Future<Todo> addTodo({
    required String title,
    String? detail,
    DateTime? dueDate,
    int? duration,
    String priority = 'none',
    int? listId,
    String? recurringFrequency,
    int repeatInterval = 1,
    List<int>? customRecurringDays,
  }) => _service.createTodo(
        title: title,
        detail: detail,
        dueDate: dueDate,
        duration: duration,
        priority: priority,
        listId: listId,
        recurringFrequency: recurringFrequency,
        repeatInterval: repeatInterval,
        customRecurringDays: customRecurringDays,
      );

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
  }) => _service.updateTodo(
        id,
        isCompleted: isCompleted,
        title: title,
        detail: detail,
        dueDate: dueDate,
        duration: duration,
        priority: priority,
        listId: listId,
        recurringFrequency: recurringFrequency,
        repeatInterval: repeatInterval,
        customRecurringDays: customRecurringDays,
      );
      
  Future<void> deleteTodo(int id) => _service.deleteTodo(id);

  // Lists
  Future<List<TodoList>> getLists() => _service.getLists();
  Future<TodoList> addList(String title, String color) => _service.createList(title, color);
  Future<void> deleteList(int id) => _service.deleteList(id);
}
