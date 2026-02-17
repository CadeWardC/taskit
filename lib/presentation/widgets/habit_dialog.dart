import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../data/models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/recurring_picker.dart';
import '../widgets/color_selector.dart';

class HabitDialog extends StatefulWidget {
  final Habit? habit;

  const HabitDialog({super.key, this.habit});

  @override
  State<HabitDialog> createState() => _HabitDialogState();
}

class _HabitDialogState extends State<HabitDialog> {
  late TextEditingController _titleController;
  late TextEditingController _detailController;

  String? _selectedColor = '#BB86FC';
  String? _selectedIcon;

  // Config
  int _targetCount = 1;
  String _frequency = 'daily';
  int _repeatInterval = 1;
  String _goalType = 'daily';
  List<int>? _customDays;



  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title);
    _detailController = TextEditingController(text: widget.habit?.detail);
    
    // If editing, load existing values
    if (widget.habit != null) {
      _selectedColor = widget.habit!.color;
      _selectedIcon = widget.habit!.icon;
      _targetCount = widget.habit!.targetCount;
      _frequency = widget.habit!.frequency;
      _repeatInterval = widget.habit!.repeatInterval;
      _goalType = widget.habit!.goalType;
      _customDays = widget.habit!.customDays;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              widget.habit == null ? 'New Habit' : 'Edit Habit',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Habit Name',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon Picker
            GestureDetector(
              onTap: () async {
                await showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1E1E1E),
                  builder: (context) {
                    return SizedBox(
                      height: 300,
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          Navigator.pop(context, emoji.emoji);
                        },
                        config: Config(
                          checkPlatformCompatibility: true,
                          emojiViewConfig: const EmojiViewConfig(
                            backgroundColor: Color(0xFF1E1E1E),
                            columns: 7,
                          ),
                          categoryViewConfig: const CategoryViewConfig(
                            backgroundColor: Color(0xFF1E1E1E),
                            dividerColor: Colors.transparent,
                            indicatorColor: Color(0xFFBB86FC),
                            iconColorSelected: Colors.white,
                            iconColor: Colors.white54,
                          ),
                          bottomActionBarConfig: const BottomActionBarConfig(
                            backgroundColor: Color(0xFF1E1E1E),
                            buttonColor: Color(0xFF1E1E1E),
                            buttonIconColor: Colors.white,
                          ),
                          searchViewConfig: const SearchViewConfig(
                            backgroundColor: Color(0xFF1E1E1E),
                            buttonIconColor: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ).then((value) {
                  if (value != null && value is String) {
                    setState(() => _selectedIcon = value);
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedIcon ?? '😀',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedIcon == null ? 'Select Icon' : 'Change Icon',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),

            // Recurring/Goal Picker
            InkWell(
              onTap: () async {
                final config = await showModalBottomSheet<RecurringConfig>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => RecurringPicker(
                    isHabit: true,
                    initialConfig: RecurringConfig(
                      frequency: _frequency,
                      interval: _repeatInterval,
                      goalType: _goalType,
                      targetCount: _targetCount,
                      customDays: _customDays,
                    ),
                    themeColor: Color(
                      int.parse(
                        (_selectedColor ?? '#BB86FC')
                            .replaceFirst('#', '0xFF'),
                      ),
                    ),
                  ),
                );

                if (config != null) {
                  setState(() {
                    _frequency = config.frequency;
                    _repeatInterval = config.interval;
                    _goalType = config.goalType ?? 'daily';
                    _targetCount = config.targetCount ?? 1;
                    _customDays = config.customDays;
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, color: Colors.white70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schedule & Goal',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '$_targetCount ${_goalType == 'daily' ? 'per day' : 'per period'} • $_frequency',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            ColorSelector(
              selectedColor: _selectedColor ?? '#BB86FC',
              onColorChanged: (color) => setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isNotEmpty) {
                    if (widget.habit == null) {
                      context.read<HabitProvider>().addHabit(
                            title: _titleController.text,
                            detail:
                                _detailController.text.isEmpty
                                    ? null
                                    : _detailController.text,
                            targetCount: _targetCount,
                            frequency: _frequency,
                            repeatInterval: _repeatInterval,
                            goalType: _goalType,
                            customDays: _customDays,
                            color: _selectedColor,
                            icon: _selectedIcon,
                          );
                    } else {
                      context.read<HabitProvider>().updateHabit(
                            widget.habit!.id!,
                            title: _titleController.text,
                            detail:
                                _detailController.text.isEmpty
                                    ? null
                                    : _detailController.text,
                            targetCount: _targetCount,
                            frequency: _frequency,
                            repeatInterval: _repeatInterval,
                            goalType: _goalType,
                            customDays: _customDays,
                            color: _selectedColor,
                            icon: _selectedIcon,
                          );
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.habit == null ? 'Create Habit' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
