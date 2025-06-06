// lib/services/checklist_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checklist_item.dart';
import '../models/habit_item.dart';
import 'firebase_service.dart';
import '../data/sample_habits.dart';
import 'habit_scheduling_service.dart';
import '../models/scheduled_habit.dart';

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

    // NEW - Enhanced checklist generation with scheduled habits
    return await _generateNewChecklistWithSchedules();
  }

  /// NEW - Enhanced checklist generation that includes scheduled habits
  Future<List<ChecklistItem>> _generateNewChecklistWithSchedules() async {
    await initialize();

    final checklistItems = <ChecklistItem>[];

    // 1. Get scheduled habits for today (highest priority)
    try {
      final todaysScheduledHabits = await HabitSchedulingService.instance.getTodaysScheduledHabits();

      // Convert scheduled habits to checklist items with priority boost
      for (final scheduledHabit in todaysScheduledHabits) {
        final item = ChecklistItem.fromSunnahHabit(scheduledHabit.habit);
        checklistItems.add(item);
      }

      print('ChecklistService: Added ${todaysScheduledHabits.length} scheduled habits to checklist');
    } catch (e) {
      print('ChecklistService: Error loading scheduled habits - $e');
    }

    // 2. Fill remaining slots with regular habits (if we have less than 3 items)
    final remainingSlots = 3 - checklistItems.length;
    if (remainingSlots > 0) {
      final regularHabits = await _generateRegularHabits(remainingSlots, checklistItems);
      checklistItems.addAll(regularHabits);
    }

    // 3. Sort by priority (scheduled habits already have boosted priority)
    checklistItems.sort((a, b) => b.priority.compareTo(a.priority));

    // 4. Ensure we have exactly 3 items (trim if necessary)
    final finalItems = checklistItems.take(3).toList();

    // Save to storage
    await _saveChecklist(finalItems);

    // Mark as generated for today
    final todayString = _formatDate(DateTime.now());
    await _prefs!.setString(_lastGeneratedKey, todayString);

    print('ChecklistService: Generated checklist with ${finalItems.length} items');
    return finalItems;
  }

  /// Generate regular habits for checklist (excluding already selected ones)
  Future<List<ChecklistItem>> _generateRegularHabits(int count, List<ChecklistItem> existingItems) async {
    // Get or create user seed for consistent randomization
    int userSeed = _prefs!.getInt(_userSeedKey) ?? _generateUserSeed();
    await _prefs!.setInt(_userSeedKey, userSeed);

    // Create seeded random generator
    final today = DateTime.now();
    final daysSinceEpoch = today.difference(DateTime(2024, 1, 1)).inDays;
    final dailySeed = userSeed + daysSinceEpoch;
    final random = Random(dailySeed);

    // Get IDs of already selected habits
    final existingIds = existingItems.map((item) => item.id).toSet();

    // Filter available habits (exclude very low priority ones and already selected)
    final availableHabits = sampleHabits
        .where((habit) => habit.priority >= 4 && !existingIds.contains(habit.id))
        .toList();

    // Shuffle and take requested count
    availableHabits.shuffle(random);
    final selectedHabits = availableHabits.take(count).toList();

    // Convert to checklist items
    return selectedHabits
        .map((habit) => ChecklistItem.fromSunnahHabit(habit))
        .toList();
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

      // Log completion to Firebase for persistence
      if (isCompleted) {
        try {
          // Save to Firebase for cross-device sync
          await FirebaseService.saveHabitCompletion(
            habitName: itemId,
            isCompleted: isCompleted,
          );
          print('ChecklistService: Habit completion saved to Firebase: $itemId');
        } catch (e) {
          print('ChecklistService: Failed to save to Firebase, keeping local state: $e');
          // Continue with local state - Firebase sync will retry later
        }
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

    // Save updated lists to local storage
    await _prefs!.setStringList('dashboard_daily_habits', newDaily.toList());
    await _prefs!.setStringList('dashboard_weekly_habits', newWeekly.toList());

    // Also sync to Firestore
    try {
      await FirebaseService.saveUserHabits(
        dailyHabits: newDaily.toList(),
        weeklyHabits: newWeekly.toList(),
      );
      print('ChecklistService.syncCompletedItemsToDashboard: synced to Firestore');
    } catch (e) {
      print('ChecklistService.syncCompletedItemsToDashboard: error syncing to Firestore - $e');
    }

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

    // Also clear user habits from Firestore
    try {
      await FirebaseService.saveUserHabits(
        dailyHabits: [],
        weeklyHabits: [],
      );
      print('ChecklistService.clearAllData: cleared Firestore habits');
    } catch (e) {
      print('ChecklistService.clearAllData: error clearing Firestore habits - $e');
    }

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

  /// Add a habit to the user's habit list (for peer-to-peer coaching)
  Future<void> addHabitToUserList(HabitItem habit, String category) async {
    await initialize();

    final key = category == 'daily' ? 'dashboard_daily_habits' : 'dashboard_weekly_habits';
    final existingJson = _prefs!.getString(key);

    List<HabitItem> existingHabits = [];
    if (existingJson != null) {
      final List<dynamic> decoded = jsonDecode(existingJson);
      existingHabits = decoded.map((item) => HabitItem.fromJson(item)).toList();
    }

    // Check if habit already exists
    final habitExists = existingHabits.any((h) => h.name == habit.name);
    if (!habitExists) {
      existingHabits.add(habit);
      final updatedJson = jsonEncode(existingHabits.map((h) => h.toJson()).toList());
      await _prefs!.setString(key, updatedJson);
      print('ChecklistService.addHabitToUserList: added ${habit.name} to $category habits');
    } else {
      print('ChecklistService.addHabitToUserList: habit ${habit.name} already exists in $category habits');
    }
  }

  /// NEW - Check if a habit is scheduled for today
  Future<bool> isHabitScheduledForToday(String habitId) async {
    try {
      return await HabitSchedulingService.instance.isHabitScheduledForToday(habitId);
    } catch (e) {
      print('ChecklistService.isHabitScheduledForToday: Error checking schedule - $e');
      return false;
    }
  }

  /// NEW - Get scheduled habit information
  Future<ScheduledHabit?> getScheduledHabit(String habitId) async {
    try {
      return await HabitSchedulingService.instance.getScheduledHabit(habitId);
    } catch (e) {
      print('ChecklistService.getScheduledHabit: Error getting scheduled habit - $e');
      return null;
    }
  }
}
