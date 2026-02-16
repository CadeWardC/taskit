import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_widgets.dart';
import '../widgets/task_dialog.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {

  void _showAddListDialog(BuildContext context) {
    final titleController = TextEditingController();
    Color selectedColor = const Color(0xFFBB86FC);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('New List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'List Name',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              ColorPicker(
                pickerColor: selectedColor,
                onColorChanged: (color) => setDialogState(() => selectedColor = color),
                enableAlpha: false,
                displayThumbColor: true,
                paletteType: PaletteType.hueWheel,
                labelTypes: const [],
                hexInputBar: false,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  context.read<TodoProvider>().addList(
                    titleController.text,
                    '#${selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.todos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${provider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                ElevatedButton(
                  onPressed: () => provider.fetchTodos(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Filter tasks by list if selected
        final allTasks = provider.todos;
        final filteredTasks = provider.selectedListId == null
            ? allTasks
            : allTasks.where((t) => t.listId == provider.selectedListId).toList();

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Lists',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showAddListDialog(context),
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add List',
                    ),
                  ],
                ),
              ),
              // List chips
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildListChip(
                      context,
                      label: 'All Tasks',
                      isSelected: provider.selectedListId == null,
                      onTap: () => provider.setSelectedListId(null),
                    ),
                    ...provider.lists.map(
                      (list) => _buildListChip(
                        context,
                        label: list.title,
                        color: list.color != null
                            ? Color(
                                int.parse(
                                  list.color!.replaceFirst('#', '0xFF'),
                                ),
                              )
                            : null,
                        isSelected: provider.selectedListId == list.id,
                        onTap: () => provider.setSelectedListId(list.id),
                        onLongPress: () {
                          if (list.id != null) {
                            _showDeleteListDialog(context, list.id!, list.title);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Tasks list
              Expanded(
                child: filteredTasks.isEmpty
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
                              'No tasks yet',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ).copyWith(bottom: 100),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final todo = filteredTasks[index];
                          return Padding(
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
                                onToggle: () => provider.toggleTodo(todo.id!),
                                onDelete: () => provider.deleteTodo(todo.id!),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListChip(
    BuildContext context, {
    required String label,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onTap(),
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          selectedColor: (color ?? Theme.of(context).colorScheme.primary)
              .withValues(alpha: 0.3),
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected
                ? (color ?? Theme.of(context).colorScheme.primary)
                : Colors.transparent,
            width: 2,
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          avatar: color != null
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                )
              : null,
        ),
      ),
    );
  }

  void _showDeleteListDialog(BuildContext context, int listId, String listName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "$listName"?\nAll tasks in this list will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TodoProvider>().deleteList(listId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
