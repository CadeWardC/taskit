import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/responsive_scaffold.dart';
import 'lists_screen.dart';
import 'calendar_screen.dart';
import 'habits_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import '../widgets/recurring_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

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
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Reports',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  void _showAddTodoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final detailController = TextEditingController();
    final durationController = TextEditingController();
    String priority = 'none';
    DateTime? dueDate;
    int? listId;
    
    // Recurring Config
    String? recurringFrequency;
    int repeatInterval = 1;
    List<int>? customRecurringDays;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Task', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Details (Optional)',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(priority),
                        initialValue: priority,
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: ['none', 'low', 'medium', 'high'].map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toUpperCase()),
                        )).toList(),
                        onChanged: (val) => setModalState(() => priority = val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Duration (min)',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Due Date and Time - Combined Picker
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final result = await showDialog<DateTime>(
                          context: context,
                          builder: (context) => _DateTimePickerDialog(initialDate: dueDate),
                        );
                        if (result != null) {
                          setModalState(() => dueDate = result);
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        dueDate == null
                            ? 'Set Due Date'
                            : '${dueDate!.month}/${dueDate!.day}${dueDate!.hour == 0 && dueDate!.minute == 0 ? '' : ' at ${TimeOfDay.fromDateTime(dueDate!).format(context)}'}',
                      ),
                    ),
                    if (dueDate != null)
                      IconButton(
                        onPressed: () => setModalState(() => dueDate = null),
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'Clear Due Date',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<TodoProvider>(
                  builder: (context, provider, child) {
                    if (provider.lists.isEmpty) return const SizedBox.shrink();
                    return DropdownButtonFormField<int>(
                      key: ValueKey(listId),
                      initialValue: listId,
                      dropdownColor: const Color(0xFF2C2C2C),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'List',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: provider.lists.map((l) => DropdownMenuItem(
                        value: l.id,
                        child: Text(l.title),
                      )).toList(),
                      onChanged: (val) => setModalState(() => listId = val),
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                // Recurring Picker Button
                InkWell(
                  onTap: () async {
                    final config = await showModalBottomSheet<RecurringConfig>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => RecurringPicker(
                        initialConfig: recurringFrequency != null
                          ? RecurringConfig(
                              frequency: recurringFrequency!,
                              interval: repeatInterval,
                              customDays: customRecurringDays,
                            )
                          : null,
                        themeColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                    
                    if (config != null) {
                      setModalState(() {
                        recurringFrequency = config.frequency;
                        repeatInterval = config.interval;
                        customRecurringDays = config.customDays;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.repeat, color: Colors.white70),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recurring', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              recurringFrequency == null 
                                  ? 'None' 
                                  : '$recurringFrequency (Every $repeatInterval)', 
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.white54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        context.read<TodoProvider>().addTodo(
                          title: titleController.text,
                          detail: detailController.text.isEmpty ? null : detailController.text,
                          priority: priority,
                          duration: int.tryParse(durationController.text),
                          dueDate: dueDate,
                          listId: listId,
                          recurringFrequency: recurringFrequency,
                          repeatInterval: repeatInterval,
                          customRecurringDays: customRecurringDays,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create Task', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      navItems: _navItems,
      destinations: const [
        ListsScreen(),
        CalendarScreen(),
        HabitsScreen(),
        ReportsScreen(),
        SettingsScreen(),
      ],
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    // Don't show on Settings or Reports tab
    if (_selectedIndex >= 3) return null;
    
    // Habits tab - show "New Habit" button
    if (_selectedIndex == 2) {
      return FloatingActionButton.extended(
        onPressed: () => _showAddHabitDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      );
    }
    
    // Lists and Calendar tabs - show "New Task" button
    return FloatingActionButton.extended(
      onPressed: () => _showAddTodoDialog(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label: const Text('New Task'),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final titleController = TextEditingController();
    final detailController = TextEditingController();
    String? selectedColor = '#BB86FC';
    String? selectedIcon;
    
    // Config
    int targetCount = 1;
    String frequency = 'daily';
    int repeatInterval = 1;
    String goalType = 'daily';
    List<int>? customDays;

    final colors = ['#BB86FC', '#03DAC6', '#CF6679', '#FFA000', '#4CAF50', '#2196F3'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Habit', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Habit Name',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                        setModalState(() => selectedIcon = value);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedIcon ?? '😀',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedIcon == null ? 'Select Icon' : 'Change Icon',
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
                          frequency: frequency,
                          interval: repeatInterval,
                          goalType: goalType,
                          targetCount: targetCount,
                          customDays: customDays,
                        ),
                        themeColor: Color(int.parse((selectedColor ?? '#BB86FC').replaceFirst('#', '0xFF'))),
                      ),
                    );
                    
                    if (config != null) {
                      setModalState(() {
                        frequency = config.frequency;
                        repeatInterval = config.interval;
                        goalType = config.goalType ?? 'daily';
                        targetCount = config.targetCount ?? 1;
                        customDays = config.customDays;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.repeat, color: Colors.white70),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Schedule & Goal', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(
                                '$targetCount ${goalType == 'daily' ? 'per day' : 'per period'} • $frequency',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
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
                Text('Color', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        context.read<HabitProvider>().addHabit(
                          title: titleController.text,
                          detail: detailController.text.isEmpty ? null : detailController.text,
                          targetCount: targetCount,
                          frequency: frequency,
                          repeatInterval: repeatInterval,
                          goalType: goalType,
                          customDays: customDays,
                          color: selectedColor,
                          icon: selectedIcon,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create Habit', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Combined date-time picker dialog with calendar and time selection
class _DateTimePickerDialog extends StatefulWidget {
  final DateTime? initialDate;

  const _DateTimePickerDialog({this.initialDate});

  @override
  State<_DateTimePickerDialog> createState() => _DateTimePickerDialogState();
}

class _DateTimePickerDialogState extends State<_DateTimePickerDialog> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    if (widget.initialDate != null) {
      final time = TimeOfDay.fromDateTime(widget.initialDate!);
      // Only set time if it's not midnight (treat midnight as no time set)
      if (time.hour != 0 || time.minute != 0) {
        _selectedTime = time;
      }
    }
  }

  DateTime _buildResult() {
    if (_selectedTime != null) {
      return DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }
    return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF1E1E1E),
              dayPeriodColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              dayPeriodTextColor: Colors.white,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialBackgroundColor: Colors.white.withValues(alpha: 0.05),
              hourMinuteTextColor: Colors.white,
              entryModeIconColor: Theme.of(context).colorScheme.primary,
              helpTextStyle: const TextStyle(color: Colors.white),
              dialTextColor: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // On desktop (>600px), center the dialog with max 400px width
    // On mobile, use default padding (24px on each side)
    final horizontalInset = screenWidth > 600 ? (screenWidth - 400) / 2 : 24.0;
    
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Calendar
              CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              // Time Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'No time set',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _pickTime,
                    child: Text(_selectedTime == null ? 'Set Time' : 'Change Time'),
                  ),
                ],
              ),
              if (_selectedTime != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                     onPressed: () => setState(() => _selectedTime = null),
                     style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                     child: const Text('Clear Time'),
                  ),
                ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _buildResult()),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
