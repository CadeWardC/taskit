import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_widgets.dart';
import '../widgets/task_dialog.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch todos on startup
    Future.microtask(
      () => Provider.of<TodoProvider>(context, listen: false).fetchTodos(),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Today'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
        ),
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

            // Filter for tasks due today (or overdue?)
            // User said "only include tasks that are due that day".
            // Strict interpretation: due date is today (ignoring time component match).
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

            final todayTasks = provider.todos.where((todo) {
              if (todo.dueDate == null) return false;
              return todo.dueDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
                     todo.dueDate!.isBefore(todayEnd.add(const Duration(seconds: 1)));
            }).toList();

            return RefreshIndicator(
              onRefresh: () => provider.fetchTodos(),
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: const Color(0xFF1E1E1E),
              child: todayTasks.isEmpty
                  ? Center(
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
                            'No tasks for today',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        top: 100,
                        left: 16,
                        right: 16,
                        bottom: 100,
                      ),
                      itemCount: todayTasks.length,
                      itemBuilder: (context, index) {
                        final todo = todayTasks[index];
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
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => TaskDialog(
              initialListId:
                  Provider.of<TodoProvider>(context, listen: false)
                      .selectedListId,
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}


