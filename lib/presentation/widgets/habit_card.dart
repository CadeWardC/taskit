import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/habit.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final habitColor = habit.color != null
        ? Color(int.parse(habit.color!.replaceFirst('#', '0xFF')))
        : Theme.of(context).colorScheme.primary;

    return Container(
      decoration: AppTheme.glassDecoration(opacity: habit.isCompleted ? 0.05 : 0.1),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: habit.isCompleted,
            onChanged: (_) => onToggle(),
            activeColor: habitColor,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
          ),
          // Emoji icon
          if (habit.icon != null && habit.icon!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                habit.icon!,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          // Title, detail, and streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                    color: habit.isCompleted ? Colors.white54 : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (habit.detail != null && habit.detail!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      habit.detail!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: habit.currentStreak > 0 ? Colors.orange : Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.currentStreak} day streak',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    if (habit.bestStreak > habit.currentStreak) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(best: ${habit.bestStreak})',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white30),
            onPressed: onDelete,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }
}
