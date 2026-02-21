import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/recurring_picker.dart';

class TaskDialog extends StatefulWidget {
  final Todo? todo;
  final int? initialListId;

  const TaskDialog({super.key, this.todo, this.initialListId});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _detailController;
  late TextEditingController _durationController;

  String _priority = 'none';
  DateTime? _dueDate;
  int? _listId;
  String? _recurringFrequency;
  int _repeatInterval = 1;
  List<int>? _customRecurringDays;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title);
    _detailController = TextEditingController(text: widget.todo?.detail);
    _durationController = TextEditingController(
        text: widget.todo?.duration?.toString() ?? '');
    
    _priority = widget.todo?.priority ?? 'none';
    _dueDate = widget.todo?.dueDate;
    _listId = widget.todo?.listId ?? widget.initialListId;
    _recurringFrequency = widget.todo?.recurringFrequency;
    _repeatInterval = widget.todo?.repeatInterval ?? 1;
    _customRecurringDays = widget.todo?.customRecurringDays;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _durationController.dispose();
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
            Text(
              widget.todo == null ? 'New Task' : 'Edit Task',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
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
              controller: _detailController,
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
                    initialValue: _priority,
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
                    onChanged: (val) => setState(() => _priority = val!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _durationController,
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
                      initialDate: _dueDate ?? DateTime.now(),
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
                      setState(() {
                         if (_dueDate != null) {
                          _dueDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            _dueDate!.hour,
                            _dueDate!.minute,
                          );
                        } else {
                          _dueDate = picked;
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    _dueDate == null
                        ? 'Set Due Date'
                        : '${_dueDate!.month}/${_dueDate!.day}',
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _dueDate != null
                          ? TimeOfDay.fromDateTime(_dueDate!)
                          : TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            timePickerTheme: TimePickerThemeData(
                              backgroundColor: const Color(0xFF1E1E1E),
                              dayPeriodColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                              dayPeriodTextColor: Colors.white,
                              dialHandColor: Theme.of(context).colorScheme.primary,
                              dialBackgroundColor:
                                  Colors.white.withValues(alpha: 0.05),
                              hourMinuteTextColor: Colors.white,
                              entryModeIconColor:
                                  Theme.of(context).colorScheme.primary,
                              helpTextStyle: const TextStyle(color: Colors.white),
                              dialTextColor: Colors.white,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        final date = _dueDate ?? DateTime.now();
                        _dueDate = DateTime(
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
                    _dueDate != null &&
                            (_dueDate!.hour != 0 || _dueDate!.minute != 0)
                        ? TimeOfDay.fromDateTime(_dueDate!).format(context)
                        : 'Set Time',
                  ),
                ),
                if (_dueDate != null)
                  IconButton(
                    onPressed: () => setState(() => _dueDate = null),
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
                  initialValue: _listId,
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
                  onChanged: (val) => setState(() => _listId = val),
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
                    initialConfig: _recurringFrequency != null
                        ? RecurringConfig(
                            frequency: _recurringFrequency!,
                            interval: _repeatInterval,
                            customDays: _customRecurringDays,
                          )
                        : null,
                    themeColor: Theme.of(context).colorScheme.primary,
                  ),
                );

                if (config != null) {
                  setState(() {
                    _recurringFrequency = config.frequency;
                    _repeatInterval = config.interval;
                    _customRecurringDays = config.customDays;
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
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          _recurringFrequency == null
                              ? 'None'
                              : '$_recurringFrequency (Every $_repeatInterval)',
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
                  if (_titleController.text.isNotEmpty) {
                    if (widget.todo == null) {
                      context.read<TodoProvider>().addTodo(
                            title: _titleController.text,
                            detail: _detailController.text,
                            priority: _priority,
                            duration: int.tryParse(_durationController.text),
                            dueDate: _dueDate,
                            listId: _listId,
                            recurringFrequency: _recurringFrequency,
                            repeatInterval: _repeatInterval,
                            customRecurringDays: _customRecurringDays,
                          );
                    } else {
                      context.read<TodoProvider>().updateTodo(
                            widget.todo!.id!,
                            title: _titleController.text,
                            detail: _detailController.text,
                            priority: _priority,
                            duration: int.tryParse(_durationController.text),
                            dueDate: _dueDate,
                            listId: _listId,
                            recurringFrequency: _recurringFrequency,
                            repeatInterval: _repeatInterval,
                            customRecurringDays: _customRecurringDays,
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
                  widget.todo == null ? 'Create Task' : 'Save Changes',
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
}
