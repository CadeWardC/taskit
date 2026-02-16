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
        title: const Text('TaskIt'),
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

            return ListView.builder(
              padding: const EdgeInsets.only(
                top: 100,
                left: 16,
                right: 16,
                bottom: 100,
              ),
              itemCount: provider.todos.length,
              itemBuilder: (context, index) {
                final todo = provider.todos[index];
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


