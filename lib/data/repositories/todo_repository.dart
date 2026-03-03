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
    int? order,
    String? section,
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
        order: order,
        section: section,
      );

  Future<Todo> updateTodo(int id, {
    bool? isCompleted,
    String? title,
    String? detail,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? duration,
    String? priority,
    int? listId,
    String? recurringFrequency,
    int? repeatInterval,
    List<int>? customRecurringDays,
    int? order,
    String? section,
  }) => _service.updateTodo(
        id,
        isCompleted: isCompleted,
        title: title,
        detail: detail,
        dueDate: dueDate,
        clearDueDate: clearDueDate,
        duration: duration,
        priority: priority,
        listId: listId,
        recurringFrequency: recurringFrequency,
        repeatInterval: repeatInterval,
        customRecurringDays: customRecurringDays,
        order: order,
        section: section,
      );
      
  Future<void> deleteTodo(int id) => _service.deleteTodo(id);

  // Lists
  Future<List<TodoList>> getLists() => _service.getLists();
  
  Future<TodoList> addList(String title, String color, {int? order, String sortOption = 'custom'}) => 
      _service.createList(title, color, order: order, sortOption: sortOption);

  Future<TodoList> updateList(int id, {String? title, String? color, int? order, String? sortOption, List<String>? sections, String? sectionLayout}) => 
    _service.updateList(id, title: title, color: color, order: order, sortOption: sortOption, sections: sections, sectionLayout: sectionLayout);
  Future<void> deleteList(int id) => _service.deleteList(id);
}
