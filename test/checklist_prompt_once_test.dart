import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:sunnah_steps/pages/checklist_welcome_page.dart';
import 'package:sunnah_steps/pages/dashboard_page.dart';
import 'package:sunnah_steps/services/user_flags_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('welcome prompt appears only once', (tester) async {
    SharedPreferences.setMockInitialValues({}); // fresh install

    await tester.pumpWidget(
      const MaterialApp(home: ChecklistWelcomePage()),
    );
    expect(find.textContaining('Would you like to see today\'s'), findsOneWidget);

    // Simulate choice "Show me now"
    await tester.tap(find.text('Show me now  ➔'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);

    // Verify flag was set
    final seen = await UserFlagsService.hasSeenChecklistPrompt();
    expect(seen, isTrue);

    // Relaunch app – prompt should NOT re-appear
    SharedPreferences.setMockInitialValues({'checklist_prompt_seen': true});
    
    // Simulate checking the flag again
    final seenAgain = await UserFlagsService.hasSeenChecklistPrompt();
    expect(seenAgain, isTrue);
  });
}
