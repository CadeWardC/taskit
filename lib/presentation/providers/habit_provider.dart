import 'package:flutter/material.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_log.dart';

import '../../data/repositories/habit_repository.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository _repository;
  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _error;

  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  HabitProvider(this._repository);

  Future<void> fetchHabits() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _habits = await _repository.getHabits();
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
        frequency: frequency,
        repeatInterval: repeatInterval,
        goalType: goalType,
        customDays: customDays,
      );
      _habits.add(newHabit);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle habit completion like a task checkbox.
  /// Check = mark complete for today, increment streak.
  /// Uncheck = mark incomplete, revert streak so re-checking doesn't double-count.
  /// Best streak is NOT updated here — it's finalized at midnight in resetDailyProgress.
  Future<void> toggleHabit(int id) async {
    try {
      final index = _habits.indexWhere((h) => h.id == id);
      if (index == -1) return;

      final habit = _habits[index];
      final today = DateTime.now();

      if (!habit.isCompleted) {
        // === CHECKING OFF (completing) ===
        int newStreak = habit.currentStreak;
        final yesterday = today.subtract(const Duration(days: 1));

        if (habit.lastCompleted == null) {
          newStreak = 1;
        } else if (_isSameDay(habit.lastCompleted!, yesterday)) {
          newStreak = habit.currentStreak + 1;
        } else if (_isSameDay(habit.lastCompleted!, today)) {
          // Already completed today before (toggled off then on again)
          // Don't change streak — it was already counted
        } else {
          // Streak broken, starting new
          newStreak = 1;
        }

        final updatedHabit = await _repository.updateHabit(
          id,
          currentProgress: habit.targetCount,
          currentStreak: newStreak,
          lastCompleted: today,
        );

        _habits[index] = updatedHabit;
      } else {
        // === UNCHECKING (un-completing) ===
        int newStreak = habit.currentStreak;
        bool shouldClearLastCompleted = false;
        DateTime? newLastCompleted;

        // Only revert streak if it was completed today
        if (habit.lastCompleted != null && _isSameDay(habit.lastCompleted!, today)) {
          if (newStreak > 0) {
            newStreak = newStreak - 1;
          }
          // Revert lastCompleted so re-checking works correctly
          if (newStreak > 0) {
            newLastCompleted = today.subtract(const Duration(days: 1));
          } else {
            // Streak is 0, clear lastCompleted entirely
            shouldClearLastCompleted = true;
          }
        }

        final updatedHabit = await _repository.updateHabit(
          id,
          currentProgress: 0,
          currentStreak: newStreak,
          lastCompleted: newLastCompleted,
          clearLastCompleted: shouldClearLastCompleted,
        );

        _habits[index] = updatedHabit;
      }

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
      final newProgress = habit.currentProgress + 1;
      final isNowComplete = newProgress >= habit.targetCount;

      // Calculate streak
      int newStreak = habit.currentStreak;
      int newBestStreak = habit.bestStreak;
      DateTime? newLastCompleted = habit.lastCompleted;

      if (isNowComplete && !habit.isCompletedToday) {
        // Check if continuing streak
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        if (habit.lastCompleted == null) {
          newStreak = 1;
        } else if (_isSameDay(habit.lastCompleted!, yesterday)) {
          newStreak = habit.currentStreak + 1;
        } else if (_isSameDay(habit.lastCompleted!, today)) {
          // Already completed today, don't change streak
        } else {
          // Streak broken, starting new
          newStreak = 1;
        }

        newBestStreak = newStreak > habit.bestStreak
            ? newStreak
            : habit.bestStreak;
        newLastCompleted = today;

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
        currentStreak: newStreak,
        bestStreak: newBestStreak,
        lastCompleted: newLastCompleted,
      );

      _habits[index] = updatedHabit;
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
        // If it was completed TODAY, we should revert the streak.
        final today = DateTime.now();
        if (habit.lastCompleted != null && _isSameDay(habit.lastCompleted!, today)) {
          // It was completed today. Revert streak.
          if (newStreak > 0) {
            newStreak = newStreak - 1;
            
            // Revert lastCompleted. 
            // If new streak is > 0, assumes previous completion was yesterday.
            // If new streak is 0, then no previous completion relevant for streak.
            if (newStreak > 0) {
               newLastCompleted = today.subtract(const Duration(days: 1));
            } else {
               // If streak is 0, we can't easily know when the *actual* last completion was 
               // without a full history log, but for streak purposes, it's not "today".
               // Setting to null or keeping as is? 
               // If we keep as 'today', it might auto-increment again if we re-complete.
               // Best to set to yesterday or null to allow re-increment.
               // Let's set to null to be safe, as "streak broken/reset".
               newLastCompleted = null; 
            }
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
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> resetDailyProgress() async {
    // Called at start of new day to reset progress for daily habits
    // Also finalizes bestStreak from the previous day
    try {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      for (int i = 0; i < _habits.length; i++) {
        final habit = _habits[i];
        if (habit.frequency == 'daily' ||
            _shouldResetForFrequency(habit, today)) {
          
          int newStreak = habit.currentStreak;
          int newBestStreak = habit.bestStreak;

          // Finalize best streak from yesterday's activity
          if (newStreak > newBestStreak) {
            newBestStreak = newStreak;
          }

          // Check if streak should be broken
          // If the habit was NOT completed yesterday, the streak is broken
          if (habit.lastCompleted != null) {
            if (!_isSameDay(habit.lastCompleted!, yesterday) && 
                !_isSameDay(habit.lastCompleted!, today)) {
              newStreak = 0; // Streak broken — missed yesterday
            }
          }

          if (habit.currentProgress > 0 || newStreak != habit.currentStreak || newBestStreak != habit.bestStreak) {
            final updatedHabit = await _repository.updateHabit(
              habit.id!,
              currentProgress: 0,
              currentStreak: newStreak,
              bestStreak: newBestStreak,
            );
            _habits[i] = updatedHabit;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool _shouldResetForFrequency(Habit habit, DateTime today) {
    switch (habit.frequency) {
      case 'weekly':
        return today.weekday == DateTime.monday;
      case 'custom':
        return habit.customDays?.contains(today.weekday) ?? false;
      default:
        return true;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> deleteHabit(int id) async {
    try {
      await _repository.deleteHabit(id);
      _habits.removeWhere((h) => h.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<HabitLog>> getHabitHistory(int habitId) async {
    return await _repository.getHabitLogs(habitId);
  }
}
