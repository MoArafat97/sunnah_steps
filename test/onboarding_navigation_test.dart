import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunnah_steps/pages/onboarding/micro_lesson_screen.dart';
import 'package:sunnah_steps/pages/checklist_welcome_page.dart';
import 'package:sunnah_steps/pages/dashboard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Navigation Tests', () {
    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Complete Onboarding button navigates correctly for first-time user', (tester) async {
      // Ensure this is a fresh install
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(
        const MaterialApp(home: MicroLessonScreen()),
      );
      
      // Wait for the screen to load
      await tester.pumpAndSettle();
      
      // Navigate to the last page by tapping Continue multiple times
      while (find.text('Complete Onboarding').evaluate().isEmpty) {
        final continueButton = find.text('Continue');
        if (continueButton.evaluate().isNotEmpty) {
          await tester.tap(continueButton);
          await tester.pumpAndSettle();
        } else {
          break; // No more Continue buttons, we should be on the last page
        }
      }
      
      // Verify we're on the last page with "Complete Onboarding" button
      expect(find.text('Complete Onboarding'), findsOneWidget);
      
      // Tap "Complete Onboarding"
      await tester.tap(find.text('Complete Onboarding'));
      await tester.pumpAndSettle();
      
      // Should navigate to ChecklistWelcomePage for first-time users
      expect(find.byType(ChecklistWelcomePage), findsOneWidget);
      expect(find.text('🎉  Welcome aboard!'), findsOneWidget);
    });

    testWidgets('Skip button navigates correctly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(
        const MaterialApp(home: MicroLessonScreen()),
      );
      
      await tester.pumpAndSettle();
      
      // Find and tap the Skip button
      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      
      // Should navigate to ChecklistWelcomePage
      expect(find.byType(ChecklistWelcomePage), findsOneWidget);
    });

    testWidgets('Complete Onboarding navigates to dashboard for returning user', (tester) async {
      // Simulate user who has already seen the prompt
      SharedPreferences.setMockInitialValues({'checklist_prompt_seen': true});
      
      await tester.pumpWidget(
        const MaterialApp(home: MicroLessonScreen()),
      );
      
      await tester.pumpAndSettle();
      
      // Navigate to last page and complete onboarding
      while (find.text('Complete Onboarding').evaluate().isEmpty) {
        final continueButton = find.text('Continue');
        if (continueButton.evaluate().isNotEmpty) {
          await tester.tap(continueButton);
          await tester.pumpAndSettle();
        } else {
          break;
        }
      }
      
      await tester.tap(find.text('Complete Onboarding'));
      await tester.pumpAndSettle();
      
      // Should go directly to DashboardPage for returning users
      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.byType(ChecklistWelcomePage), findsNothing);
    });
  });
}
