import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_widgets.dart';
import '../../data/models/todo.dart';
import '../../data/models/todo_list.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  List<Todo> _getTasksForDate(List<Todo> todos, DateTime date) {
    return todos.where((todo) {
      if (todo.dueDate == null) return false;
      return todo.dueDate!.year == date.year &&
          todo.dueDate!.month == date.month &&
          todo.dueDate!.day == date.day;
    }).toList();
  }

  bool _hasTasksOnDate(List<Todo> todos, DateTime date) {
    return _getTasksForDate(todos, date).isNotEmpty;
  }

  /// Returns up to 3 unique list colors for tasks due on this date.
  List<Color> _getListColorsForDate(List<Todo> todos, List<TodoList> lists, DateTime date) {
    final tasks = _getTasksForDate(todos, date);
    final seen = <int?>{};
    final colors = <Color>[];

    for (final task in tasks) {
      if (seen.contains(task.listId)) continue;
      seen.add(task.listId);

      if (task.listId != null) {
        final list = lists.cast<TodoList?>().firstWhere(
          (l) => l?.id == task.listId,
          orElse: () => null,
        );
        if (list != null && list.color != null) {
          colors.add(_hexToColor(list.color!));
        } else {
          colors.add(Colors.grey);
        }
      } else {
        colors.add(Colors.grey);
      }

      if (colors.length >= 3) break;
    }

    return colors;
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        final tasksForSelected = _getTasksForDate(
          provider.todos,
          _selectedDate,
        );

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchTodos(),
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: const Color(0xFF1E1E1E),
            child: CustomScrollView(
              slivers: [
                // Header & Navigation
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Calendar',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _focusedMonth = DateTime(
                                            _focusedMonth.year,
                                            _focusedMonth.month - 1,
                                          );
                                        });
                                      },
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    Text(
                                      DateFormat('MMMM yyyy').format(_focusedMonth),
                                      style: Theme.of(context).textTheme.titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _focusedMonth = DateTime(
                                            _focusedMonth.year,
                                            _focusedMonth.month + 1,
                                          );
                                        });
                                      },
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Weekday headers
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children:
                                      ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                                          .map(
                                            (day) => Expanded(
                                              child: Center(
                                                child: Text(
                                                  day,
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(
                                                      alpha: 0.5,
                                                    ),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Calendar grid
                              _buildCalendarGrid(provider.todos, provider.lists),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Selected date header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          DateFormat('EEEE, MMM d').format(_selectedDate),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Task List
                if (tasksForSelected.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks for this day',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final todo = tasksForSelected[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: TaskCard(
                          todo: todo,
                          onToggle: () => provider.toggleTodo(todo.id!),
                          onDelete: () => provider.deleteTodo(todo.id!),
                        ),
                      );
                    }, childCount: tasksForSelected.length),
                  ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid(List<Todo> todos, List<TodoList> lists) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startPadding = firstDay.weekday % 7; // Sunday = 0

    final days = <Widget>[];

    // Empty cells for padding
    for (int i = 0; i < startPadding; i++) {
      days.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isToday =
          date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      final isSelected =
          date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final dotColors = _getListColorsForDate(todos, lists, date);

      days.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : isToday
                  ? Colors.white.withValues(alpha: 0.1)
                  : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (dotColors.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dotColors.map((c) => Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 2, left: 1, right: 1),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      )).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1,
        children: days,
      ),
    );
  }
}
