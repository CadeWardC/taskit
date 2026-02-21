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

class TaskCard extends StatefulWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Color? activeColor;

  const TaskCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    this.activeColor,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0, // Start fully visible
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleToggle(bool? value) {
    if (value == null) return;
    
    if (widget.todo.isCompleted) {
      // Unchecking - do immediately
      widget.onToggle();
    } else {
      // Checking - animate then toggle
      setState(() => _isChecking = true);
      
      // Reverse animation to shrink height
      _controller.reverse().then((_) {
        if (mounted) {
           widget.onToggle();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.getPriorityColor(widget.todo.priority);
    final isDone = widget.todo.isCompleted || _isChecking;
    
    // Wrap entire card in SizeTransition for smooth exit
    return SizeTransition(
      sizeFactor: _animation,
      axis: Axis.vertical,
      axisAlignment: -1.0, // Anchor at top, shrink from bottom
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isChecking ? 0.0 : (widget.todo.isCompleted ? 0.5 : 1.0),
        curve: Curves.easeOut,
        child: GlassContainer(
          opacity: widget.todo.isCompleted ? 0.05 : 0.1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Checkbox(
                  value: isDone,
                  onChanged: _handleToggle,
                  activeColor: widget.activeColor ?? Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.todo.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? Colors.white54 : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.todo.detail != null && widget.todo.detail!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          widget.todo.detail!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Date and Duration Row moved here
                    if (widget.todo.dueDate != null || widget.todo.duration != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            if (widget.todo.dueDate != null) ...[
                              const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text(
                                () {
                                  final date = widget.todo.dueDate!.toLocal();
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
                            if (widget.todo.duration != null) ...[
                              const Icon(Icons.timer, size: 12, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.todo.duration} min',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ]
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
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
              ),
            ],
          ),
        ).animate().fadeIn().slideX(begin: 0.2, end: 0),
      ),
    );
  }
}
