// lib/services/checklist_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checklist_item.dart';
import '../data/sample_habits.dart';

/// Service for managing the daily checklist state and persistence
class ChecklistService {
  static const String _checklistKey = 'daily_checklist';
  static const String _lastGeneratedKey = 'checklist_last_generated';
  static const String _hasShownTodayKey = 'checklist_shown_today';
  static const String _hasShownPostOnboardingKey = 'checklist_shown_post_onboarding';
  static const String _userSeedKey = 'user_seed';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  static ChecklistService? _instance;
  static ChecklistService get instance => _instance ??= ChecklistService._();
  ChecklistService._();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if checklist should be shown today
  Future<bool> shouldShowChecklist() async {
    await initialize();

    final today = DateTime.now();
    final todayString = _formatDate(today);
    final lastShown = _prefs!.getString(_hasShownTodayKey);
    final onboardingCompleted = _prefs!.getBool(_onboardingCompletedKey) ?? false;

    // Debug logging
    print('ChecklistService.shouldShowChecklist: today=$todayString, lastShown=$lastShown, onboardingCompleted=$onboardingCompleted');

    // Show if onboarding is completed and not shown today
    final shouldShow = onboardingCompleted && (lastShown != todayString);
    print('ChecklistService.shouldShowChecklist: returning $shouldShow');
    return shouldShow;
  }

  /// Check if checklist should be shown immediately after onboarding completion
  /// This is a special case that bypasses the daily check
  Future<bool> shouldShowChecklistAfterOnboarding() async {
    await initialize();

    final onboardingCompleted = _prefs!.getBool(_onboardingCompletedKey) ?? false;
    final hasShownPostOnboarding = _prefs!.getBool(_hasShownPostOnboardingKey) ?? false;

    // Debug logging
    print('ChecklistService.shouldShowChecklistAfterOnboarding: onboardingCompleted=$onboardingCompleted, hasShownPostOnboarding=$hasShownPostOnboarding');

    // Show if onboarding is completed and post-onboarding checklist has never been shown
    final shouldShow = onboardingCompleted && !hasShownPostOnboarding;
    print('ChecklistService.shouldShowChecklistAfterOnboarding: returning $shouldShow');
    return shouldShow;
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    await initialize();
    await _prefs!.setBool(_onboardingCompletedKey, true);
    print('ChecklistService.markOnboardingCompleted: onboarding marked as completed');
  }

  /// Mark checklist as shown for today
  Future<void> markChecklistShown() async {
    await initialize();
    final today = DateTime.now();
    final todayString = _formatDate(today);
    await _prefs!.setString(_hasShownTodayKey, todayString);
  }

  /// Mark post-onboarding checklist as shown (one-time flag)
  Future<void> markPostOnboardingChecklistShown() async {
    await initialize();
    await _prefs!.setBool(_hasShownPostOnboardingKey, true);
    print('ChecklistService.markPostOnboardingChecklistShown: post-onboarding checklist marked as shown');
  }

  /// Get today's checklist items (generate if needed)
  Future<List<ChecklistItem>> getTodaysChecklist() async {
    await initialize();

    final today = DateTime.now();
    final todayString = _formatDate(today);
    final lastGenerated = _prefs!.getString(_lastGeneratedKey);

    // Check if we need to generate new checklist for today
    if (lastGenerated != todayString) {
      return await _generateNewChecklist();
    }

    // Load existing checklist
    return await _loadExistingChecklist();
  }

  /// Generate a new checklist for today
  Future<List<ChecklistItem>> _generateNewChecklist() async {
    await initialize();

    // Get or create user seed for consistent randomization
    int userSeed = _prefs!.getInt(_userSeedKey) ?? _generateUserSeed();
    await _prefs!.setInt(_userSeedKey, userSeed);

    // Create seeded random generator
    final today = DateTime.now();
    final daysSinceEpoch = today.difference(DateTime(2024, 1, 1)).inDays;
    final dailySeed = userSeed + daysSinceEpoch;
    final random = Random(dailySeed);

    // Filter available habits (exclude very low priority ones for better experience)
    final availableHabits = sampleHabits.where((habit) => habit.priority >= 4).toList();

    // Shuffle and take 3 unique habits
    availableHabits.shuffle(random);
    final selectedHabits = availableHabits.take(3).toList();

    // Convert to checklist items
    final checklistItems = selectedHabits
        .map((habit) => ChecklistItem.fromSunnahHabit(habit))
        .toList();

    // Save to storage
    await _saveChecklist(checklistItems);

    // Mark as generated for today
    final todayString = _formatDate(today);
    await _prefs!.setString(_lastGeneratedKey, todayString);

    return checklistItems;
  }

