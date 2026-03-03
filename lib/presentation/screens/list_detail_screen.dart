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
  late TodoProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<TodoProvider>();
    // Set the selected list ID so provider knows which sort preference to use
    Future.microtask(() {
      _provider.setSelectedListId(widget.list.id);
      if (widget.list.id == null && widget.list.title.toLowerCase() == 'inbox') {
        _provider.setViewingInbox(true);
      }
    });
  }

  @override
  void dispose() {
    if (widget.list.id == null && widget.list.title.toLowerCase() == 'inbox') {
      _provider.setViewingInbox(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        final currentList = provider.lists.firstWhere(
          (l) => l.id == widget.list.id,
          orElse: () => widget.list,
        );

        // Parse color if available
        Color? listColor;
        if (currentList.color != null) {
          try {
            listColor = Color(int.parse(currentList.color!.replaceFirst('#', '0xFF')));
          } catch (_) {}
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Expanded(child: Text(currentList.title)),
                IconButton(
                  icon: const Icon(Icons.post_add),
                  tooltip: 'New Section',
                  onPressed: () => _showAddSectionDialog(context, provider, currentList),
                ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'View Options',
                  onPressed: () => _showViewOptionsSheet(context, provider, currentList, listColor),
                ),
              ],
            ),
            backgroundColor: listColor ?? Colors.black,
            elevation: 0,
          ),
          body: currentList.sectionLayout == 'horizontal' && (currentList.sections?.isNotEmpty ?? false)
              ? DefaultTabController(
                  length: (currentList.sections?.length ?? 0) + 1, // +1 for "Ungrouped"
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        indicatorColor: listColor ?? Theme.of(context).colorScheme.primary,
                        labelColor: listColor ?? Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.white54,
                        tabs: [
                          ...currentList.sections!.map((s) => Tab(text: s)),
                          const Tab(text: 'Ungrouped'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ...currentList.sections!.map((sectionName) => _buildSectionList(context, currentList, sectionName, listColor)),
                            _buildSectionList(context, currentList, null, listColor), // Ungrouped
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : _buildVerticalLayout(context, provider, currentList, listColor),
        );
      },
    );
  }

  void _showAddSectionDialog(BuildContext context, TodoProvider provider, TodoList currentList) {
    final TextEditingController sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('New Section', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: sectionController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter section name',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final newSection = sectionController.text.trim();
              if (newSection.isNotEmpty) {
                final activeSections = currentList.sections ?? <String>[];
                if (!activeSections.contains(newSection)) {
                  provider.updateList(
                    currentList.id!,
                    sections: [...activeSections, newSection],
                  );
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showViewOptionsSheet(BuildContext context, TodoProvider provider, TodoList currentList, Color? listColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Layout Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Layout',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionTile(
                          context: context,
                          icon: Icons.view_stream,
                          label: 'Vertical',
                          isSelected: currentList.sectionLayout != 'horizontal',
                          activeColor: listColor,
                          onTap: () {
                            provider.updateList(currentList.id!, sectionLayout: null);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildOptionTile(
                          context: context,
                          icon: Icons.view_carousel,
                          label: 'Horizontal',
                          isSelected: currentList.sectionLayout == 'horizontal',
                          activeColor: listColor,
                          onTap: () {
                            provider.updateList(currentList.id!, sectionLayout: 'horizontal');
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Sort Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort Tasks',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionTile(
                          context: context,
                          icon: Icons.calendar_today,
                          label: 'Date',
                          isSelected: provider.currentSort == SortOption.date,
                          activeColor: listColor,
                          onTap: () {
                            provider.setSort(SortOption.date);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildOptionTile(
                          context: context,
                          icon: Icons.flag_outlined,
                          label: 'Priority',
                          isSelected: provider.currentSort == SortOption.priority,
                          activeColor: listColor,
                          onTap: () {
                            provider.setSort(SortOption.priority);
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 8),
                         _buildOptionTile(
                          context: context,
                          icon: Icons.drag_handle,
                          label: 'Custom',
                          isSelected: provider.currentSort == SortOption.custom,
                          activeColor: listColor,
                          onTap: () {
                            provider.setSort(SortOption.custom);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? (activeColor ?? Theme.of(context).colorScheme.primary) : Colors.white70;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context, TodoProvider provider, TodoList currentList, Color? listColor) {
    return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF121212), Color(0xFF2C2C2C)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Builder(
          builder: (context) {
            final allTasks = provider.todos.where((t) => t.listId == currentList.id).toList();
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
                  : currentList.sections != null && currentList.sections!.isNotEmpty
                      ? _buildVerticalSections(context, provider, currentList, activeTasks, completedTasks, listColor)
                      : provider.currentSort == SortOption.custom
                          ? _buildReorderableList(context, provider, currentList, activeTasks, completedTasks, listColor)
                          : _buildStandardList(context, provider, currentList, activeTasks, completedTasks, listColor),
            );
          },
        ),
          ),
        ),
      );
  }

  Widget _buildVerticalSections(BuildContext context, TodoProvider provider, TodoList currentList, List<dynamic> activeTasks, List<dynamic> completedTasks, Color? listColor) {
    return ListView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      children: [
        for (final sectionName in currentList.sections!)
          _buildVerticalSectionGroup(context, provider, currentList, activeTasks, sectionName, listColor),
        
        _buildVerticalSectionGroup(context, provider, currentList, activeTasks, null, listColor), // Ungrouped
        
        if (completedTasks.isNotEmpty) _buildCompletedFooter(context, provider, currentList, completedTasks, listColor),
      ],
    );
  }

  Widget _buildVerticalSectionGroup(BuildContext context, TodoProvider provider, TodoList currentList, List<dynamic> allActiveTasks, String? sectionName, Color? listColor) {
    final tasksInSection = allActiveTasks.where((t) => t.section == sectionName).toList();
    if (tasksInSection.isEmpty && sectionName == null) return const SizedBox.shrink(); // Don't show empty Ungrouped

    bool isDeleting = false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: StatefulBuilder(
            builder: (context, setState) {
              return GestureDetector(
                onTap: () {
                  if (sectionName != null) {
                    setState(() => isDeleting = !isDeleting);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      sectionName ?? 'Ungrouped',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: listColor ?? Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: isDeleting
                          ? Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E1E1E),
                                      title: const Text('Delete Section', style: TextStyle(color: Colors.white)),
                                      content: Text('Delete "$sectionName"? Tasks will be ungrouped.', style: const TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            provider.deleteSection(currentList.id!, sectionName!);
                                            Navigator.pop(context);
                                          },
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }
          ),
        ),
        if (tasksInSection.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'No tasks',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontStyle: FontStyle.italic),
            ),
          )
        else
          ...tasksInSection.map((todo) => Padding(
            key: Key('task_${todo.id}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => TaskDialog(todo: todo, availableSections: currentList.sections),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: TaskCard(
                todo: todo,
                activeColor: listColor,
                onToggle: () => provider.toggleTodo(todo.id!),
                onDelete: () => provider.deleteTodo(todo.id!),
                onPriorityTap: () => provider.cycleTodoPriority(todo.id!),
              ),
            ),
          )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionList(BuildContext context, TodoList currentList, String? sectionName, Color? listColor) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF121212), Color(0xFF2C2C2C)],
        ),
      ),
      child: Builder(
        builder: (context) {
          final provider = context.watch<TodoProvider>();
          final allTasks = provider.todos.where((t) => t.listId == currentList.id && t.section == sectionName).toList();
          final activeTasks = allTasks.where((t) => !t.isCompleted).toList();
          final completedTasks = allTasks.where((t) => t.isCompleted).toList();

          return RefreshIndicator(
            onRefresh: () => provider.fetchTodos(),
            color: listColor ?? Theme.of(context).colorScheme.primary,
            backgroundColor: const Color(0xFF1E1E1E),
            child: allTasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks in this section',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                    children: [
                      ...activeTasks.map((todo) => Padding(
                        key: Key('task_${todo.id}'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => TaskDialog(
                                todo: todo,
                                availableSections: currentList.sections,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: TaskCard(
                            todo: todo,
                            activeColor: listColor,
                            onToggle: () => provider.toggleTodo(todo.id!),
                            onDelete: () => provider.deleteTodo(todo.id!),
                            onPriorityTap: () => provider.cycleTodoPriority(todo.id!),
                          ),
                        ),
                      )),
                      if (completedTasks.isNotEmpty) _buildCompletedFooter(context, provider, currentList, completedTasks, listColor),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildReorderableList(BuildContext context, TodoProvider provider, TodoList currentList, List<dynamic> activeTasks, List<dynamic> completedTasks, Color? listColor) {
    return ReorderableListView(
                          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex >= activeTasks.length) return; // Can't move footer
                            if (newIndex > activeTasks.length) newIndex = activeTasks.length; // Can't move past active
                            provider.reorderListTodos(currentList.id, oldIndex, newIndex);
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
                                          builder: (context) => TaskDialog(todo: activeTasks[index], availableSections: currentList.sections),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: TaskCard(
                                        todo: activeTasks[index],
                                        activeColor: listColor,
                                        onToggle: () => provider.toggleTodo(activeTasks[index].id!),
                                        onDelete: () => provider.deleteTodo(activeTasks[index].id!),
                                        onPriorityTap: () => provider.cycleTodoPriority(activeTasks[index].id!),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Footer as a single item
                            if (completedTasks.isNotEmpty) _buildCompletedFooter(context, provider, currentList, completedTasks, listColor),
                          ],
    );
  }

  Widget _buildStandardList(BuildContext context, TodoProvider provider, TodoList currentList, List<dynamic> activeTasks, List<dynamic> completedTasks, Color? listColor) {
    return ListView(
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
                builder: (context) => TaskDialog(todo: todo, availableSections: currentList.sections),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: TaskCard(
              todo: todo,
              activeColor: listColor,
              onToggle: () => provider.toggleTodo(todo.id!),
              onDelete: () => provider.deleteTodo(todo.id!),
              onPriorityTap: () => provider.cycleTodoPriority(todo.id!),
            ),
          ),
        )),

        // Completed Tasks Dropdown
        if (completedTasks.isNotEmpty) _buildCompletedFooter(context, provider, currentList, completedTasks, listColor),
      ],
    );
  }

  Widget _buildCompletedFooter(BuildContext context, TodoProvider provider, TodoList currentList, List<dynamic> completedTasks, Color? listColor) {
    return Padding(
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
                  builder: (context) => TaskDialog(todo: todo, availableSections: currentList.sections),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: TaskCard(
                todo: todo,
                activeColor: listColor,
                onToggle: () => provider.toggleTodo(todo.id!),
                onDelete: () => provider.deleteTodo(todo.id!),
                onPriorityTap: () => provider.cycleTodoPriority(todo.id!),
              ),
            ),
          )).toList(),
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
