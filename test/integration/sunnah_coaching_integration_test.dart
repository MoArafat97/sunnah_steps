import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../lib/services/sunnah_coaching_service.dart';
import '../../lib/services/checklist_service.dart';
import '../../lib/models/sent_sunnah.dart';
import '../../lib/models/habit_item.dart';
import '../../lib/pages/inbox_page.dart';
import '../../lib/widgets/send_sunnah_dialog.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sunnah Coaching Integration Tests', () {

    testWidgets('should display send Sunnah dialog correctly', (WidgetTester tester) async {
      // Build the dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSendSunnahDialog(
                  context,
                  habitId: 'habit123',
                  habitTitle: 'Read Quran daily',
                ),
                child: const Text('Send to Friend'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show dialog
      await tester.tap(find.text('Send to Friend'));
      await tester.pumpAndSettle();

      // Verify dialog elements are displayed
      expect(find.text('Send to Friend'), findsWidgets); // Title and button
      expect(find.text('Read Quran daily'), findsOneWidget);
      expect(find.text('Friend\'s Email'), findsOneWidget);
      expect(find.text('Personal Message (Optional)'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });

    testWidgets('should validate email input in send dialog', (WidgetTester tester) async {
      // Build the dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSendSunnahDialog(
                  context,
                  habitId: 'habit123',
                  habitTitle: 'Morning Adhkar',
                ),
                child: const Text('Send to Friend'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Send to Friend'));
      await tester.pumpAndSettle();

      // Try to send without email
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter an email address'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter their email address'),
        'invalid-email',
      );
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should show inbox page with proper structure', (WidgetTester tester) async {
      // Build the inbox page
      await tester.pumpWidget(
        const MaterialApp(
          home: InboxPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar is displayed
      expect(find.text('Sunnah Inbox'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    group('Service Integration Tests', () {
      test('should create SunnahCoachingService instance', () {
        // Arrange & Act
        final service1 = SunnahCoachingService.instance;
        final service2 = SunnahCoachingService.instance;

        // Assert - should be singleton
        expect(service1, same(service2));
      });

      test('should create ChecklistService instance', () {
        // Arrange & Act
        final service1 = ChecklistService.instance;
        final service2 = ChecklistService.instance;

        // Assert - should be singleton
        expect(service1, same(service2));
      });

      test('should handle habit item operations', () async {
        // Arrange
        final checklistService = ChecklistService.instance;
        final testHabit = HabitItem(
          name: 'Test Sunnah Habit',
          completed: false,
        );

        // Act & Assert - should not throw
        expect(
          () => checklistService.addHabitToUserList(testHabit, 'daily'),
          returnsNormally,
        );
      });

      test('should validate SentSunnah model operations', () {
        // Arrange
        final testSunnah = SentSunnah(
          id: 'test123',
          senderId: 'sender456',
          recipientId: 'recipient789',
          habitId: 'habit123',
          habitTitle: 'Test Habit',
          note: 'Test note',
          status: 'pending',
          timestamp: DateTime.now(),
          senderEmail: 'test@example.com',
        );

        // Act
        final firestoreData = testSunnah.toFirestore();
        final copiedSunnah = testSunnah.copyWith(status: 'accepted');

        // Assert
        expect(firestoreData, isA<Map<String, dynamic>>());
        expect(firestoreData['status'], equals('pending'));
        expect(copiedSunnah.status, equals('accepted'));
        expect(copiedSunnah.habitTitle, equals('Test Habit')); // Unchanged
      });
    });
  });
}
