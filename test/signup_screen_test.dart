import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunnah_steps/pages/onboarding/signup_screen.dart';

void main() {
  group('Signup Screen Tests', () {
    testWidgets('Signup screen displays all required fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupScreen()),
      );
      
      // Wait for the screen to load
      await tester.pumpAndSettle();
      
      // Check that the title is displayed
      expect(find.text('SIGN UP'), findsOneWidget);
      
      // Check that all form fields are present
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Birthday'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      
      // Check that terms checkbox is present
      expect(find.text('AGREE TO TERMS AND SERVICES'), findsOneWidget);
      
      // Check that continue button is present
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('Form validation works correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupScreen()),
      );

      await tester.pumpAndSettle();

      // Scroll down to make the continue button visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Try to submit without filling any fields
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('Terms checkbox validation works', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupScreen()),
      );

      await tester.pumpAndSettle();

      // Fill all required fields but don't check terms
      await tester.enterText(find.widgetWithText(TextFormField, 'First Name'), 'John');
      await tester.enterText(find.widgetWithText(TextFormField, 'Last Name'), 'Doe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'john@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Birthday'), '01/01/1990');
      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'johndoe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'password123');

      // Select gender from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      // Scroll down to make the continue button visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Try to submit without checking terms
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Should show terms validation error
      expect(find.text('Please agree to the terms and services to continue'), findsOneWidget);
    });

    testWidgets('Password confirmation validation works', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupScreen()),
      );

      await tester.pumpAndSettle();

      // Enter different passwords
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'differentpassword');

      // Scroll down to make the continue button visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Trigger validation by tapping continue
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Should show password mismatch error
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('UI elements have correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupScreen()),
      );
      
      await tester.pumpAndSettle();
      
      // Check background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF5F3EE));
      
      // Check that title has golden highlight (Stack widget should be present)
      expect(find.byType(Stack), findsWidgets);
      
      // Check that continue button has custom styling
      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);
    });
  });
}
