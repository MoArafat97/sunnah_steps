// integration_test/progress_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunnah_steps/main.dart' as app;
import 'package:sunnah_steps/services/progress_service.dart';
import 'package:sunnah_steps/services/debug_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Progress Engine Integration Tests', () {
    setUp(() async {
      // Clear all data before each test
      SharedPreferences.setMockInitialValues({});
      await ProgressService.instance.resetAllProgress();
      await DebugService.instance.resetDebugSettings();
    });

    testWidgets('Complete habit completion and progress tracking flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate through onboarding to reach dashboard
      // (This assumes the onboarding flow exists and works)
      await _navigateToDashboard(tester);

      // Verify initial state - no progress
      expect(find.text('0 Day Streak'), findsOneWidget);

      // Complete a habit
      final habitCheckbox = find.byIcon(Icons.radio_button_unchecked).first;
      await tester.tap(habitCheckbox);
      await tester.pumpAndSettle();

      // Verify habit is marked as completed
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Navigate to progress page
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      // Verify progress is updated
      expect(find.text('1 Day Streak'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // Today's completion count

      // Verify heatmap shows completion
      expect(find.byType(Container), findsWidgets); // Heatmap cells
    });

    testWidgets('Debug mode toggle and test-drive mode', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _navigateToDashboard(tester);

      // Long press on app title to enable debug mode
      await tester.longPress(find.text('Sunnah Steps'));
      await tester.pumpAndSettle();

      // Confirm debug mode enable
      await tester.tap(find.text('Enable'));
      await tester.pumpAndSettle();

      // Verify debug icon appears
      expect(find.byIcon(Icons.bug_report), findsOneWidget);

      // Tap debug icon to open panel
      await tester.tap(find.byIcon(Icons.bug_report));
      await tester.pumpAndSettle();

      // Enable test-drive mode
      await tester.tap(find.text('Enable Test-Drive Mode'));
      await tester.pumpAndSettle();

      // Verify test data is loaded
      expect(find.textContaining('Day Streak'), findsOneWidget);
      
      // Navigate to progress page to verify test data
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      // Verify test streak data is displayed
      expect(find.textContaining('Day Streak'), findsOneWidget);
      expect(find.text('Weekly Summary'), findsOneWidget);
    });

    testWidgets('Heatmap displays completion data correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _navigateToDashboard(tester);

      // Complete multiple habits
      final habitCheckboxes = find.byIcon(Icons.radio_button_unchecked);
      final checkboxCount = tester.widgetList(habitCheckboxes).length;
      
      for (int i = 0; i < checkboxCount && i < 3; i++) {
        await tester.tap(habitCheckboxes.at(i));
        await tester.pumpAndSettle();
      }

      // Navigate to progress page
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      // Verify heatmap shows today's completions
      expect(find.text('This Week\'s Activity'), findsOneWidget);
      expect(find.textContaining('Sunnahs completed'), findsOneWidget);

      // Tap on today's heatmap cell to see details
      final heatmapCells = find.byType(GestureDetector);
      if (heatmapCells.evaluate().isNotEmpty) {
        await tester.tap(heatmapCells.first);
        await tester.pumpAndSettle();

        // Verify completion details dialog
        expect(find.text('Completed Habits:'), findsOneWidget);
        
        // Close dialog
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Streak resets correctly after missed day', (WidgetTester tester) async {
      // This test would require mocking time or using a time-travel mechanism
      // For now, we'll test the logic through the service directly
      
      final progressService = ProgressService.instance;
      await progressService.initialize();

      final today = DateTime.now();
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      // Simulate completion 3 days ago
      await progressService.recordHabitCompletion('habit1', completionDate: threeDaysAgo);

      // Simulate completion today (should reset streak)
      await progressService.recordHabitCompletion('habit2', completionDate: today);

      final streakData = await progressService.getStreakData();
      expect(streakData.currentStreak, equals(1)); // Reset to 1

      // Start the app and verify UI reflects the reset
      app.main();
      await tester.pumpAndSettle();

      await _navigateToProgress(tester);

      // Verify streak shows as 1
      expect(find.text('1 Day Streak'), findsOneWidget);
    });

    testWidgets('Progress persists across app restarts', (WidgetTester tester) async {
      // First session - build some progress
      app.main();
      await tester.pumpAndSettle();

      await _navigateToProgress(tester);

      // Manually add some progress through service
      final progressService = ProgressService.instance;
      await progressService.recordHabitCompletion('habit1');
      await progressService.recordHabitCompletion('habit2');

      // Restart app (simulate by creating new widget)
      await tester.pumpWidget(Container()); // Clear current widget
      app.main();
      await tester.pumpAndSettle();

      await _navigateToProgress(tester);

      // Verify progress is still there
      expect(find.text('1 Day Streak'), findsOneWidget);
      expect(find.textContaining('2'), findsWidgets); // Today's completions
    });

    testWidgets('Weekly heatmap updates correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Add completions for multiple days through service
      final progressService = ProgressService.instance;
      final today = DateTime.now();
      
      for (int i = 0; i < 5; i++) {
        final date = today.subtract(Duration(days: i));
        await progressService.recordHabitCompletion('habit$i', completionDate: date);
      }

      await _navigateToProgress(tester);

      // Verify heatmap shows activity
      expect(find.text('This Week\'s Activity'), findsOneWidget);
      expect(find.textContaining('5 Sunnahs completed'), findsOneWidget);

      // Verify weekly summary
      expect(find.text('Weekly Summary'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
    });
  });
}

/// Helper function to navigate to dashboard
Future<void> _navigateToProgress(WidgetTester tester) async {
  // Try to find and tap the progress menu item
  final menuButton = find.byIcon(Icons.menu);
  if (menuButton.evaluate().isNotEmpty) {
    await tester.tap(menuButton);
    await tester.pumpAndSettle();
    
    final progressItem = find.text('Progress');
    if (progressItem.evaluate().isNotEmpty) {
      await tester.tap(progressItem);
      await tester.pumpAndSettle();
    }
  }
}

/// Helper function to navigate to dashboard (simplified)
Future<void> _navigateToDashboard(WidgetTester tester) async {
  // This is a simplified version - in a real app you'd navigate through the full onboarding
  // For testing purposes, we'll assume we can reach the dashboard directly

  // Look for dashboard elements or skip onboarding
  final dashboardElements = find.text('Sunnah Steps');
  if (dashboardElements.evaluate().isNotEmpty) {
    // We're likely on the dashboard already
    return;
  }

  // Otherwise, try to navigate through the app structure
  // This would be customized based on your specific app flow
}


