// lib/services/progress_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak_data.dart';
import '../models/heatmap_data.dart';

/// Service for managing user progress tracking including streaks and heatmap data
class ProgressService {
  static const String _streakKey = 'user_streak_data';
  static const String _heatmapKey = 'weekly_heatmap_data';
  static const String _lastUpdateKey = 'progress_last_update';

  static ProgressService? _instance;
  static ProgressService get instance => _instance ??= ProgressService._();
  ProgressService._();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get current streak data
  Future<StreakData> getStreakData() async {
    await initialize();

    final streakJson = _prefs!.getString(_streakKey);
    if (streakJson == null) {
      return StreakData.initial();
    }

    try {
      final data = StreakData.fromJson(jsonDecode(streakJson));
      // Only check for reset if the last completion was recent (within a week)
      // This prevents test data from being reset inappropriately
      if (data.lastCompletionDate != null) {
        final daysSinceLastCompletion = DateTime.now().difference(data.lastCompletionDate!).inDays;
        if (daysSinceLastCompletion <= 7) {
          return data.checkForStreakReset();
        }
      }
      return data;
    } catch (e) {
      print('Error loading streak data: $e');
      return StreakData.initial();
    }
  }

  /// Save streak data
  Future<void> _saveStreakData(StreakData streakData) async {
    await initialize();
    await _prefs!.setString(_streakKey, jsonEncode(streakData.toJson()));
  }

  /// Get current week's heatmap data
  Future<WeeklyHeatmapData> getWeeklyHeatmapData() async {
    await initialize();

    final heatmapJson = _prefs!.getString(_heatmapKey);
    if (heatmapJson == null) {
      return WeeklyHeatmapData.currentWeek();
    }

    try {
      final data = jsonDecode(heatmapJson) as Map<String, dynamic>;
      final weekStartDate = DateTime.parse(data['weekStartDate'] as String);
      final daysData = data['days'] as List;

      final days = daysData.map((dayJson) =>
          HeatmapData.fromJson(dayJson as Map<String, dynamic>)).toList();

      return WeeklyHeatmapData(
        days: days,
        weekStartDate: weekStartDate,
      );
    } catch (e) {
      print('Error loading heatmap data: $e');
      return WeeklyHeatmapData.currentWeek();
    }
  }

  /// Save weekly heatmap data
  Future<void> _saveWeeklyHeatmapData(WeeklyHeatmapData heatmapData) async {
    await initialize();

    final data = {
      'weekStartDate': heatmapData.weekStartDate.toIso8601String(),
      'days': heatmapData.days.map((day) => day.toJson()).toList(),
    };

    await _prefs!.setString(_heatmapKey, jsonEncode(data));
  }

  /// Record a habit completion and update progress
  Future<void> recordHabitCompletion(String habitId, {DateTime? completionDate}) async {
    final date = completionDate ?? DateTime.now();

    // Update streak data
    final currentStreak = await getStreakData();
    final updatedStreak = currentStreak.updateWithCompletion(date);
    await _saveStreakData(updatedStreak);

    // Update heatmap data
    await _updateHeatmapForCompletion(habitId, date);

    // Update last update timestamp
    await _updateLastUpdateTime();

    print('ProgressService: Recorded completion for habit $habitId on ${date.toIso8601String().split('T')[0]}');
  }

  /// Update heatmap data for a habit completion
  Future<void> _updateHeatmapForCompletion(String habitId, DateTime date) async {
    final weeklyData = await getWeeklyHeatmapData();

    // Check if the completion date is in the current week
    final completionDay = DateTime(date.year, date.month, date.day);
    final dayIndex = weeklyData.days.indexWhere((day) =>
        day.date.year == completionDay.year &&
        day.date.month == completionDay.month &&
        day.date.day == completionDay.day);

    if (dayIndex != -1) {
      // Update the specific day
      final currentDayData = weeklyData.days[dayIndex];
      final updatedDayData = currentDayData.addCompletion(habitId);
      final updatedWeeklyData = weeklyData.updateDay(completionDay, updatedDayData);
      await _saveWeeklyHeatmapData(updatedWeeklyData);
    } else {
      // Completion is outside current week - might need to handle differently
      print('ProgressService: Completion date $completionDay is outside current week');
    }
  }

  /// Remove a habit completion (for undo functionality)
  Future<void> removeHabitCompletion(String habitId, {DateTime? completionDate}) async {
    final date = completionDate ?? DateTime.now();

    // Update heatmap data
    await _removeHeatmapCompletion(habitId, date);

    // Note: We don't automatically recalculate streaks on removal
    // as this could be complex. Consider implementing if needed.

    print('ProgressService: Removed completion for habit $habitId on ${date.toIso8601String().split('T')[0]}');
  }

  /// Remove heatmap completion
  Future<void> _removeHeatmapCompletion(String habitId, DateTime date) async {
    final weeklyData = await getWeeklyHeatmapData();

    final completionDay = DateTime(date.year, date.month, date.day);
    final dayIndex = weeklyData.days.indexWhere((day) =>
        day.date.year == completionDay.year &&
        day.date.month == completionDay.month &&
        day.date.day == completionDay.day);

    if (dayIndex != -1) {
      final currentDayData = weeklyData.days[dayIndex];
      final updatedDayData = currentDayData.removeCompletion(habitId);
      final updatedWeeklyData = weeklyData.updateDay(completionDay, updatedDayData);
      await _saveWeeklyHeatmapData(updatedWeeklyData);
    }
  }

  /// Check if we have any completions today
  Future<bool> hasCompletionsToday() async {
    final weeklyData = await getWeeklyHeatmapData();
    final today = DateTime.now();
    final todayData = weeklyData.days.firstWhere(
      (day) => day.isToday,
      orElse: () => HeatmapData.empty(today),
    );

    return todayData.completionCount > 0;
  }

  /// Get completion count for today
  Future<int> getTodayCompletionCount() async {
    final weeklyData = await getWeeklyHeatmapData();
    final todayData = weeklyData.days.firstWhere(
      (day) => day.isToday,
      orElse: () => HeatmapData.empty(DateTime.now()),
    );

    return todayData.completionCount;
  }

  /// Update last update timestamp
  Future<void> _updateLastUpdateTime() async {
    await initialize();
    await _prefs!.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  /// Get last update time
  Future<DateTime?> getLastUpdateTime() async {
    await initialize();
    final lastUpdateString = _prefs!.getString(_lastUpdateKey);
    if (lastUpdateString == null) return null;

    try {
      return DateTime.parse(lastUpdateString);
    } catch (e) {
      return null;
    }
  }

  /// Reset all progress data (for testing/debug purposes)
  Future<void> resetAllProgress() async {
    await initialize();
    await _prefs!.remove(_streakKey);
    await _prefs!.remove(_heatmapKey);
    await _prefs!.remove(_lastUpdateKey);
    print('ProgressService: All progress data reset');
  }

  /// Get progress summary for display
  Future<Map<String, dynamic>> getProgressSummary() async {
    final streakData = await getStreakData();
    final weeklyData = await getWeeklyHeatmapData();
    final todayCount = await getTodayCompletionCount();

    return {
      'currentStreak': streakData.currentStreak,
      'longestStreak': streakData.longestStreak,
      'streakMessage': streakData.statusMessage,
      'streakEmoji': streakData.streakEmoji,
      'todayCompletions': todayCount,
      'weeklyTotal': weeklyData.totalCompletions,
      'weeklyAverage': weeklyData.averageCompletions,
      'lastUpdate': await getLastUpdateTime(),
    };
  }
}
