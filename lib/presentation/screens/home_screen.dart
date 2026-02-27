import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_widgets.dart';
import '../widgets/task_dialog.dart';
import '../../data/services/local_cache_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cache = LocalCacheService();
  
  // Filter modes
  static const _filters = ['Today', 'Tomorrow', 'Week'];
  String _currentFilter = 'Today';
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Restore cached filter
      final saved = await _cache.getInboxFilter();
      if (mounted && _filters.contains(saved)) {
        setState(() {
          _currentFilter = saved;
          _isLoaded = true;
        });
      } else if (mounted) {
        setState(() => _isLoaded = true);
      }
      Provider.of<TodoProvider>(context, listen: false).fetchTodos();
    });
  }

  void _cycleFilter() {
    final idx = _filters.indexOf(_currentFilter);
    final next = _filters[(idx + 1) % _filters.length];
    setState(() => _currentFilter = next);
    _cache.setInboxFilter(next);
  }

  List<dynamic> _filterTasks(List<dynamic> todos) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (_currentFilter) {
      case 'Tomorrow':
        final tomorrowStart = todayStart.add(const Duration(days: 1));
        final tomorrowEnd = tomorrowStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        return todos.where((todo) {
          if (todo.dueDate == null) return false;
          return todo.dueDate!.isAfter(tomorrowStart.subtract(const Duration(seconds: 1))) &&
                 todo.dueDate!.isBefore(tomorrowEnd.add(const Duration(seconds: 1)));
        }).toList();
      case 'Week':
        final weekEnd = todayStart.add(const Duration(days: 7, hours: 23, minutes: 59, seconds: 59));
        return todos.where((todo) {
          if (todo.dueDate == null) return false;
          return todo.dueDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
                 todo.dueDate!.isBefore(weekEnd);
        }).toList();
      default: // Today
        final todayEnd = todayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        return todos.where((todo) {
          if (todo.dueDate == null) return false;
          return todo.dueDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
                 todo.dueDate!.isBefore(todayEnd.add(const Duration(seconds: 1)));
        }).toList();
    }
  }

  String get _emptyMessage {
    switch (_currentFilter) {
      case 'Tomorrow': return 'No tasks for tomorrow';
      case 'Week': return 'No tasks this week';
      default: return 'No tasks for today';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
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

            final filteredTasks = _filterTasks(provider.todos);

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header — tappable filter title
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _cycleFilter,
                          child: Row(
                            children: [
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                alignment: Alignment.centerLeft,
                                clipBehavior: Clip.none,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  layoutBuilder: (currentChild, previousChildren) {
                                    return Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        ...previousChildren,
                                        if (currentChild != null) currentChild,
                                      ],
                                    );
                                  },
                                  transitionBuilder: (child, animation) {
                                    final offsetAnimation = Tween<Offset>(
                                      begin: const Offset(0.0, 0.5),
                                      end: Offset.zero,
                                    ).animate(animation);
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _currentFilter,
                                    key: ValueKey(_currentFilter),
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.swap_horiz,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Inbox',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => provider.fetchTodos(),
                      color: Theme.of(context).colorScheme.primary,
                      backgroundColor: const Color(0xFF1E1E1E),
                      child: filteredTasks.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.wb_sunny_outlined,
                                          size: 64,
                                          color: Colors.white.withValues(alpha: 0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _emptyMessage,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                                      onPriorityTap: () => provider.cycleTodoPriority(todo.id!),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
