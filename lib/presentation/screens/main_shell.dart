import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/responsive_scaffold.dart';
import 'home_screen.dart';
import 'lists_screen.dart';
import 'calendar_screen.dart';
import 'habits_screen.dart';
import 'settings_screen.dart';
import '../widgets/task_dialog.dart';
import '../widgets/habit_dialog.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  DateTime _lastCheck = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fetch todos and check for habit reset on startup
    Future.microtask(() {
       Provider.of<TodoProvider>(context, listen: false).fetchTodos();
       _checkDailyReset();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDailyReset();
    }
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.day != _lastCheck.day || now.month != _lastCheck.month || now.year != _lastCheck.year) {
      // It's a new day
      Provider.of<HabitProvider>(context, listen: false).resetDailyProgress();
      _lastCheck = now;
    }
  }

  final List<NavigationDestination> _navItems = const [
    NavigationDestination(
      icon: Icon(Icons.wb_sunny_outlined),
      selectedIcon: Icon(Icons.wb_sunny),
      label: 'Today',
    ),
    NavigationDestination(
      icon: Icon(Icons.list_alt_outlined),
      selectedIcon: Icon(Icons.list_alt),
      label: 'Lists',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Calendar',
    ),
    NavigationDestination(
      icon: Icon(Icons.repeat_outlined),
      selectedIcon: Icon(Icons.repeat),
      label: 'Habits',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      navItems: _navItems,
      destinations: [
        HomeScreen(), // Today
        ListsScreen(),
        CalendarScreen(),
        HabitsScreen(),
        SettingsScreen(),
      ],
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    // Settings (index 4) has no FAB
    if (_selectedIndex == 4) return null;
    
    // Habits (index 3) - show "New Habit" button
    if (_selectedIndex == 3) {
      return FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const HabitDialog(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      );
    }
    
    // Today, Lists, Calendar - show "New Task" button
    return FloatingActionButton.extended(
      onPressed: () {
        final selectedListId =
            Provider.of<TodoProvider>(context, listen: false).selectedListId;
        showDialog(
          context: context,
          builder: (context) => TaskDialog(initialListId: selectedListId),
        );
      },
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label: const Text('New Task'),
    );
  }



}
