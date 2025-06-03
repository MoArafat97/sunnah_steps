import 'package:shared_preferences/shared_preferences.dart';

class UserFlagsService {
  static const _kChecklistPromptSeen = 'checklist_prompt_seen';

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
}
