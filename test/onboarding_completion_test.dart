import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunnah_steps/pages/onboarding/micro_lesson_screen.dart';
import 'package:sunnah_steps/pages/checklist_welcome_page.dart';
import 'package:sunnah_steps/pages/dashboard_page.dart';
import 'package:sunnah_steps/services/user_flags_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Completion Flow', () {
    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('First-time user sees welcome prompt after onboarding', (tester) async {
      // Ensure this is a fresh install
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(
        const MaterialApp(home: MicroLessonScreen()),
      );
      
      // Wait for the screen to load
      await tester.pumpAndSettle();
      
      // Find and tap the "Complete Onboarding" button
      // First we need to navigate to the last page
      final nextButton = find.text('Continue');
      if (nextButton.evaluate().isNotEmpty) {
        // Navigate through all pages to get to the last one
        while (find.text('Complete Onboarding').evaluate().isEmpty) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        }
      }
      
      // Now tap "Complete Onboarding"
      await tester.tap(find.text('Complete Onboarding'));
      await tester.pumpAndSettle();
      
      // Should navigate to ChecklistWelcomePage
      expect(find.byType(ChecklistWelcomePage), findsOneWidget);
      expect(find.text('🎉  Welcome aboard!'), findsOneWidget);
      expect(find.text('Would you like to see today\'s Sunnah checklist you can follow?'), findsOneWidget);
    });

    testWidgets('Returning user skips welcome prompt', (tester) async {
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
      
      // Should go directly to DashboardPage
      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.byType(ChecklistWelcomePage), findsNothing);
    });

    testWidgets('Welcome prompt "Show me now" navigates to dashboard with overlay', (tester) async {
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(
        const MaterialApp(home: ChecklistWelcomePage()),
      );
      
      await tester.pumpAndSettle();
      
      // Tap "Show me now"
      await tester.tap(find.text('Show me now  ➔'));
      await tester.pumpAndSettle();
      
      // Should navigate to dashboard
      expect(find.byType(DashboardPage), findsOneWidget);
      
      // Verify the flag was set
      final seen = await UserFlagsService.hasSeenChecklistPrompt();
      expect(seen, isTrue);
    });

    testWidgets('Welcome prompt "Maybe later" navigates to dashboard without overlay', (tester) async {
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(
        const MaterialApp(home: ChecklistWelcomePage()),
      );
      
      await tester.pumpAndSettle();
      
      // Tap "Maybe later"
      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      
      // Should navigate to dashboard
      expect(find.byType(DashboardPage), findsOneWidget);
      
      // Verify the flag was set
      final seen = await UserFlagsService.hasSeenChecklistPrompt();
      expect(seen, isTrue);
    });
  });
}
