import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_widgets.dart';
import '../widgets/task_dialog.dart';
import '../../data/models/todo_list.dart';

class ListDetailScreen extends StatefulWidget {
  final TodoList list;

  const ListDetailScreen({super.key, required this.list});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Set the selected list ID so provider knows which sort preference to use
    Future.microtask(() {
      context.read<TodoProvider>().setSelectedListId(widget.list.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Parse color if available
    Color? listColor;
    if (widget.list.color != null) {
      try {
        listColor = Color(int.parse(widget.list.color!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(widget.list.title)),
            PopupMenuButton<SortOption>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort by',
              onSelected: (option) => context.read<TodoProvider>().setSort(option),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: SortOption.date,
                  child: Row(
                     children: [Icon(Icons.calendar_today, size: 18), SizedBox(width: 8), Text('Date')],
                  ),
                ),
                const PopupMenuItem(
                  value: SortOption.priority,
                   child: Row(
                     children: [Icon(Icons.flag_outlined, size: 18), SizedBox(width: 8), Text('Priority')],
                  ),
                ),
                const PopupMenuItem(
                  value: SortOption.custom,
                   child: Row(
                     children: [Icon(Icons.drag_handle, size: 18), SizedBox(width: 8), Text('Custom')],
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: listColor ?? Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF121212), Color(0xFF2C2C2C)],
          ),
        ),
        child: Consumer<TodoProvider>(
          builder: (context, provider, child) {
            final allTasks = provider.todos.where((t) => t.listId == widget.list.id).toList();
            final activeTasks = allTasks.where((t) => !t.isCompleted).toList();
            final completedTasks = allTasks.where((t) => t.isCompleted).toList();

            if (provider.isLoading && allTasks.isEmpty) {
               return const Center(child: CircularProgressIndicator());
            }
            
            return RefreshIndicator(
              onRefresh: () => provider.fetchTodos(),
              color: listColor ?? Theme.of(context).colorScheme.primary,
              backgroundColor: const Color(0xFF1E1E1E),
              child: allTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks in this list',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : provider.currentSort == SortOption.custom
                      ? ReorderableListView(
                          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex >= activeTasks.length) return; // Can't move footer
                            if (newIndex > activeTasks.length) newIndex = activeTasks.length; // Can't move past active
                            provider.reorderListTodos(widget.list.id, oldIndex, newIndex);
                          },
                          children: [
                            for (var index = 0; index < activeTasks.length; index++)
                              ReorderableDelayedDragStartListener(
                                key: Key('task_${activeTasks[index].id}'),
                                index: index,
                                child: Dismissible(
                                  key: Key('dismiss_task_${activeTasks[index].id}'),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    provider.deleteTodo(activeTasks[index].id!);
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => TaskDialog(todo: activeTasks[index]),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: TaskCard(
                                        todo: activeTasks[index],
                                        activeColor: listColor,
                                        onToggle: () => provider.toggleTodo(activeTasks[index].id!),
                                        onDelete: () => provider.deleteTodo(activeTasks[index].id!),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Footer as a single item
                            if (completedTasks.isNotEmpty)
                              Padding(
                                key: const Key('completed_section'),
                                padding: const EdgeInsets.only(top: 24),
                                child: Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    title: const Text(
                                      'Completed Tasks',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    iconColor: Colors.white70,
                                    collapsedIconColor: Colors.white70,
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_sweep, color: Colors.white70),
                                      tooltip: 'Delete All Completed',
                                      onPressed: () {
                                        _showDeleteCompletedDialog(context, provider, completedTasks);
                                      },
                                    ),
                                    children: completedTasks.map((todo) => Padding(
                                      key: Key('task_completed_${todo.id}'),
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => TaskDialog(todo: todo),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: TaskCard(
                                          todo: todo,
                                          activeColor: listColor,
                                          onToggle: () => provider.toggleTodo(todo.id!),
                                          onDelete: () => provider.deleteTodo(todo.id!),
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                          children: [
                            // Active Tasks
                            ...activeTasks.map((todo) => Padding(
                              key: Key('task_${todo.id}'),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => TaskDialog(todo: todo),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: TaskCard(
                                  todo: todo,
                                  activeColor: listColor,
                                  onToggle: () => provider.toggleTodo(todo.id!),
                                  onDelete: () => provider.deleteTodo(todo.id!),
                                ),
                              ),
                            )),

                            // Completed Tasks Dropdown
                            if (completedTasks.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  title: const Text(
                                    'Completed Tasks',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  iconColor: Colors.white70,
                                  collapsedIconColor: Colors.white70,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_sweep, color: Colors.white70),
                                    tooltip: 'Delete All Completed',
                                    onPressed: () {
                                      _showDeleteCompletedDialog(context, provider, completedTasks);
                                    },
                                  ),
                                  children: completedTasks.map((todo) => Padding(
                                    key: Key('task_completed_${todo.id}'),
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => TaskDialog(todo: todo),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: TaskCard(
                                        todo: todo,
                                        activeColor: listColor,
                                        onToggle: () => provider.toggleTodo(todo.id!),
                                        onDelete: () => provider.deleteTodo(todo.id!),
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
            );
          },
        ),
      ),

    );
  }

  void _showDeleteCompletedDialog(BuildContext context, TodoProvider provider, List<dynamic> tasks) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Completed Tasks'),
        content: const Text('Are you sure you want to delete all completed tasks in this list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              for (final task in tasks) {
                provider.deleteTodo(task.id);
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }


}
