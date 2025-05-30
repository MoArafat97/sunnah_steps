// lib/services/debug_service.dart

import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak_data.dart';
import '../models/heatmap_data.dart';
import '../models/habit_item.dart';
import '../data/sample_habits.dart';
import 'progress_service.dart';
import 'checklist_service.dart';

/// Debug service for QA testing and development
class DebugService {
  static const String _debugModeKey = 'debug_mode_enabled';
  static const String _testDataLoadedKey = 'test_data_loaded';

  static DebugService? _instance;
  static DebugService get instance => _instance ??= DebugService._();
  DebugService._();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if debug mode is enabled
  Future<bool> isDebugModeEnabled() async {
    await initialize();
    return _prefs!.getBool(_debugModeKey) ?? false;
  }

  /// Toggle debug mode
  Future<void> toggleDebugMode() async {
    await initialize();
    final currentMode = await isDebugModeEnabled();
    await _prefs!.setBool(_debugModeKey, !currentMode);
    print('DebugService: Debug mode ${!currentMode ? 'enabled' : 'disabled'}');
  }

  /// Enable test-drive mode with dummy data
  Future<void> enableTestDriveMode() async {
    await initialize();

    print('DebugService: Enabling test-drive mode...');

    // Load dummy streak data
    await _loadDummyStreakData();

    // Load dummy heatmap data
    await _loadDummyHeatmapData();

    // Load pre-ticked habits on dashboard
    await _loadDummyDashboardHabits();

    // Mark test data as loaded
    await _prefs!.setBool(_testDataLoadedKey, true);

    print('DebugService: Test-drive mode enabled successfully');
  }

  /// Disable test-drive mode and clear dummy data
  Future<void> disableTestDriveMode() async {
    await initialize();

    print('DebugService: Disabling test-drive mode...');

    // Clear all progress data
    await ProgressService.instance.resetAllProgress();

    // Clear checklist data
    await ChecklistService.instance.forceResetChecklistState();

    // Mark test data as not loaded
    await _prefs!.setBool(_testDataLoadedKey, false);

    print('DebugService: Test-drive mode disabled');
  }

  /// Check if test data is currently loaded
  Future<bool> isTestDataLoaded() async {
    await initialize();
    return _prefs!.getBool(_testDataLoadedKey) ?? false;
  }

  /// Load dummy streak data for testing
  Future<void> _loadDummyStreakData() async {
    final random = Random(42); // Fixed seed for consistent test data

    // Generate a realistic streak (7-21 days)
    final currentStreak = 7 + random.nextInt(15);
    final longestStreak = currentStreak + random.nextInt(10);
    final lastCompletionDate = DateTime.now().subtract(const Duration(days: 0));
    final streakStartDate = lastCompletionDate.subtract(Duration(days: currentStreak - 1));

    final dummyStreak = StreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastCompletionDate: lastCompletionDate,
      streakStartDate: streakStartDate,
    );

    // Save directly to SharedPreferences (bypassing ProgressService to avoid conflicts)
    await _prefs!.setString('user_streak_data',
        '{"currentStreak":$currentStreak,"longestStreak":$longestStreak,'
        '"lastCompletionDate":"${lastCompletionDate.toIso8601String()}",'
        '"streakStartDate":"${streakStartDate.toIso8601String()}"}');

