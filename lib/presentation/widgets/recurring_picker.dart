import 'package:flutter/material.dart';

class RecurringConfig {
  final String frequency; // 'daily', 'weekly', 'monthly'
  final int interval;
  final List<int>? customDays; // 1=Mon, 7=Sun
  final String? goalType; // 'daily', 'period' (Habits only)
  final int? targetCount; // (Habits only)

  RecurringConfig({
    required this.frequency,
    this.interval = 1,
    this.customDays,
    this.goalType,
    this.targetCount,
  });

  @override
  String toString() {
    return 'Frequency: $frequency, Interval: $interval, Days: $customDays, Goal: $goalType, Target: $targetCount';
  }
}

class RecurringPicker extends StatefulWidget {
  final RecurringConfig? initialConfig;
  final bool isHabit; // If true, show goal configuration
  final Color themeColor;

  const RecurringPicker({
    super.key,
    this.initialConfig,
    this.isHabit = false,
    this.themeColor = const Color(0xFFBB86FC),
  });

  @override
  State<RecurringPicker> createState() => _RecurringPickerState();
}

class _RecurringPickerState extends State<RecurringPicker> {
  late String _frequency;
  late int _interval;
  List<int> _customDays = [];

  // Habit specific
  late String _goalType;
  late int _targetCount;

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialConfig?.frequency ?? 'daily';
    _interval = widget.initialConfig?.interval ?? 1;
    _customDays = widget.initialConfig?.customDays ?? [];

    // Default to daily goal if not set, or period if habit implies it
    _goalType = widget.initialConfig?.goalType ?? 'daily';
    _targetCount = widget.initialConfig?.targetCount ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
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
              widget.isHabit ? 'Habit Schedule' : 'Recurring Task',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Frequency & Interval Row
            Row(
              children: [
                const Text('Every', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    controller:
                        TextEditingController(text: _interval.toString())
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: _interval.toString().length),
                          ),
                    onChanged: (val) {
                      setState(() {
                        _interval = int.tryParse(val) ?? 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(
                      _frequency,
                    ), // Force rebuild when frequency updates
                    initialValue: _frequency, // Replaced deprecated 'value'
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: ['daily', 'weekly', 'monthly']
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              _interval > 1
                                  ? '${f.replaceFirst('ly', '')}s'
                                  : f,
                              style: const TextStyle(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _frequency = val!),
                  ),
                ),
              ],
            ),

            // Weekly: Custom Days Selector
            if (_frequency == 'weekly') ...[
              const SizedBox(height: 24),
              const Text('On days', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .asMap()
                    .entries
                    .map((entry) {
                      final dayIndex = entry.key + 1;
                      final isSelected = _customDays.contains(dayIndex);
                      return FilterChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _customDays.add(dayIndex);
                            } else {
                              _customDays.remove(dayIndex);
                            }
                            _customDays.sort();
                          });
                        },
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        selectedColor: widget.themeColor.withValues(alpha: 0.3),
                        checkmarkColor: widget.themeColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? widget.themeColor
                                : Colors.transparent,
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
            ],

            // Monthly: Custom Dates Selector
            if (_frequency == 'monthly') ...[
              const SizedBox(height: 24),
              const Text('On dates', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(31, (index) {
                    final day = index + 1;
                    final isSelected = _customDays.contains(day);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _customDays.remove(day);
                          } else {
                            _customDays.add(day);
                          }
                          _customDays.sort();
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.themeColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? widget.themeColor
                                : Colors.white24,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],

            // Habit Goals
            if (widget.isHabit) ...[
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                'Goal',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text(
                        'Daily Goal',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Complete target every active day',
                        style: TextStyle(color: Colors.white54),
                      ),
                      value: 'daily',
                      groupValue: _goalType,
                      onChanged: (val) {
                        if (val != null) setState(() => _goalType = val);
                      },
                      activeColor: widget.themeColor,
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'Period Goal (${_frequency.toUpperCase()})',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Complete target X times per $_frequency',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      value: 'period',
                      groupValue: _goalType,
                      onChanged: (val) {
                        if (val != null) setState(() => _goalType = val);
                      },
                      activeColor: widget.themeColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Text(
                    'Target Count:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      controller:
                          TextEditingController(text: _targetCount.toString())
                            ..selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: _targetCount.toString().length,
                              ),
                            ),
                      onChanged: (val) {
                        setState(() {
                          _targetCount = int.tryParse(val) ?? 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _goalType == 'daily' ? 'per day' : 'times per $_frequency',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        RecurringConfig(
                          frequency: _frequency,
                          interval: _interval,
                          customDays: _customDays.isNotEmpty
                              ? _customDays
                              : null,
                          goalType: _goalType,
                          targetCount: _targetCount,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
