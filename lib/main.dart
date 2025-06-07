import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/dashboard_page.dart';
import 'pages/progress_page.dart';
import 'pages/onboarding/onboarding_flow.dart';
import 'pages/onboarding/auth_screen.dart';
import 'pages/inbox_page.dart';
import 'pages/checklist_welcome_page.dart';
import 'services/firebase_service.dart';
import 'services/user_flags_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await FirebaseService.initialize();

  // Debug mode configuration
  // Note: Excessive debug logging disabled for performance

  runApp(const MyApp());
}

// GoRouter configuration
final GoRouter _router = GoRouter(
  refreshListenable: GoRouterRefreshStream(FirebaseService.authStateChanges),
  redirect: (context, state) async {
    // Check if user is authenticated using the current user
    // Note: This should be reliable after Firebase initialization
    final currentUser = FirebaseService.currentUser;
    final isAuthenticated = currentUser != null;

    // Check if user can bypass signup requirements (admin/testing)
    final canBypass = await UserFlagsService.canBypassSignup();

    // Check if onboarding is completed (from Firestore)
    final hasCompletedOnboarding = await FirebaseService.hasCompletedOnboarding();

    // Handle dashboard access - require authentication unless user can bypass
    if (state.fullPath == '/dashboard') {
      if (!isAuthenticated && !canBypass) {
        // Block dashboard access for unauthenticated users who can't bypass
        return '/auth';
      }
      // Allow access if authenticated or can bypass
      return null;
    }

    // Only redirect from the root path to avoid infinite loops
    if (state.fullPath != '/') {
      return null; // No redirect needed for other paths
    }

    // Routing logic for root path:
    if (isAuthenticated && hasCompletedOnboarding) {
      // User is signed in and has completed onboarding → go to dashboard
      return '/dashboard';
    } else {
      // User is not signed in or hasn't completed onboarding → start with welcome screen (no redirect)
      return null;
    }
  },
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) {
        final pageParam = state.uri.queryParameters['page'];
        final initialPage = pageParam != null ? int.tryParse(pageParam) ?? 0 : 0;

        // Add fade transition when navigating back from auth
        if (initialPage > 0) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: OnboardingFlow(initialPage: initialPage),
            transitionDuration: const Duration(milliseconds: 700),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return Container(
                color: const Color(0xFFF5F3EE), // Ensure cream background during transition
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
          );
        }

        // Default behavior for initial load
        return MaterialPage(
          key: state.pageKey,
          child: OnboardingFlow(initialPage: initialPage),
        );
      },
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return Container(
            color: const Color(0xFFF5F3EE), // Ensure cream background during transition
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: '/checklist-welcome',
      builder: (context, state) => const ChecklistWelcomePage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) {
        final showChecklist = state.uri.queryParameters['showChecklist'] == 'true';
        return DashboardPage(initialChecklistOverlayVisible: showChecklist);
      },
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressPage(),
    ),
    GoRoute(
      path: '/inbox',
      builder: (context, state) => const InboxPage(),
    ),

  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sunnah Steps',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
    );
  }
}

/// A [ChangeNotifier] that refreshes GoRouter when Firebase Auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<User?> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (User? user) {
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
