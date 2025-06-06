import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sunnah_steps/pages/onboarding/auth_screen.dart';
import 'package:sunnah_steps/pages/onboarding/signup_screen.dart';

void main() {
  group('Navigation Tests', () {
    testWidgets('Auth screen navigates to signup screen when Create Account is tapped', (tester) async {
      // Create a simple router for testing
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/auth',
            builder: (context, state) => const AuthScreen(),
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) => const SignupScreen(),
          ),
        ],
        initialLocation: '/auth',
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the auth screen
      expect(find.text('Welcome Back'), findsOneWidget);

      // Tap the "Create Account" button to navigate to signup
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Verify we're now on the signup screen
      expect(find.text('SIGN UP'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
    });

    testWidgets('Signup screen has back button that returns to auth screen', (tester) async {
      // Create a simple router for testing
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/auth',
            builder: (context, state) => const AuthScreen(),
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) => const SignupScreen(),
          ),
        ],
        initialLocation: '/signup',
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the signup screen
      expect(find.text('SIGN UP'), findsOneWidget);

      // Tap the back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're back on the auth screen
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('Signup screen displays new design elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SignupScreen()),
      );

      await tester.pumpAndSettle();

      // Check for new design elements
      expect(find.text('SIGN UP'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(find.text('AGREE TO TERMS AND SERVICES'), findsOneWidget);
      
      // Check for all 7 required fields
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Birthday'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Check background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF5F3EE));
    });
  });
}
