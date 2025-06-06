import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/dashboard_page.dart';
import 'pages/progress_page.dart';
import 'pages/onboarding/onboarding_flow.dart';
import 'pages/onboarding/auth_screen.dart';
// Removed separate signup screen - now integrated into auth screen
import 'pages/onboarding/intro_screen.dart';
import 'pages/onboarding/micro_lesson_screen.dart';
import 'pages/onboarding/age_question_screen.dart';
import 'pages/onboarding/closeness_question_screen.dart';
import 'pages/onboarding/struggle_question_screen.dart';
import 'pages/onboarding/frequency_question_screen.dart';
import 'pages/onboarding/limited_frequency_screen.dart';
import 'pages/onboarding/high_frequency_screen.dart';
import 'pages/onboarding/gender_question_screen.dart';
import 'pages/onboarding/loading_screen.dart';
import 'pages/onboarding/rich_comparison_screen.dart';
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
        return '/signup';
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
    } else if (isAuthenticated && !hasCompletedOnboarding) {
      // User is signed in but hasn't completed onboarding → continue onboarding
      return '/intro';
    } else {
      // User is not signed in → start with welcome screen (no redirect)
      return null;
    }
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const OnboardingFlow(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    // Removed separate signup route - now integrated into auth screen
    GoRoute(
      path: '/intro',
      builder: (context, state) => const IntroScreen(),
    ),
    GoRoute(
      path: '/onboarding/micro-lessons',
      builder: (context, state) => const MicroLessonScreen(),
    ),
    GoRoute(
      path: '/onboarding/age',
      builder: (context, state) => const AgeQuestionScreen(),
    ),
    GoRoute(
      path: '/onboarding/closeness',
      builder: (context, state) => const ClosenessQuestionScreen(),
    ),
    GoRoute(
      path: '/onboarding/struggle',
      builder: (context, state) => const StruggleQuestionScreen(),
    ),
    GoRoute(
      path: '/onboarding/frequency',
      builder: (context, state) => const FrequencyQuestionScreen(),
    ),
    GoRoute(
      path: '/onboarding/frequency_limited',
      builder: (context, state) => const LimitedFrequencyScreen(),
    ),
    GoRoute(
      path: '/onboarding/frequency_high',
      builder: (context, state) => const HighFrequencyScreen(),
    ),
    GoRoute(
      path: '/onboarding/gender',
      builder: (context, state) => const GenderQuestionScreen(),
    ),
    GoRoute(
      path: '/onboarding/comparison',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/onboarding/rich-comparison/loading',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/onboarding/rich-comparison',
      builder: (context, state) => const RichComparisonScreen(),
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
