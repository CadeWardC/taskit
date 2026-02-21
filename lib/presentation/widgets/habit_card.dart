import 'package:flutter/material.dart';
import '../../data/models/habit.dart';


class HabitCard extends StatefulWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool isManagementMode;
  final Function(int)? onProgressChange;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
    this.isManagementMode = false,
    this.onProgressChange,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  int? _dragProgress;
  int _baseProgress = 0;
  double _dragStartX = 0.0;

  @override
  void didUpdateWidget(HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.habit.currentProgress != oldWidget.habit.currentProgress) {
      _dragProgress = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    // ... (rest of build setup) ...
    final habitColor = habit.color != null
        ? Color(int.parse(habit.color!.replaceFirst('#', '0xFF')))
        : Theme.of(context).colorScheme.primary;

    // Calculate contrast color for text/icons
    final isLight = habitColor.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black : Colors.white;
    final secondaryTextColor = isLight ? Colors.black54 : Colors.white70;

    // Determine current display progress (dragged or actual)
    final displayProgress = _dragProgress ?? habit.currentProgress;
    final progressRatio = habit.targetCount > 0 
        ? (displayProgress / habit.targetCount).clamp(0.0, 1.0) 
        : (habit.isCompleted ? 1.0 : 0.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return GestureDetector(
          onHorizontalDragStart: widget.isManagementMode ? null : (details) {
            if (habit.targetCount <= 0) return;
            _baseProgress = habit.currentProgress;
            _dragStartX = details.localPosition.dx;
            setState(() {
              _dragProgress = _baseProgress;
            });
          },
          onHorizontalDragUpdate: widget.isManagementMode ? null : (details) {
            if (habit.targetCount <= 0) return;
            
            // Map relative movement to progress change
            final currentX = details.localPosition.dx;
            final deltaX = currentX - _dragStartX;
            
            // Calculate progress delta based on width percentage
            // Full width swipe = full target count change
            final progressDelta = (deltaX / maxWidth * habit.targetCount).round();
            
            final newProgress = (_baseProgress + progressDelta).clamp(0, habit.targetCount);
            
            if (newProgress != _dragProgress) {
              setState(() {
                _dragProgress = newProgress;
              });
            }
          },
          onHorizontalDragEnd: widget.isManagementMode ? null : (details) {
             if (_dragProgress != null) {
               widget.onProgressChange?.call(_dragProgress!);
               // Don't clear _dragProgress here; wait for update from parent
             }
          },
          onHorizontalDragCancel: widget.isManagementMode ? null : () {
             setState(() {
               _dragProgress = null;
             });
          },
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: habitColor, // Base background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Progress Fill Layer
                if (!widget.isManagementMode)
                  AnimatedContainer(
                    duration: _dragProgress != null ? Duration.zero : const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: maxWidth * progressRatio,
                    height: 80, // Reduced from 100
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15), // Darken the filled part
                    ),
                  ),

                // Content Layer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced vertical padding
                  child: Row(
                    children: [
                      // Progress Indicator (Only in Today mode)
                      if (!widget.isManagementMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 20, // Reduced size
                                height: 20,
                                child: CircularProgressIndicator(
                                  value: progressRatio,
                                  backgroundColor: textColor.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                                  strokeWidth: 2.5,
                                ),
                              ),
                              if (displayProgress >= habit.targetCount && habit.targetCount > 0)
                                Icon(Icons.check, size: 14, color: textColor)
                              else if (habit.targetCount > 1)
                                 Text(
                                   '$displayProgress',
                                   style: TextStyle(
                                     fontSize: 9, // Reduced font

                                     fontWeight: FontWeight.bold,
                                     color: textColor,
                                   ),
                                 ),
                            ],
                          ),
                        ),
                        
                      // Emoji icon
                      if (habit.icon != null && habit.icon!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(right: 12, left: widget.isManagementMode ? 0 : 0),
                          child: Text(
                            habit.icon!,
                            style: const TextStyle(fontSize: 20), // Reduced from 24
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
                                decoration: (!widget.isManagementMode && habit.isCompleted) ? TextDecoration.lineThrough : null,
                                color: (!widget.isManagementMode && habit.isCompleted) ? textColor.withValues(alpha: 0.5) : textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15, // Slightly reduced
                              ),
                            ),
                            if (habit.detail != null && habit.detail!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  habit.detail!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: secondaryTextColor,
                                  ),
                                  maxLines: 1, // Reduced lines
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 2), // Reduced from 4
                            if (!widget.isManagementMode)
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 14,
                                    color: habit.currentStreak > 0 ? (isLight ? Colors.orange[800] : Colors.orange) : textColor.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${habit.currentStreak} day streak',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (habit.bestStreak > habit.currentStreak) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '(best: ${habit.bestStreak})',
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.3),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            else
                               // In management mode, show frequency summary
                               Text(
                                  habit.frequency == 'daily' && habit.repeatInterval == 1 
                                    ? 'Daily'
                                    : '${habit.frequency[0].toUpperCase()}${habit.frequency.substring(1)}',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                  ),
                               ),
                          ],
                        ),
                      ),
                      
                      // Delete button (Only in Management mode)
                      if (widget.isManagementMode)
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: textColor.withValues(alpha: 0.6)),
                          onPressed: widget.onDelete,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