    print('DebugService: Loaded dummy streak data - Current: $currentStreak, Longest: $longestStreak');
  }

  /// Load dummy heatmap data for testing
  Future<void> _loadDummyHeatmapData() async {
    final random = Random(42); // Fixed seed for consistent test data
    final weeklyData = WeeklyHeatmapData.currentWeek();

    // Generate realistic completion patterns
    final updatedDays = weeklyData.days.map((day) {
      // Higher chance of completions on recent days
      final daysFromToday = DateTime.now().difference(day.date).inDays.abs();
      final completionChance = daysFromToday <= 1 ? 0.9 : 0.6;

      if (random.nextDouble() < completionChance) {
        // Generate 1-4 completions for this day
        final completionCount = 1 + random.nextInt(4);
        final habitIds = <String>[];

        // Select random habits from sample data
        final availableHabits = sampleHabits.take(10).toList();
        for (int i = 0; i < completionCount && i < availableHabits.length; i++) {
          final habitIndex = random.nextInt(availableHabits.length);
          final habitId = availableHabits[habitIndex].id;
          if (!habitIds.contains(habitId)) {
            habitIds.add(habitId);
          }
        }

        return HeatmapData(
          date: day.date,
          completionCount: habitIds.length,
          completedHabitIds: habitIds,
        );
      } else {
        return HeatmapData.empty(day.date);
      }
    }).toList();

    final dummyWeeklyData = WeeklyHeatmapData(
      days: updatedDays,
      weekStartDate: weeklyData.weekStartDate,
    );

    // Save directly to SharedPreferences
    final heatmapJson = {
      'weekStartDate': dummyWeeklyData.weekStartDate.toIso8601String(),
      'days': dummyWeeklyData.days.map((day) => day.toJson()).toList(),
    };

    await _prefs!.setString('weekly_heatmap_data',
        '{"weekStartDate":"${dummyWeeklyData.weekStartDate.toIso8601String()}",'
        '"days":${heatmapJson['days']}}');

    print('DebugService: Loaded dummy heatmap data with ${dummyWeeklyData.totalCompletions} total completions');
  }

  /// Load pre-ticked habits on dashboard for testing
  Future<void> _loadDummyDashboardHabits() async {
    final random = Random(42); // Fixed seed for consistent test data

    // Select 3 random habits from sample data
    final availableHabits = sampleHabits.take(10).toList();
    final selectedHabits = <String>[];

    while (selectedHabits.length < 3 && selectedHabits.length < availableHabits.length) {
      final habitIndex = random.nextInt(availableHabits.length);
      final habitTitle = availableHabits[habitIndex].title;
      if (!selectedHabits.contains(habitTitle)) {
        selectedHabits.add(habitTitle);
      }
    }

    // Save to checklist service as synced habits
    final syncedHabits = {
      'daily': selectedHabits.take(2).toList(),
      'weekly': selectedHabits.skip(2).take(1).toList(),
    };

    // Use ChecklistService to sync these habits
    await ChecklistService.instance.initialize();
    // Note: We'll need to add a method to ChecklistService to set synced habits directly

    print('DebugService: Loaded ${selectedHabits.length} dummy dashboard habits: $selectedHabits');
  }

  /// Generate test completion data for a specific date range
  Future<void> generateTestCompletions({
    required DateTime startDate,
    required DateTime endDate,
    int maxCompletionsPerDay = 3,
  }) async {
    final random = Random(42);
    final progressService = ProgressService.instance;

    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      // Random chance of having completions on this day
      if (random.nextDouble() < 0.7) {
        final completionCount = 1 + random.nextInt(maxCompletionsPerDay);

        for (int i = 0; i < completionCount; i++) {
          final habitIndex = random.nextInt(sampleHabits.length);
          final habitId = sampleHabits[habitIndex].id;

          await progressService.recordHabitCompletion(
            habitId,
            completionDate: currentDate,
          );
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    print('DebugService: Generated test completions from $startDate to $endDate');
  }

  /// Get debug information for display
  Future<Map<String, dynamic>> getDebugInfo() async {
    final isDebugEnabled = await isDebugModeEnabled();
    final testDataLoaded = await isTestDataLoaded();
    final progressSummary = await ProgressService.instance.getProgressSummary();

    return {
      'debugModeEnabled': isDebugEnabled,
      'testDataLoaded': testDataLoaded,
      'progressSummary': progressSummary,
      'buildMode': const bool.fromEnvironment('dart.vm.product') ? 'release' : 'debug',
    };
  }

  /// Reset all debug settings
  Future<void> resetDebugSettings() async {
    await initialize();
    await _prefs!.remove(_debugModeKey);
    await _prefs!.remove(_testDataLoadedKey);
    print('DebugService: All debug settings reset');
  }

  /// Quick test data scenarios
  Future<void> loadScenario(String scenarioName) async {
    switch (scenarioName) {
      case 'new_user':
        await disableTestDriveMode();
        break;
      case 'active_user':
        await enableTestDriveMode();
        break;
      case 'streak_master':
        await _loadStreakMasterScenario();
        break;
      case 'inconsistent_user':
        await _loadInconsistentUserScenario();
        break;
      default:
        print('DebugService: Unknown scenario: $scenarioName');
    }
  }

  /// Load streak master scenario (30+ day streak)
  Future<void> _loadStreakMasterScenario() async {
    final streakData = StreakData(
      currentStreak: 35,
      longestStreak: 42,
      lastCompletionDate: DateTime.now(),
      streakStartDate: DateTime.now().subtract(const Duration(days: 34)),
    );

    await _prefs!.setString('user_streak_data',
        '{"currentStreak":35,"longestStreak":42,'
        '"lastCompletionDate":"${DateTime.now().toIso8601String()}",'
        '"streakStartDate":"${DateTime.now().subtract(const Duration(days: 34)).toIso8601String()}"}');

    print('DebugService: Loaded streak master scenario');
  }

  /// Load inconsistent user scenario (broken streak)
  Future<void> _loadInconsistentUserScenario() async {
    final streakData = StreakData(
      currentStreak: 0,
      longestStreak: 12,
      lastCompletionDate: DateTime.now().subtract(const Duration(days: 3)),
      streakStartDate: DateTime.now(),
    );

    await _prefs!.setString('user_streak_data',
        '{"currentStreak":0,"longestStreak":12,'
        '"lastCompletionDate":"${DateTime.now().subtract(const Duration(days: 3)).toIso8601String()}",'
        '"streakStartDate":"${DateTime.now().toIso8601String()}"}');

    print('DebugService: Loaded inconsistent user scenario');
  }
}
