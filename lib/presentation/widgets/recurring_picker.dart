import 'package:flutter/material.dart';

class RecurringConfig {
  final String frequency; // 'daily', 'weekly', 'monthly'
  final int interval;
  final List<int>? customDays; // 1=Mon, 7=Sun for Weekly; 1-31 for Monthly

  RecurringConfig({
    required this.frequency,
    this.interval = 1,
    this.customDays,
  });

  @override
  String toString() {
    return 'Frequency: $frequency, Interval: $interval, Days: $customDays';
  }
}

class RecurringPicker extends StatefulWidget {
  final RecurringConfig? initialConfig;
  final Color themeColor;

  const RecurringPicker({
    super.key,
    this.initialConfig,
    this.themeColor = const Color(0xFFBB86FC),
  });

  @override
  State<RecurringPicker> createState() => _RecurringPickerState();
}

class _RecurringPickerState extends State<RecurringPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _interval;
  List<int> _customDays = [];
  
  final List<String> _frequencies = ['daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    
    // Determine initial index
    int initialIndex = 0;
    if (widget.initialConfig != null) {
      initialIndex = _frequencies.indexOf(widget.initialConfig!.frequency);
      if (initialIndex == -1) initialIndex = 0;
    }

    _tabController = TabController(
      length: 3, 
      vsync: this, 
      initialIndex: initialIndex
    );
    
    _interval = widget.initialConfig?.interval ?? 1;
    _customDays = List.from(widget.initialConfig?.customDays ?? []);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          // Reset custom days when switching frequencies to avoid invalid state
          // e.g. switching from Monthly (days 1-31) to Weekly (days 1-7)
           _customDays = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Schedule',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Frequency Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: widget.themeColor,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black, // Depending on themeColor luminosity, but usually black on accent
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Daily'),
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Interval Input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Every', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(width: 16),
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  controller: TextEditingController(text: _interval.toString())
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
              const SizedBox(width: 16),
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  String unit = _frequencies[_tabController.index]; // daily, weekly, monthly
                  // Convert to noun (day, week, month)
                  String noun = unit == 'daily' ? 'day' : unit == 'weekly' ? 'week' : 'month';
                  if (_interval > 1) noun += 's';
                  return Text(noun, style: const TextStyle(color: Colors.white70, fontSize: 16));
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Dynamic Content based on Tab
          SizedBox(
            height: 300, // Fixed height for content area
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                return IndexedStack(
                  index: _tabController.index,
                  children: [
                    _buildDailyView(),
                    _buildWeeklyView(),
                    _buildMonthlyView(),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          
          // Action Buttons
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
                        frequency: _frequencies[_tabController.index],
                        interval: _interval,
                        customDays: _customDays.isNotEmpty ? _customDays : null,
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
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDailyView() {
    return const Center(
      child: Text(
        'Task will repeat every day',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildWeeklyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Quick Select Chips
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildActionChip('Weekdays', [1, 2, 3, 4, 5]),
              _buildActionChip('Weekends', [6, 7]),
              _buildActionChip('All Days', [1, 2, 3, 4, 5, 6, 7]),
            ],
          ),
          const SizedBox(height: 24),
          // Day Toggles
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .asMap()
                .entries
                .map((entry) {
                  final dayIndex = entry.key + 1;
                  final isSelected = _customDays.contains(dayIndex);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _customDays.remove(dayIndex);
                        } else {
                          _customDays.add(dayIndex);
                        }
                        _customDays.sort();
                      });
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? widget.themeColor : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: isSelected ? widget.themeColor : Colors.white24,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        entry.value[0], // First letter
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    return Center(
      child: SizedBox(
        width: 300,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 31,
          itemBuilder: (context, index) {
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
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? widget.themeColor : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? widget.themeColor : Colors.white10,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, List<int> days) {
    final isSelected = _listEquals(_customDays, days);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _customDays = List.from(days);
          } else {
            _customDays = [];
          }
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
          color: isSelected ? widget.themeColor : Colors.transparent,
        ),
      ),
    );
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
