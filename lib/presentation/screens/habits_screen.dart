import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_dialog.dart';
import '../widgets/reports_view.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  int _selectedTab = 0; // 0 for Habits, 1 for Reports

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<HabitProvider>(context, listen: false).fetchHabits());
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
                      title: 'Habits',
                      index: 0,
                      isSelected: _selectedTab == 0,
                    ),
                    const Spacer(), // Pushes Reports to right as requested? "reports title aligned on the right"
                    // Wait, user said "habits title is perfect there should be a reports title aligned on the right"
                    // Does this mean right side of SCREEN or just to the right of Habits?
                    // "whichever one is selected is highlighted iwth the accent color"
                    // I'll put them in a Row with a Spacer between them to align Reports to the far right, 
                    // OR I can just align them left/center. 
                    // "reports title aligned on the right" implies far right.
                    
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
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(bottom: BorderSide(color: primaryColor, width: 2))
              : null,
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? primaryColor : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitsList(BuildContext context, HabitProvider provider) {
    if (provider.habits.isEmpty) {
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
              'No habits yet',
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
        itemCount: provider.habits.length,
        itemBuilder: (context, index) {
          final habit = provider.habits[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      HabitDialog(habit: habit),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: HabitCard(
                habit: habit,
                onToggle: () => provider.toggleHabit(habit.id!),
                onDelete: () => provider.deleteHabit(habit.id!),
              ),
            ),
          );
        },
      ),
    );
  }
}
