import 'package:shared_preferences/shared_preferences.dart';

class UserFlagsService {
  static const _kChecklistPromptSeen = 'checklist_prompt_seen';
  static const _kOnboardingCompleted = 'onboarding_completed';

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

  /// Reset all flags (for testing purposes)
  static Future<void> resetAllFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kChecklistPromptSeen);
    await prefs.remove(_kOnboardingCompleted);
  }
}