  /// Load existing checklist from storage
  Future<List<ChecklistItem>> _loadExistingChecklist() async {
    await initialize();

    final checklistJson = _prefs!.getString(_checklistKey);
    if (checklistJson == null) {
      return await _generateNewChecklist();
    }

    try {
      final List<dynamic> jsonList = json.decode(checklistJson);
      return jsonList
          .map((item) => ChecklistItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, generate new checklist
      return await _generateNewChecklist();
    }
  }

  /// Save checklist to storage
  Future<void> _saveChecklist(List<ChecklistItem> items) async {
    await initialize();

    final jsonList = items.map((item) => item.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await _prefs!.setString(_checklistKey, jsonString);
  }

  /// Update completion status of a checklist item
  Future<void> updateItemCompletion(String itemId, bool isCompleted) async {
    final items = await getTodaysChecklist();
    final itemIndex = items.indexWhere((item) => item.id == itemId);

    if (itemIndex != -1) {
      items[itemIndex] = items[itemIndex].copyWith(isCompleted: isCompleted);
      await _saveChecklist(items);

      // TODO: Replace with direct Firestore operations after removing Cloud Functions
      // Optionally log completion to API
      if (isCompleted) {
        // API calls temporarily disabled - will be replaced with direct Firestore operations
        print('Habit completion logged locally: $itemId');
      }
    }
  }

  /// Get completion statistics for today's checklist
  Future<Map<String, int>> getCompletionStats() async {
    final items = await getTodaysChecklist();
    final completed = items.where((item) => item.isCompleted).length;
    final total = items.length;

    return {
      'completed': completed,
      'total': total,
      'percentage': total > 0 ? ((completed / total) * 100).round() : 0,
    };
  }

  /// Sync completed checklist items to dashboard as active habits
  Future<void> syncCompletedItemsToDashboard(List<ChecklistItem> completedItems) async {
    await initialize();

    print('ChecklistService.syncCompletedItemsToDashboard: syncing ${completedItems.length} completed items');

    // Get existing dashboard habits
    final existingDaily = _prefs!.getStringList('dashboard_daily_habits') ?? [];
    final existingWeekly = _prefs!.getStringList('dashboard_weekly_habits') ?? [];

    print('ChecklistService.syncCompletedItemsToDashboard: existing daily=${existingDaily.length}, weekly=${existingWeekly.length}');

    // Add completed items to appropriate lists based on category
    final newDaily = Set<String>.from(existingDaily);
    final newWeekly = Set<String>.from(existingWeekly);

    for (final item in completedItems) {
      print('ChecklistService.syncCompletedItemsToDashboard: processing item "${item.title}" (category: ${item.category})');
      if (item.category == 'daily' || item.category == 'occasional') {
        newDaily.add(item.title);
      } else if (item.category == 'weekly') {
        newWeekly.add(item.title);
      }
    }

    print('ChecklistService.syncCompletedItemsToDashboard: new daily=${newDaily.length}, weekly=${newWeekly.length}');

    // Save updated lists
    await _prefs!.setStringList('dashboard_daily_habits', newDaily.toList());
    await _prefs!.setStringList('dashboard_weekly_habits', newWeekly.toList());

    print('ChecklistService.syncCompletedItemsToDashboard: sync completed successfully');
  }

  /// Get synced dashboard habits
  Future<Map<String, List<String>>> getSyncedDashboardHabits() async {
    await initialize();

    final daily = _prefs!.getStringList('dashboard_daily_habits') ?? [];
    final weekly = _prefs!.getStringList('dashboard_weekly_habits') ?? [];

    print('ChecklistService.getSyncedDashboardHabits: returning daily=$daily, weekly=$weekly');

    return {
      'daily': daily,
      'weekly': weekly,
    };
  }

  /// Clear all checklist data (for testing/reset)
  Future<void> clearAllData() async {
    await initialize();
    await _prefs!.remove(_checklistKey);
    await _prefs!.remove(_lastGeneratedKey);
    await _prefs!.remove(_hasShownTodayKey);
    await _prefs!.remove(_hasShownPostOnboardingKey);
    await _prefs!.remove(_userSeedKey);
    await _prefs!.remove(_onboardingCompletedKey);
    await _prefs!.remove('dashboard_daily_habits');
    await _prefs!.remove('dashboard_weekly_habits');
    print('ChecklistService.clearAllData: all data cleared');
  }

  /// Force reset checklist to show again (for testing)
  Future<void> forceResetChecklistState() async {
    await initialize();
    await _prefs!.remove(_hasShownTodayKey);
    print('ChecklistService.forceResetChecklistState: checklist state reset');
  }

  /// Force reset onboarding state (for testing)
  Future<void> forceResetOnboardingState() async {
    await initialize();
    await _prefs!.remove(_onboardingCompletedKey);
    await _prefs!.remove(_hasShownTodayKey);
    await _prefs!.remove(_hasShownPostOnboardingKey);
    print('ChecklistService.forceResetOnboardingState: onboarding and checklist state reset');
  }

  /// Generate a unique user seed based on current time
  int _generateUserSeed() {
    return DateTime.now().millisecondsSinceEpoch % 1000000;
  }

  /// Format date as YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
