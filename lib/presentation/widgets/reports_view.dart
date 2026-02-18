import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/habit_provider.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_log.dart';
import '../../core/theme.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  Map<int, List<HabitLog>> _logsPerHabit = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final provider = Provider.of<HabitProvider>(context, listen: false);
    
    // First pass: Load from cache
    final Map<int, List<HabitLog>> cachedLogs = {};
    for (final habit in provider.habits) {
      if (habit.id != null) {
        final logs = await provider.getCachedHabitLogs(habit.id!);
        if (logs != null) cachedLogs[habit.id!] = logs;
      }
    }
    
    if (mounted && cachedLogs.isNotEmpty) {
      setState(() {
        _logsPerHabit = cachedLogs;
        _loading = false;
      });
    }

    // Second pass: Load from network
    final Map<int, List<HabitLog>> freshLogs = {};
    for (final habit in provider.habits) {
      if (habit.id != null) {
        try {
          freshLogs[habit.id!] = await provider.getHabitHistory(habit.id!);
        } catch (_) {
          freshLogs[habit.id!] = _logsPerHabit[habit.id!] ?? [];
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _logsPerHabit = freshLogs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        if (_loading && _logsPerHabit.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = provider.habits;

        if (habits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded, size: 64,
                    color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No habits yet',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Create habits to see your reports here',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadLogs,
          child: ListView(
            padding: const EdgeInsets.all(16).copyWith(bottom: 100),
            children: [
              // Summary Cards
              _buildSummaryCards(habits),
              const SizedBox(height: 24),

              // Weekly Overview
              Text('Weekly Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildWeeklyChart(habits),
              const SizedBox(height: 24),

              // Per-Habit Stats
              Text('Habit Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...habits.map((habit) => _buildHabitDetailCard(habit)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(List<Habit> habits) {
    final totalHabits = habits.length;
    final activeStreaks = habits.where((h) => h.currentStreak > 0).length;
    final longestStreak = habits.fold<int>(
        0, (max, h) => h.bestStreak > max ? h.bestStreak : max);

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    int totalPossible = totalHabits * 7;
    int totalCompleted = 0;
    for (final habit in habits) {
      final logs = _logsPerHabit[habit.id] ?? [];
      totalCompleted += logs
          .where((log) => log.date.isAfter(weekAgo))
          .length;
    }
    final completionRate =
        totalPossible > 0 ? (totalCompleted / totalPossible * 100) : 0.0;

    return Row(
      children: [
        _buildStatCard('Total', '$totalHabits', Icons.repeat, const Color(0xFF6C63FF)),
        const SizedBox(width: 8),
        _buildStatCard('Active', '$activeStreaks', Icons.local_fire_department, Colors.orange),
        const SizedBox(width: 8),
        _buildStatCard('Best', '$longestStreak', Icons.emoji_events, Colors.amber),
        const SizedBox(width: 8),
        _buildStatCard('Rate', '${completionRate.toStringAsFixed(0)}%', Icons.pie_chart, Colors.teal),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.glassDecoration(opacity: 0.1),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<Habit> habits) {
    final now = DateTime.now();
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final completionsPerDay = List<double>.filled(7, 0);
    for (final habit in habits) {
      final logs = _logsPerHabit[habit.id] ?? [];
      for (final log in logs) {
        final daysAgo = now.difference(log.date).inDays;
        if (daysAgo < 7 && daysAgo >= 0) {
          final dayIndex = (log.date.weekday - 1) % 7;
          completionsPerDay[dayIndex] += 1;
        }
      }
    }

    final maxY = completionsPerDay.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(opacity: 0.1),
      child: BarChart(
        BarChartData(
          maxY: (maxY > 0 ? maxY : 1) + 1,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} done',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dayLabels[value.toInt()],
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: completionsPerDay[i],
                  color: const Color(0xFF6C63FF),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (maxY > 0 ? maxY : 1) + 1,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHabitDetailCard(Habit habit) {
    final logs = _logsPerHabit[habit.id] ?? [];
    final habitColor = habit.color != null
        ? Color(int.parse(habit.color!.replaceFirst('#', '0xFF')))
        : const Color(0xFF6C63FF);

    final now = DateTime.now();
    final last30Days = List.generate(30, (i) {
      final day = now.subtract(Duration(days: 29 - i));
      final completed = logs.any((log) =>
          log.date.year == day.year &&
          log.date.month == day.month &&
          log.date.day == day.day);
      return completed;
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(opacity: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (habit.icon != null && habit.icon!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(habit.icon!, style: const TextStyle(fontSize: 22)),
                ),
              Expanded(
                child: Text(
                  habit.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat(Icons.local_fire_department, '${habit.currentStreak}',
                  'Current', Colors.orange),
              const SizedBox(width: 16),
              _buildMiniStat(
                  Icons.emoji_events, '${habit.bestStreak}', 'Best', Colors.amber),
              const SizedBox(width: 16),
              _buildMiniStat(Icons.check_circle_outline, '${logs.length}',
                  'Total', Colors.green),
            ],
          ),
          const SizedBox(height: 14),
          Text('Last 30 Days',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 3,
            runSpacing: 3,
            children: last30Days.map((completed) {
              return Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: completed
                      ? habitColor
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
      ],
    );
  }
}
