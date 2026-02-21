import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../data/models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/color_selector.dart';
import '../widgets/recurring_picker.dart';

class HabitDialog extends StatefulWidget {
  final Habit? habit;

  const HabitDialog({super.key, this.habit});

  @override
  State<HabitDialog> createState() => _HabitDialogState();
}

class _HabitDialogState extends State<HabitDialog> {
  late TextEditingController _titleController;
  late TextEditingController _detailController;
  late TextEditingController _countController;

  String? _selectedColor = '#BB86FC';
  String? _selectedIcon;

  // Config
  int _targetCount = 1;
  String _unit = 'times';
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
      _unit = widget.habit!.unit;
      _frequency = widget.habit!.frequency;
      _repeatInterval = widget.habit!.repeatInterval;
      _goalType = widget.habit!.goalType;
      _customDays = widget.habit!.customDays;
    }

    _countController = TextEditingController(text: _targetCount.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _countController.dispose();
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _selectedIcon ?? '😀',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.habit == null ? 'New Habit' : 'Edit Habit',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),

            // Recurring/Schedule Picker
            InkWell(
              onTap: () async {
                final config = await showModalBottomSheet<RecurringConfig>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => RecurringPicker(
                    initialConfig: RecurringConfig(
                      frequency: _frequency,
                      interval: _repeatInterval,
                      customDays: _customDays,
                    ),
                    themeColor: _selectedColor != null
                        ? Color(int.parse(_selectedColor!.replaceFirst('#', '0xFF')))
                        : Theme.of(context).colorScheme.primary,
                  ),
                );

                if (config != null) {
                  setState(() {
                    _frequency = config.frequency;
                    _repeatInterval = config.interval;
                    _customDays = config.customDays;
                    
                    // Auto-update goal type based on frequency
                    if (_frequency == 'daily') {
                      _goalType = 'daily';
                    } else {
                      _goalType = 'period';
                    }
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schedule',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getFrequencyText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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

            // Goal Type Slider (Only for Weekly/Monthly)
            if (_frequency == 'weekly' || _frequency == 'monthly') ...[
              Row(
                children: [
                   const Text(
                    'Goal Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E1E),
                          title: const Text('Goal Type', style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'Daily: The target count applies to each scheduled day individually.\n\n'
                            'Period: The target count applies to the entire period (week or month). Progress accumulates until the period resets.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Icon(Icons.info_outline, color: Colors.white54, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _goalType = 'daily'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _goalType == 'daily'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Daily',
                            style: TextStyle(
                              color: _goalType == 'daily' ? Colors.black : Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _goalType = 'period'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _goalType == 'period'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _frequency == 'weekly' ? 'Weekly' : 'Monthly',
                            style: TextStyle(
                              color: _goalType == 'period' ? Colors.black : Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Count & Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Count',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    controller: _countController,
                    onChanged: (val) {
                      setState(() {
                        _targetCount = int.tryParse(val) ?? 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      'times',
                      'minutes',
                      'hours',
                      'pages',
                      'steps',
                      'glasses',
                      'km',
                      'miles',
                    ]
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              u[0].toUpperCase() + u.substring(1),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _unit = val!),
                  ),
                ),
              ],
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
                onPressed: () async {
                  if (_titleController.text.isNotEmpty) {
                    if (widget.habit == null) {
                      // ... add ...
                      context.read<HabitProvider>().addHabit(
                            title: _titleController.text,
                            detail:
                                _detailController.text.isEmpty
                                    ? null
                                    : _detailController.text,
                            targetCount: _targetCount,
                            unit: _unit,
                            frequency: _frequency,
                            repeatInterval: _repeatInterval,
                            goalType: _goalType,
                            customDays: _customDays,
                            color: _selectedColor,
                            icon: _selectedIcon,
                          );
                    } else {
                      debugPrint('HabitDialog: Saving changes for habit ${widget.habit!.id}');
                      
                      await context.read<HabitProvider>().updateHabit(
                            widget.habit!.id!,
                            title: _titleController.text,
                            detail:
                                _detailController.text.isEmpty
                                    ? null
                                    : _detailController.text,
                            targetCount: _targetCount,
                            unit: _unit,
                            frequency: _frequency,
                            repeatInterval: _repeatInterval,
                            goalType: _goalType,
                            customDays: _customDays,
                            color: _selectedColor,
                            icon: _selectedIcon,
                          );
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
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
      ),
    );
  }
  String _getFrequencyText() {
    String text = _frequency[0].toUpperCase() + _frequency.substring(1);
    
    if (_repeatInterval > 1) {
      text += ' (Every $_repeatInterval)';
    }

    if (_customDays != null && _customDays!.isNotEmpty) {
      if (_frequency == 'weekly') {
        if (_customDays!.length == 7) text += ' • All Days';
        else if (_customDays!.length == 5 && !_customDays!.contains(6) && !_customDays!.contains(7)) text += ' • Weekdays';
        else if (_customDays!.length == 2 && _customDays!.contains(6) && _customDays!.contains(7)) text += ' • Weekends';
        else text += ' • ${_customDays!.length} Days';
      } else if (_frequency == 'monthly') {
        text += ' • ${_customDays!.length} Dates';
      }
    }
    
    return text;
  }
}
