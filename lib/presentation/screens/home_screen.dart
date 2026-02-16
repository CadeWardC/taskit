import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_widgets.dart';
import '../widgets/recurring_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch todos on startup
    Future.microtask(
      () => Provider.of<TodoProvider>(context, listen: false).fetchTodos(),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final detailController = TextEditingController();
    final durationController = TextEditingController();

    String priority = 'none';
    DateTime? dueDate;
    int? listId;
    String? recurringFrequency;
    int repeatInterval = 1;
    List<int>? customRecurringDays;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                32, // Increased padding
            left: 16,
            right: 16,
            top: 24, // Increased top padding
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Task',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
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
                  controller: detailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Details (Optional)',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ['none', 'low', 'medium', 'high']
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => priority = val!),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Due Date and Time Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                  surface: const Color(0xFF1E1E1E),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() {
                            // Preserve time if already set
                            if (dueDate != null) {
                              dueDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                dueDate!.hour,
                                dueDate!.minute,
                              );
                            } else {
                              dueDate = picked;
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        dueDate == null
                            ? 'Set Due Date'
                            : '${dueDate!.month}/${dueDate!.day}',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: dueDate != null
                              ? TimeOfDay.fromDateTime(dueDate!)
                              : TimeOfDay.now(),
                          builder: (context, child) {
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
                          setModalState(() {
                            final date = dueDate ?? DateTime.now();
                            dueDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        dueDate != null && (dueDate!.hour != 0 || dueDate!.minute != 0)
                            ? TimeOfDay.fromDateTime(dueDate!).format(context)
                            : 'Set Time',
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: provider.lists
                          .map(
                            (l) => DropdownMenuItem(
                              value: l.id,
                              child: Text(l.title),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setModalState(() => listId = val),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Recurring Config

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recurring',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              recurringFrequency == null
                                  ? 'None'
                                  : '$recurringFrequency (Every $repeatInterval)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
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
                          detail: detailController.text,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Task',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('TaskIt'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF121212), Color(0xFF2C2C2C)],
          ),
        ),
        child: Consumer<TodoProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.todos.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${provider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: () => provider.fetchTodos(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                top: 100,
                left: 16,
                right: 16,
                bottom: 80,
              ),
              itemCount: provider.todos.length,
              itemBuilder: (context, index) {
                final todo = provider.todos[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(
                    todo: todo,
                    onToggle: () => provider.toggleTodo(todo.id!),
                    onDelete: () => provider.deleteTodo(todo.id!),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTodoDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}

/// Custom date-time picker dialog with time input below the calendar
class DateTimePickerDialog extends StatefulWidget {
  final DateTime? initialDate;

  const DateTimePickerDialog({super.key, this.initialDate});

  @override
  State<DateTimePickerDialog> createState() => _DateTimePickerDialogState();
}

class _DateTimePickerDialogState extends State<DateTimePickerDialog> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    if (widget.initialDate != null) {
      _selectedTime = TimeOfDay.fromDateTime(widget.initialDate!);
      // If the time is 00:00, we might want to treat it as no time set, 
      // but for editing an existing date, we should respect it.
      // However, the previous logic was a bit fuzzy. 
      // Let's assume if it was passed in managed state, it's valid.
      if (_selectedTime!.hour == 0 && _selectedTime!.minute == 0) {
         // Optionally check if we want to treat midnight as "no time"
         // For now, let's keep it if it's strictly from the initialDate object
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
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Calendar
              CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow past dates?
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
