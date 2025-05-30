// test/unit/progress_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunnah_steps/services/progress_service.dart';
import 'package:sunnah_steps/models/streak_data.dart';
import 'package:sunnah_steps/models/heatmap_data.dart';

void main() {
  group('ProgressService Tests', () {
    late ProgressService progressService;

    setUp(() async {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
      progressService = ProgressService.instance;
      await progressService.initialize();
    });

    tearDown(() async {
      // Clean up after each test
      await progressService.resetAllProgress();
    });

    group('Streak Logic Tests', () {
      test('should start with initial streak data', () async {
        final streakData = await progressService.getStreakData();

        expect(streakData.currentStreak, equals(0));
        expect(streakData.longestStreak, equals(0));
        expect(streakData.lastCompletionDate, isNull);
      });

      test('should increment streak on first completion', () async {
        final today = DateTime.now();
        await progressService.recordHabitCompletion('habit1', completionDate: today);

        final streakData = await progressService.getStreakData();

        expect(streakData.currentStreak, equals(1));
        expect(streakData.longestStreak, equals(1));
        expect(streakData.lastCompletionDate?.day, equals(today.day));
      });

      test('should increment streak on consecutive day completion', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        // Complete habit yesterday
        await progressService.recordHabitCompletion('habit1', completionDate: yesterday);

        // Complete habit today
        await progressService.recordHabitCompletion('habit2', completionDate: today);

        final streakData = await progressService.getStreakData();

        expect(streakData.currentStreak, equals(2));
        expect(streakData.longestStreak, equals(2));
      });

      test('should reset streak after missing a day', () async {
        final today = DateTime.now();
        final threeDaysAgo = today.subtract(const Duration(days: 3));

        // Complete habit 3 days ago
        await progressService.recordHabitCompletion('habit1', completionDate: threeDaysAgo);

        // Complete habit today (gap of 2 days)
        await progressService.recordHabitCompletion('habit2', completionDate: today);

        final streakData = await progressService.getStreakData();

        expect(streakData.currentStreak, equals(1)); // Reset to 1
        expect(streakData.longestStreak, equals(1)); // Previous streak was only 1 day
      });

      test('should maintain longest streak record', () async {
        // Use a base date that won't trigger reset logic
        final baseDate = DateTime(2024, 1, 1);

        // Build a 5-day streak
        for (int i = 0; i < 5; i++) {
          final date = baseDate.add(Duration(days: i));
          await progressService.recordHabitCompletion('habit$i', completionDate: date);
        }

        // Skip a day and start new streak
        final futureDate = baseDate.add(const Duration(days: 7)); // Skip 2 days
        await progressService.recordHabitCompletion('habit_new', completionDate: futureDate);

        final streakData = await progressService.getStreakData();

        expect(streakData.currentStreak, equals(1)); // New streak
        expect(streakData.longestStreak, equals(5)); // Previous longest streak
      });

      test('should not change streak for same day completion', () async {
        final today = DateTime.now();

        // Complete first habit today
        await progressService.recordHabitCompletion('habit1', completionDate: today);

        // Complete second habit same day
        await progressService.recordHabitCompletion('habit2', completionDate: today);

        final streakData = await progressService.getStreakData();

        expect(streakData.currentStreak, equals(1)); // Should remain 1
        expect(streakData.longestStreak, equals(1));
      });
    });

    group('Heatmap Data Tests', () {
      test('should start with empty weekly heatmap', () async {
        final heatmapData = await progressService.getWeeklyHeatmapData();

        expect(heatmapData.days.length, equals(7));
        expect(heatmapData.totalCompletions, equals(0));

        for (final day in heatmapData.days) {
          expect(day.completionCount, equals(0));
          expect(day.completedHabitIds, isEmpty);
        }
      });

      test('should record completion in heatmap', () async {
        final today = DateTime.now();
        await progressService.recordHabitCompletion('habit1', completionDate: today);

        final heatmapData = await progressService.getWeeklyHeatmapData();
        final todayData = heatmapData.days.firstWhere((day) => day.isToday);

        expect(todayData.completionCount, equals(1));
        expect(todayData.completedHabitIds, contains('habit1'));
      });

      test('should accumulate multiple completions per day', () async {
        final today = DateTime.now();

        await progressService.recordHabitCompletion('habit1', completionDate: today);
        await progressService.recordHabitCompletion('habit2', completionDate: today);
        await progressService.recordHabitCompletion('habit3', completionDate: today);

        final heatmapData = await progressService.getWeeklyHeatmapData();
        final todayData = heatmapData.days.firstWhere((day) => day.isToday);

        expect(todayData.completionCount, equals(3));
        expect(todayData.completedHabitIds, containsAll(['habit1', 'habit2', 'habit3']));
      });

      test('should not duplicate same habit completion on same day', () async {
        final today = DateTime.now();

        await progressService.recordHabitCompletion('habit1', completionDate: today);
        await progressService.recordHabitCompletion('habit1', completionDate: today); // Duplicate

        final heatmapData = await progressService.getWeeklyHeatmapData();
        final todayData = heatmapData.days.firstWhere((day) => day.isToday);

        expect(todayData.completionCount, equals(1)); // Should remain 1
        expect(todayData.completedHabitIds, equals(['habit1']));
      });

      test('should calculate weekly totals correctly', () async {
        final today = DateTime.now();

        // Add completions across different days
        for (int i = 0; i < 3; i++) {
          final date = today.subtract(Duration(days: i));
          await progressService.recordHabitCompletion('habit$i', completionDate: date);
        }

        final heatmapData = await progressService.getWeeklyHeatmapData();

        expect(heatmapData.totalCompletions, equals(3));
        expect(heatmapData.averageCompletions, closeTo(3.0 / 7.0, 0.01));
      });
    });

    group('Progress Summary Tests', () {
      test('should provide accurate progress summary', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        // Build some progress
        await progressService.recordHabitCompletion('habit1', completionDate: yesterday);
        await progressService.recordHabitCompletion('habit2', completionDate: today);
        await progressService.recordHabitCompletion('habit3', completionDate: today);

        final summary = await progressService.getProgressSummary();

        expect(summary['currentStreak'], equals(2));
        expect(summary['longestStreak'], equals(2));
        expect(summary['todayCompletions'], equals(2));
        expect(summary['weeklyTotal'], equals(3));
        expect(summary['streakEmoji'], isNotNull);
        expect(summary['streakMessage'], isNotNull);
      });
    });

    group('Data Persistence Tests', () {
      test('should persist streak data across service restarts', () async {
        final today = DateTime.now();

        // Record completion
        await progressService.recordHabitCompletion('habit1', completionDate: today);

        // Create new service instance (simulating app restart)
        final newService = ProgressService.instance;
        await newService.initialize();

        final streakData = await newService.getStreakData();

        expect(streakData.currentStreak, equals(1));
        expect(streakData.longestStreak, equals(1));
      });

      test('should persist heatmap data across service restarts', () async {
        final today = DateTime.now();

        // Record completion
        await progressService.recordHabitCompletion('habit1', completionDate: today);

        // Create new service instance (simulating app restart)
        final newService = ProgressService.instance;
        await newService.initialize();

        final heatmapData = await newService.getWeeklyHeatmapData();
        final todayData = heatmapData.days.firstWhere((day) => day.isToday);

        expect(todayData.completionCount, equals(1));
        expect(todayData.completedHabitIds, contains('habit1'));
      });
    });

    group('Edge Cases Tests', () {
      test('should handle completion removal', () async {
        final today = DateTime.now();

        // Add and then remove completion
        await progressService.recordHabitCompletion('habit1', completionDate: today);
        await progressService.removeHabitCompletion('habit1', completionDate: today);

        final heatmapData = await progressService.getWeeklyHeatmapData();
        final todayData = heatmapData.days.firstWhere((day) => day.isToday);

        expect(todayData.completionCount, equals(0));
        expect(todayData.completedHabitIds, isEmpty);
      });

      test('should handle data reset', () async {
        final today = DateTime.now();

        // Build some progress
        await progressService.recordHabitCompletion('habit1', completionDate: today);

        // Reset all data
        await progressService.resetAllProgress();

        final streakData = await progressService.getStreakData();
        final heatmapData = await progressService.getWeeklyHeatmapData();

        expect(streakData.currentStreak, equals(0));
        expect(heatmapData.totalCompletions, equals(0));
      });
    });
  });
}
