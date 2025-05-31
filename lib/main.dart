import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/dashboard_page.dart';
import 'pages/progress_page.dart';
import 'pages/onboarding/welcome_screen.dart';
import 'pages/onboarding/auth_screen.dart';
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
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await FirebaseService.initialize();

  // Only enable in debug mode
  if (kDebugMode) {
    debugPrintRebuildDirtyWidgets = true;
    debugProfileBuildsEnabled = true;
  }

  runApp(const MyApp());
}

// GoRouter configuration
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
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
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressPage(),
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
