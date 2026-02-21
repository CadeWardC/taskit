import 'package:flutter/material.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_log.dart';

import '../../data/repositories/habit_repository.dart';
import '../../data/services/local_cache_service.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository _repository;
  final LocalCacheService _cache;
  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _error;

  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  HabitProvider(this._repository, this._cache);

  Future<void> fetchHabits() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Load cached data first for instant UI
    if (_habits.isEmpty) {
      final cachedHabits = await _cache.getCachedHabits();
      if (cachedHabits != null && cachedHabits.isNotEmpty) {
        _habits = cachedHabits;
        _isLoading = false;
        notifyListeners();
        _isLoading = true;
      }
    }

    try {
      _habits = await _repository.getHabits();
      await _cache.cacheHabits(_habits);
      
      // Check for daily resets (streaks, progress)
      await resetDailyProgress();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHabit({
    required String title,
    String? detail,
    String? icon,
    String? color,
    int targetCount = 1,
    String unit = 'times',
    String frequency = 'daily',
    int repeatInterval = 1,
    String goalType = 'daily',
    List<int>? customDays,
  }) async {
    try {
      final newHabit = await _repository.addHabit(
        title: title,
        detail: detail,
        icon: icon,
        color: color,
        targetCount: targetCount,
        unit: unit,
        frequency: frequency,
        repeatInterval: repeatInterval,
        goalType: goalType,
        customDays: customDays,
      );
      _habits.add(newHabit);
      await _cache.cacheHabits(_habits);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateHabit(
    int id, {
    String? title,
    String? detail,
    String? icon,
    String? color,
    int? targetCount,
    String? unit,
    String? frequency,
    int? repeatInterval,
    String? goalType,
    List<int>? customDays,
  }) async {
    try {
      final updatedHabit = await _repository.updateHabit(
        id,
        title: title,
        detail: detail,
        icon: icon,
        color: color,
        targetCount: targetCount,
        unit: unit,
        frequency: frequency,
        repeatInterval: repeatInterval,
        goalType: goalType,
        customDays: customDays,
      );
      
      final index = _habits.indexWhere((h) => h.id == id);
      if (index != -1) {
        _habits[index] = updatedHabit;
        await _cache.cacheHabits(_habits);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleHabit(int id) async {
    try {
      final index = _habits.indexWhere((h) => h.id == id);
      if (index == -1) return;

      final habit = _habits[index];
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      if (!habit.isCompleted) {
        // === CHECKING OFF (completing) ===
        final updatedHabit = await _repository.updateHabit(
          id,
          currentProgress: habit.targetCount,
          lastCompleted: today,
          currentStreak: habit.currentStreak + 1,
        );

        _habits[index] = updatedHabit;
      } else {
        // === UNCHECKING (un-completing) ===
        // bool shouldClearLastCompleted = false; // Unused
        DateTime? newLastCompleted;

        // If it was completed TODAY, revert lastCompleted
        debugPrint('Checking for log deletion (toggleHabit): lastCompleted=${habit.lastCompleted} (UTC) vs today=$today (Local)');
        
        if (habit.lastCompleted != null) {
          final isSame = _isSameDay(habit.lastCompleted!, today);
          debugPrint('Are they same day? $isSame (Local conversions: ${habit.lastCompleted!.toLocal()} vs ${today.toLocal()})');
        
          if (isSame) {
            // Revert to yesterday to reflect "streak is pending for today" state
            newLastCompleted = yesterday;
            
            // DELETE ALL HABIT LOGS FOR TODAY
            try {
              debugPrint('Attempting to delete logs for habit $id on date $today');
              await _repository.deleteHabitLogsForDate(id, today);
            } catch (e) {
              debugPrint('Error deleting habit logs: $e');
            }
          }
        }
        
        int newStreak = habit.currentStreak;
        if (habit.lastCompleted != null && _isSameDay(habit.lastCompleted!, today)) {
          newStreak = (habit.currentStreak - 1).clamp(0, 99999);
        }
        
        final updatedHabit = await _repository.updateHabit(
          id,
          currentProgress: 0,
          currentStreak: newStreak,
          lastCompleted: newLastCompleted,
        );

        _habits[index] = updatedHabit;
      }

      await _cache.cacheHabits(_habits);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> incrementProgress(int id) async {
    try {
      final index = _habits.indexWhere((h) => h.id == id);
      if (index == -1) return;

      final habit = _habits[index];
      if (habit.currentProgress >= habit.targetCount) return; // Prevent exceeding target

      final newProgress = habit.currentProgress + 1;
      final isNowComplete = newProgress >= habit.targetCount;

      int newStreak = habit.currentStreak;
      DateTime? newLastCompleted = habit.lastCompleted;

      if (isNowComplete && !habit.isCompletedToday) {
        // Just record completion date
        final today = DateTime.now();
        newLastCompleted = today;
        newStreak = habit.currentStreak + 1;

        // Log the completion
        await _repository.logCompletion(
          habitId: id,
          date: today,
          completedCount: newProgress,
        );
      }

      final updatedHabit = await _repository.updateHabit(
        id,
        currentProgress: newProgress,
        lastCompleted: newLastCompleted,
        currentStreak: newStreak,
      );

      _habits[index] = updatedHabit;
      await _cache.cacheHabits(_habits);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> completeHabit(int id) async {
    try {
      final index = _habits.indexWhere((h) => h.id == id);
      if (index == -1) return;

      final habit = _habits[index];
      if (habit.currentProgress >= habit.targetCount) return; // Already complete

      final newProgress = habit.targetCount;
      // The rest is similar to incrementProgress logic for completion
      
      // int newStreak = habit.currentStreak; // Unused
      DateTime? newLastCompleted = habit.lastCompleted;
      int newStreak = habit.currentStreak;

      if (!habit.isCompletedToday) {
        // Just record completion date
        final today = DateTime.now();
        newLastCompleted = today;
        newStreak = habit.currentStreak + 1;

        // Log the completion
        await _repository.logCompletion(
          habitId: id,
          date: today,
          completedCount: newProgress,
        );
      }

      final updatedHabit = await _repository.updateHabit(
        id,
        currentProgress: newProgress,
        lastCompleted: newLastCompleted,
        currentStreak: newStreak,
      );

      _habits[index] = updatedHabit;
      await _cache.cacheHabits(_habits);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProgress(int id, int newProgress) async {
    try {
      final index = _habits.indexWhere((h) => h.id == id);
      if (index == -1) return;

      final habit = _habits[index];
      // Clamp progress between 0 and targetCount
      final clampedProgress = newProgress.clamp(0, habit.targetCount);
      
      if (clampedProgress == habit.currentProgress) return;

      final isNowComplete = clampedProgress >= habit.targetCount;
      final wasComplete = habit.currentProgress >= habit.targetCount;

      // Streak logic removed.
      DateTime? newLastCompleted = habit.lastCompleted;
      int newStreak = habit.currentStreak;
      
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // Handle Completion
      if (isNowComplete && !wasComplete) {
         if (!habit.isCompletedToday) {
            newLastCompleted = today;
            newStreak = habit.currentStreak + 1;
            // Log the completion
            await _repository.logCompletion(
              habitId: id,
              date: today,
              completedCount: clampedProgress,
            );
         }
      } 
      // Handle Un-completion
      else if (wasComplete && !isNowComplete) {
        debugPrint('Un-completing habit $id. Checking lastCompleted: ${habit.lastCompleted} vs today: $today');
        
        final isSame = habit.lastCompleted != null && _isSameDay(habit.lastCompleted!, today);
        debugPrint('Is same day? $isSame');
        
        if (habit.lastCompleted != null && isSame) {
           // Revert lastCompleted to yesterday
           newLastCompleted = yesterday;
           newStreak = (habit.currentStreak - 1).clamp(0, 99999);
           
           // DELETE ALL HABIT LOGS FOR TODAY
           try {
             debugPrint('Attempting to delete logs for habit $id on date $today');
             await _repository.deleteHabitLogsForDate(id, today);
           } catch (e) {
             debugPrint('Error deleting habit logs: $e');
           }
        } else {
          debugPrint('Skipping log deletion. lastCompleted was ${habit.lastCompleted}');
        }
      }

      final updatedHabit = await _repository.updateHabit(
        id,
        currentProgress: clampedProgress,
        lastCompleted: newLastCompleted,
        currentStreak: newStreak,
      );

      _habits[index] = updatedHabit;
      await _cache.cacheHabits(_habits);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> decrementProgress(int id) async {
    try {
      final index = _habits.indexWhere((h) => h.id == id);
      if (index == -1) return;

      final habit = _habits[index];
      if (habit.currentProgress <= 0) return;

      final newProgress = habit.currentProgress - 1;
      
      // Check if we are un-completing the habit
      // i.e., it was complete (progress >= target), and now it's not (newProgress < target)
      final wasComplete = habit.currentProgress >= habit.targetCount;
      final isNowComplete = newProgress >= habit.targetCount;
      
      int newStreak = habit.currentStreak;
      DateTime? newLastCompleted = habit.lastCompleted;

      if (wasComplete && !isNowComplete) {
        // We are undoing a completion.
        // If it was completed TODAY, we should revert lastCompleted.
        final today = DateTime.now();
        if (habit.lastCompleted != null && _isSameDay(habit.lastCompleted!, today)) {
          // Revert to yesterday
          newStreak = (habit.currentStreak - 1).clamp(0, 99999);
          if (habit.currentStreak > 0) {
             newLastCompleted = today.subtract(const Duration(days: 1));
          } else {
             newLastCompleted = null; // Or unknown. Null is safest to start fresh?
          }

          // DELETE ALL HABIT LOGS FOR TODAY
          try {
            await _repository.deleteHabitLogsForDate(id, today);
          } catch (e) {
            debugPrint('Error deleting habit logs: $e');
          }
        }
      }

      final updatedHabit = await _repository.updateHabit(
        id,
        currentProgress: newProgress,
        currentStreak: newStreak, 
        lastCompleted: newLastCompleted,
      );

      _habits[index] = updatedHabit;
      await _cache.cacheHabits(_habits);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> resetDailyProgress() async {
    // Called at start of new day to reset progress for daily habits
    try {
      final today = DateTime.now();
      
      final lastReset = await _cache.getLastDailyReset();
      if (lastReset != null && _isSameDay(lastReset, today)) {
        return; // Already processed resets for today
      }
      
      final yesterday = today.subtract(const Duration(days: 1));

      for (int i = 0; i < _habits.length; i++) {
        final habit = _habits[i];
        
        // Idempotency check: If habit was already updated today, skip logic.
        // This prevents double streak increments or resetting progress mid-day.
        if (habit.dateUpdated != null && _isSameDay(habit.dateUpdated!, today)) {
          continue;
        }

        if (habit.frequency == 'daily' ||
            _shouldResetForFrequency(habit, today)) {
          
          int newStreak = habit.currentStreak;
          int newBestStreak = habit.bestStreak;

          // STREAK LOGIC:
          if (habit.lastCompleted != null) {
            if (_isSameDay(habit.lastCompleted!, yesterday)) {
               // Completed yesterday. Streak is maintained up to yesterday. No action needed!
               newStreak = habit.currentStreak;
            } else if (_isSameDay(habit.lastCompleted!, today)) {
               // Completed today. Streak is maintained. No action needed!
               newStreak = habit.currentStreak;
            } else {
               // Missed yesterday -> Reset streak
               if (habit.frequency == 'daily') {
                 newStreak = 0;
               }
            }
          } else {
            newStreak = 0;
          }

          if (newStreak > newBestStreak) {
            newBestStreak = newStreak;
          }

          // Reset progress for the new day
          // CRITICAL FIX: If the habit was already completed/updated TODAY (via user interaction),
          // DO NOT reset progress to 0.
          int currentProgressToSet = 0;
          bool shouldRespectCurrentProgress = false;

          if (habit.lastCompleted != null && _isSameDay(habit.lastCompleted!, today)) {
             shouldRespectCurrentProgress = true;
             currentProgressToSet = habit.currentProgress;
          }

          // Only update if changes found OR if we need to set dateUpdated
          if (habit.currentProgress > 0 || newStreak != habit.currentStreak || newBestStreak != habit.bestStreak || !shouldRespectCurrentProgress || habit.dateUpdated == null || !_isSameDay(habit.dateUpdated!, today)) {
            final updatedHabit = await _repository.updateHabit(
              habit.id!,
              currentProgress: currentProgressToSet,
              currentStreak: newStreak,
              bestStreak: newBestStreak,
              dateUpdated: today, // MARK AS UPDATED TODAY
            );
            _habits[i] = updatedHabit;
          }
        }
      }
      await _cache.setLastDailyReset(today);
      await _cache.cacheHabits(_habits);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool _shouldResetForFrequency(Habit habit, DateTime today) {
    // If goal type is 'period', we only reset at the start of the period.
    if (habit.goalType == 'period') {
      if (habit.frequency == 'weekly') {
        // Reset on Monday
        return today.weekday == DateTime.monday;
      } else if (habit.frequency == 'monthly') {
        // Reset on 1st of month
        return today.day == 1;
      }
    }

    // Default 'daily' behavior (reset every scheduled day)
    switch (habit.frequency) {
      case 'weekly':
        // If it's a daily goal on a weekly habit, we reset on every scheduled day.
        // If customDays are set, reset on those days.
        // If no customDays, assume every day (default)? Or maybe Monday?
        // Actually for "Daily" goal on "Weekly" habit without custom days implies "Every day of the week"?
        // Or does it mean "Once a week, but treated as a daily task"?
        // Let's assume:
        // Weekly + Daily Goal + Custom Days -> Reset on Custom Days
        // Weekly + Daily Goal + No Custom Days -> Reset every day (standard daily behavior)
        if (habit.customDays != null && habit.customDays!.isNotEmpty) {
           return habit.customDays!.contains(today.weekday);
        }
        return true; // Default to daily reset if no specific days
      case 'monthly':
        // Monthly + Daily Goal + Custom Days -> Reset on Custom Days
        if (habit.customDays != null && habit.customDays!.isNotEmpty) {
           return habit.customDays!.contains(today.day);
        }
        return true;
      case 'custom':
        return habit.customDays?.contains(today.weekday) ?? false;
      default:
        return true;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year && localA.month == localB.month && localA.day == localB.day;
  }

  Future<void> deleteHabit(int id) async {
    try {
      // First delete all associated logs (cascade delete)
      await _repository.deleteAllHabitLogs(id);
      // Then delete the habit
      await _repository.deleteHabit(id);
      _habits.removeWhere((h) => h.id == id);
      await _cache.cacheHabits(_habits);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<HabitLog>?> getCachedHabitLogs(int habitId) =>
      _cache.getCachedHabitLogs(habitId);

  Future<List<HabitLog>> getHabitHistory(int habitId) async {
    try {
      final logs = await _repository.getHabitLogs(habitId);
      await _cache.cacheHabitLogs(habitId, logs);
      return logs;
    } catch (e) {
      // Fall back to cached logs on error
      final cached = await _cache.getCachedHabitLogs(habitId);
      if (cached != null) return cached;
      rethrow;
    }
  }
}

