// Tests for Sunnah Steps app

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunnah_steps/data/sunnah_norms.dart';
import 'package:sunnah_steps/models/streak_data.dart';
import 'package:sunnah_steps/models/heatmap_data.dart';
import 'package:sunnah_steps/widgets/weekly_heatmap.dart';
import 'package:sunnah_steps/services/progress_service.dart';
import 'package:sunnah_steps/services/debug_service.dart';

void main() {
  group('Engagement Score Calculations', () {
    test('getEngagementScore returns correct values', () {
      expect(getEngagementScore('Several times a day'), 100);
      expect(getEngagementScore('Once a day'), 80);
      expect(getEngagementScore('Once a week'), 60);
      expect(getEngagementScore('Once a month'), 40);
      expect(getEngagementScore('Rarely'), 20);
      expect(getEngagementScore('Never'), 0);
      expect(getEngagementScore('Invalid'), 0);
    });

    test('getPeerAverageEngagement calculates correctly', () {
      // Test with known data: 18-25 male
      // Several times a day: 10% * 100 = 1000
      // Once a day: 20% * 80 = 1600
      // Once a week: 25% * 60 = 1500
      // Once a month: 25% * 40 = 1000
      // Rarely: 20% * 20 = 400
      // Never: 0% * 0 = 0
      // Total: 5500 / 100 = 55.0

      final result = getPeerAverageEngagement('18-25', 'male');
      expect(result, 55.0);
    });

    test('getPeerAverageEngagement handles invalid data', () {
      expect(getPeerAverageEngagement('invalid', 'male'), 0.0);
      expect(getPeerAverageEngagement('18-25', 'invalid'), 0.0);
    });

    test('getPeerPercentage returns correct values', () {
      expect(getPeerPercentage('18-25', 'male', 'Once a day'), 20);
      expect(getPeerPercentage('25-40', 'female', 'Several times a day'), 20);
      expect(getPeerPercentage('invalid', 'male', 'Once a day'), 0);
    });
  });

  group('Progress Engine Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('WeeklyHeatmap displays correctly', (WidgetTester tester) async {
      // Create test heatmap data
      final testData = WeeklyHeatmapData.currentWeek();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyHeatmap(heatmapData: testData),
          ),
        ),
      );

      // Verify heatmap elements are present
      expect(find.text('This Week\'s Activity'), findsOneWidget);
      expect(find.text('0 Sunnahs completed'), findsOneWidget);
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('WeeklyHeatmap shows completion data', (WidgetTester tester) async {
      // Create test data with completions
      final testData = WeeklyHeatmapData.currentWeek();
      final today = DateTime.now();
      final todayData = HeatmapData(
        date: today,
        completionCount: 3,
        completedHabitIds: ['habit1', 'habit2', 'habit3'],
      );

      final updatedData = testData.updateDay(today, todayData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyHeatmap(heatmapData: updatedData),
          ),
        ),
      );

      // Verify completion count is displayed
      expect(find.text('3 Sunnahs completed'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // In the heatmap cell
    });
  });

  group('Progress Service Integration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ProgressService.instance.resetAllProgress();
    });

    test('ProgressService records and retrieves completions', () async {
      final progressService = ProgressService.instance;
      await progressService.initialize();

      // Record a completion
      await progressService.recordHabitCompletion('test_habit');

      // Verify streak is updated
      final streakData = await progressService.getStreakData();
      expect(streakData.currentStreak, equals(1));

      // Verify today's completion count
      final todayCompletions = await progressService.getTodayCompletionCount();
      expect(todayCompletions, equals(1));
    });

    test('ProgressService handles multiple completions correctly', () async {
      final progressService = ProgressService.instance;
      await progressService.initialize();

      // Record multiple completions
      await progressService.recordHabitCompletion('habit1');
      await progressService.recordHabitCompletion('habit2');
      await progressService.recordHabitCompletion('habit3');

      // Verify counts
      final todayCompletions = await progressService.getTodayCompletionCount();
      expect(todayCompletions, equals(3));

      // Verify streak is still 1 (same day)
      final streakData = await progressService.getStreakData();
      expect(streakData.currentStreak, equals(1));
    });
  });

  group('Debug Service Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DebugService.instance.resetDebugSettings();
    });

    test('DebugService toggles debug mode correctly', () async {
      final debugService = DebugService.instance;
      await debugService.initialize();

      // Initially disabled
      expect(await debugService.isDebugModeEnabled(), isFalse);

      // Toggle on
      await debugService.toggleDebugMode();
      expect(await debugService.isDebugModeEnabled(), isTrue);

      // Toggle off
      await debugService.toggleDebugMode();
      expect(await debugService.isDebugModeEnabled(), isFalse);
    });

    test('DebugService loads test data correctly', () async {
      final debugService = DebugService.instance;
      await debugService.initialize();

      // Enable test-drive mode
      await debugService.enableTestDriveMode();

      // Verify test data is loaded
      expect(await debugService.isTestDataLoaded(), isTrue);

      // Verify progress service has test data
      final progressService = ProgressService.instance;
      final streakData = await progressService.getStreakData();
      expect(streakData.currentStreak, greaterThan(0));
    });
  });
}
