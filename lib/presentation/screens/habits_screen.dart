import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_dialog.dart';
import '../widgets/reports_view.dart';
import '../../data/models/habit.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  int _selectedTab = 0; // 0 for Habits, 1 for Reports
  bool _showAll = false; // Toggle for "Today" vs "All/Manage" view

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<HabitProvider>(context, listen: false).fetchHabits());
  }

  bool _isScheduledForToday(Habit habit) {
    final now = DateTime.now();
    
    // 1. Daily
    if (habit.frequency == 'daily') {
      if (habit.repeatInterval == 1) return true;
      // If interval > 1, check against creation date
      // If createdAt is null, assume true to be safe, or false? defaulting to true.
      if (habit.createdAt == null) return true;
      
      final daysDiff = now.difference(habit.createdAt!).inDays;
      return daysDiff % habit.repeatInterval == 0;
    }
    
    // 2. Weekly
    if (habit.frequency == 'weekly') {
      // If no custom days, assume everyday or maybe default to none? 
      // Usually "weekly" implies some days selected. If none, maybe it means same day of creation?
      // Let's assume if customDays is empty/null, it shows up if interval logic matches week?
      // Re-reading RecurringPicker: defaults to empty customDays when switching.
      // If customDays is empty, maybe show every day? Or show warning?
      // Let's strictly check customDays if present.
      if (habit.customDays != null && habit.customDays!.isNotEmpty) {
        return habit.customDays!.contains(now.weekday);
      }
      return true; // Fallback
    }
    
    // 3. Monthly
    if (habit.frequency == 'monthly') {
      if (habit.customDays != null && habit.customDays!.isNotEmpty) {
        return habit.customDays!.contains(now.day);
      }
      // Fallback: if no specific dates, maybe matched by creation day?
      if (habit.createdAt != null) {
        return now.day == habit.createdAt!.day;
      }
      return false; // Safest fallback
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.habits.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.habits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.fetchHabits(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Tab Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildTabTitle(
                      context,
                      title: _selectedTab == 0 && _showAll ? 'All' : 'Habits',
                      index: 0,
                      isSelected: _selectedTab == 0,
                    ),
                    const Spacer(), 
                    _buildTabTitle(
                      context,
                      title: 'Reports',
                      index: 1,
                      isSelected: _selectedTab == 1,
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: _selectedTab == 0
                    ? _buildHabitsList(context, provider)
                    : const ReportsView(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabTitle(BuildContext context, {required String title, required int index, required bool isSelected}) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () {
        if (index == 0 && _selectedTab == 0) {
          // Toggle Show All if tapping already selected "Habits" tab
          setState(() => _showAll = !_showAll);
        } else {
          setState(() {
            _selectedTab = index;
            // Reset to Today view when switching tabs? Or keep state?
            // If switching TO habits, maybe reset `_showAll` to false? User didn't specify.
            if (index == 0) _showAll = false; 
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(bottom: BorderSide(color: primaryColor, width: 2))
              : null,
        ),
        child: AnimatedSwitcher(
           duration: const Duration(milliseconds: 200),
           child: Text(
            title,
            key: ValueKey(title),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? primaryColor : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitsList(BuildContext context, HabitProvider provider) {
    // Filter habits
    final visibleHabits = _showAll 
        ? provider.habits 
        : provider.habits.where(_isScheduledForToday).toList();

    if (visibleHabits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _showAll ? 'No habits yet' : 'No habits for today',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create a habit',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => provider.fetchHabits(),
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 100),
        itemCount: visibleHabits.length,
        itemBuilder: (context, index) {
          final habit = visibleHabits[index];

          final card = HabitCard(
            habit: habit,
            isManagementMode: _showAll,
            onToggle: () => provider.toggleHabit(habit.id!),
            onDelete: () => provider.deleteHabit(habit.id!),
            onProgressChange: (newProgress) {
              provider.updateProgress(habit.id!, newProgress);
            },
          );

          if (_showAll) {
            // All/Management View: Swipe to Delete
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Dismissible(
                key: ValueKey(habit.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                   provider.deleteHabit(habit.id!);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => HabitDialog(habit: habit),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: card,
                ),
              ),
            ).animate().fadeIn().slideX(begin: 0.2, end: 0);
          } else {
            // Today View: Swipe to Fill (Internal to HabitCard) + Tap to Complete
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                   if (habit.isCompleted) {
                     provider.updateProgress(habit.id!, 0);
                   } else {
                     provider.completeHabit(habit.id!);
                   }
                },
                borderRadius: BorderRadius.circular(16),
                child: card,
              ),
            ).animate().fadeIn().slideX(begin: 0.2, end: 0);
          }
        },
      ),
    );
  }
}
