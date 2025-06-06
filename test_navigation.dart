import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'lib/pages/onboarding/auth_screen.dart';
import 'lib/pages/onboarding/signup_screen.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => TestHomePage(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Navigation Test',
      routerConfig: router,
    );
  }
}

class TestHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Navigation Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/auth'),
              child: Text('Go to Auth Screen'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/signup'),
              child: Text('Go to Signup Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
