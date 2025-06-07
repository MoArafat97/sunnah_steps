/// Application-wide constants for the Sunnah Steps app
/// This file centralizes all hardcoded values to improve maintainability
/// and make the codebase more configurable for OpenAI Codex improvements.

class AppConstants {
  // App Information
  static const String appName = 'Sunnah Steps';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Track your Sunnah habits and build spiritual consistency';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardPadding = 12.0;
  static const double borderRadius = 12.0;
  static const double elevatedBorderRadius = 20.0;
  static const double cardElevation = 2.0;
  static const double maxCardWidth = 400.0;
  
  // Animation Durations (in milliseconds)
  static const int shortAnimationDuration = 300;
  static const int mediumAnimationDuration = 500;
  static const int longAnimationDuration = 900;
  static const int typewriterDelay = 800;
  static const int autoNavigationDelay = 2500;
  
  // Checklist Configuration
  static const int maxChecklistItems = 3;
  static const int minHabitPriority = 4;
  static const double habitCompletionChance = 0.7;
  static const int maxCompletionsPerDay = 4;
  
  // Progress Tracking
  static const int heatmapDays = 7;
  static const int maxStreakDays = 365;
  static const int progressHistoryDays = 30;
  
  // Debug Configuration
  static const bool enableDebugLogging = true;
  static const bool enablePerformanceLogging = false;
  static const int debugDataSeed = 42;
  
  // Firebase Configuration Keys
  static const String firestoreUsersCollection = 'users';
  static const String firestoreHabitsCollection = 'habits';
  static const String firestoreBundlesCollection = 'bundles';
  static const String firestoreSentSunnahsCollection = 'sent_sunnahs';
  static const String firestoreCompletionsSubcollection = 'habit_completions';
  
  // SharedPreferences Keys
  static const String checklistKey = 'daily_checklist';
  static const String lastGeneratedKey = 'checklist_last_generated';
  static const String hasShownTodayKey = 'checklist_shown_today';
  static const String hasShownPostOnboardingKey = 'checklist_shown_post_onboarding';
  static const String userSeedKey = 'user_seed';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String debugModeKey = 'debug_mode_enabled';
  static const String testDataLoadedKey = 'test_data_loaded';
  static const String isAdminUserKey = 'is_admin_user';
  static const String isTestingUserKey = 'is_testing_user';
  static const String dashboardDailyHabitsKey = 'dashboard_daily_habits';
  static const String dashboardWeeklyHabitsKey = 'dashboard_weekly_habits';
  static const String userStreakDataKey = 'user_streak_data';
  
  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection and try again.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
  static const String firestoreErrorMessage = 'Failed to sync data. Changes saved locally.';
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  
  // Success Messages
  static const String habitCompletedMessage = 'Habit completed! BarakAllahu feekum 🌸';
  static const String dataResetMessage = 'All data has been reset successfully.';
  static const String syncSuccessMessage = 'Data synced successfully.';
  
  // Validation Constants
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxNoteLength = 500;
  static const String emailRegexPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  // Feature Flags
  static const bool enableSocialFeatures = true;
  static const bool enableProgressSharing = true;
  static const bool enableNotifications = true;
  static const bool enableAnalytics = false; // Disabled for privacy
  
  // Environment Configuration
  static const String environmentKey = 'USE_EMULATOR';
  static const String emulatorHost = 'localhost';
  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;
  
  // Date Formatting
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timestampFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  
  // Habit Categories
  static const List<String> habitCategories = ['daily', 'weekly', 'occasional'];
  static const List<String> priorityLevels = ['fard', 'recommended', 'optional'];
  
  // UI Text Constants
  static const String welcomeHeadline = 'Welcome — this is your space, your step. Your Sunnah.';
  static const String onboardingExplanation = 'We\'ll ask you a few questions to personalize your experience.';
  static const String loadingText = 'Loading your spiritual journey...';
  static const String noDataText = 'No data available yet. Start tracking your habits!';
  
  // Asset Paths
  static const String backgroundImagePath = 'assets/images/Sunnah_App_Background.png';
  static const String logoImagePath = 'assets/images/Sunnah_Steps_Logo.png';
  static const String audioAssetsPath = 'assets/sfx/';
  static const String shaderAssetsPath = 'shaders/';
  
  // Font Configuration
  static const String primaryFontFamily = 'Cairo';
  static const double primaryLetterSpacing = 1.2;
  static const double headlineFontSize = 24.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;
  
  // Color Hex Values (for reference)
  static const String creamColorHex = '#F5F3EE';
  static const String brownColorHex = '#8B5E3C';
  static const String darkBackgroundHex = '#04031A';
  static const String goldenAccentHex = '#F5C518';
  static const String primaryTealHex = '#009688';
  
  // Security Configuration
  static const bool enableSecurityLogging = false; // Never log sensitive data
  static const bool requireStrongPasswords = true;
  static const int maxLoginAttempts = 5;
  static const int sessionTimeoutMinutes = 60;
  
  // Performance Configuration
  static const int maxCacheSize = 100; // Maximum number of cached items
  static const int cacheExpirationHours = 24;
  static const bool enableImageCaching = true;
  static const bool enableDataCompression = true;
  
  // Accessibility Configuration
  static const double minTouchTargetSize = 44.0;
  static const double maxTextScaleFactor = 2.0;
  static const bool enableHighContrast = false;
  static const bool enableReducedMotion = false;
}

/// Route names for navigation
class AppRoutes {
  static const String root = '/';
  static const String auth = '/auth';
  static const String dashboard = '/dashboard';
  static const String progress = '/progress';
  static const String inbox = '/inbox';
  static const String checklistWelcome = '/checklist-welcome';
}

/// API endpoints and configuration
class ApiConstants {
  // Note: This app uses direct Firestore SDK, no REST API endpoints
  static const String baseUrl = ''; // Not used - direct Firestore access
  static const int timeoutSeconds = 30;
  static const int retryAttempts = 3;
  static const int retryDelaySeconds = 2;
}
