import 'package:shared_preferences/shared_preferences.dart';

class UserFlagsService {
  static const _kChecklistPromptSeen = 'checklist_prompt_seen';
  static const _kOnboardingCompleted = 'onboarding_completed';
  static const _kIsAdminUser = 'is_admin_user';
  static const _kIsTestingUser = 'is_testing_user';

  /// Returns `true` if the welcome prompt has already been shown.
  static Future<bool> hasSeenChecklistPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kChecklistPromptSeen) ?? false;
  }

  /// Marks the prompt as shown so we never show it again.
  static Future<void> markChecklistPromptSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kChecklistPromptSeen, true);
  }

  /// Returns `true` if onboarding has been completed.
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingCompleted) ?? false;
  }

  /// Marks onboarding as completed.
  static Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompleted, true);
  }

  /// Check if user is an admin (can bypass signup requirements)
  static Future<bool> isAdminUser() async {
    final prefs = await SharedPreferences.getInstance();
    // Only check local flag - debug mode should not automatically grant admin access
    final localFlag = prefs.getBool(_kIsAdminUser) ?? false;
    return localFlag;
  }

  /// Set admin user flag
  static Future<void> setAdminUser(bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsAdminUser, isAdmin);
  }

  /// Check if user is in testing mode (can bypass signup requirements)
  static Future<bool> isTestingUser() async {
    final prefs = await SharedPreferences.getInstance();
    // Check both local flag and environment variable
    final localFlag = prefs.getBool(_kIsTestingUser) ?? false;
    const envFlag = bool.fromEnvironment('TESTING_MODE', defaultValue: false);
    return localFlag || envFlag;
  }

  /// Set testing user flag
  static Future<void> setTestingUser(bool isTesting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsTestingUser, isTesting);
  }

  /// Check if user can bypass signup requirements (admin or testing)
  static Future<bool> canBypassSignup() async {
    final isAdmin = await isAdminUser();
    final isTesting = await isTestingUser();
    return isAdmin || isTesting;
  }

  /// Reset all flags (for testing purposes)
  static Future<void> resetAllFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kChecklistPromptSeen);
    await prefs.remove(_kOnboardingCompleted);
    await prefs.remove(_kIsAdminUser);
    await prefs.remove(_kIsTestingUser);
  }
}
