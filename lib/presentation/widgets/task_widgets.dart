import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/todo.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double opacity;
  final EdgeInsetsGeometry padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.opacity = 0.1,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassDecoration(opacity: opacity),
      padding: padding,
      child: child,
    );
  }
}

class TaskCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.getPriorityColor(todo.priority);
    
    return GlassContainer(
      opacity: todo.isCompleted ? 0.05 : 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: todo.isCompleted,
                onChanged: (_) => onToggle(),
                activeColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                        color: todo.isCompleted ? Colors.white54 : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                     if (todo.detail != null && todo.detail!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          todo.detail!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                             color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                     BoxShadow(color: priorityColor.withValues(alpha: 0.4), blurRadius: 4),
                  ]
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white30),
                onPressed: onDelete,
              ),
            ],
          ),
          if (todo.dueDate != null || todo.duration != null)
            Padding(
              padding: const EdgeInsets.only(left: 48, right: 16, bottom: 4),
              child: Row(
                children: [
                  if (todo.dueDate != null) ...[
                    const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      () {
                        final date = todo.dueDate!.toLocal();
                        final dateStr = '${date.month}/${date.day}';
                        if (date.hour != 0 || date.minute != 0) {
                          final timeStr = TimeOfDay.fromDateTime(date).format(context);
                          return '$dateStr $timeStr';
                        }
                        return dateStr;
                      }(),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (todo.duration != null) ...[
                     const Icon(Icons.timer, size: 12, color: Colors.white38),
                     const SizedBox(width: 4),
                     Text(
                       '${todo.duration} min',
                       style: const TextStyle(color: Colors.white38, fontSize: 12),
                     ),
                  ]
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }
}
