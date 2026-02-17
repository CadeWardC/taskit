import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'data/services/directus_service.dart';
import 'data/services/local_cache_service.dart';
import 'data/repositories/todo_repository.dart';
import 'data/repositories/habit_repository.dart';
import 'presentation/providers/todo_provider.dart';
import 'presentation/providers/habit_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/main_shell.dart';
import 'presentation/screens/login_screen.dart';

void main() {
  runApp(const TaskItApp());
}

class TaskItApp extends StatelessWidget {
  const TaskItApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize dependencies
    final directusService = DirectusService();
    final localCacheService = LocalCacheService();
    final todoRepository = TodoRepository(directusService);
    final habitRepository = HabitRepository(directusService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(directusService),
        ),
        ChangeNotifierProvider(
          create: (_) => TodoProvider(todoRepository, localCacheService),
        ),
        ChangeNotifierProvider(
          create: (_) => HabitProvider(habitRepository, localCacheService),
        ),
      ],
      child: MaterialApp(
        title: 'TaskIt',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (auth.isAuthenticated) {
              return const MainShell();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

