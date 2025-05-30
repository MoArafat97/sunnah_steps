import '../models/sunnah_habit.dart';
import '../models/place.dart';

/// Service for matching habits to user context (location, time, etc.)
class ContextMatchingService {
  /// Get habits that are relevant for the current context
  static List<SunnahHabit> getContextualHabits({
    required List<SunnahHabit> allHabits,
    Place? currentPlace,
    DateTime? currentTime,
    List<String>? userPreferences,
  }) {
    final contextualHabits = <SunnahHabit>[];
    final now = currentTime ?? DateTime.now();

    for (final habit in allHabits) {
      if (_isHabitRelevantForContext(
        habit: habit,
        currentPlace: currentPlace,
        currentTime: now,
        userPreferences: userPreferences,
      )) {
        contextualHabits.add(habit);
      }
    }

    // Sort by priority and relevance
    contextualHabits.sort((a, b) {
      // Higher priority first
      if (a.priority != b.priority) return b.priority.compareTo(a.priority);

      // Then by name
      return a.title.compareTo(b.title);
    });

    return contextualHabits;
  }

  /// Check if a habit is relevant for the current context
  static bool _isHabitRelevantForContext({
    required SunnahHabit habit,
    Place? currentPlace,
    required DateTime currentTime,
    List<String>? userPreferences,
  }) {
    // Time-based filtering
    if (!_isHabitRelevantForTime(habit, currentTime)) {
      return false;
    }

    // Location-based filtering
    if (!_isHabitRelevantForPlace(habit, currentPlace)) {
      return false;
    }

    // User preference filtering
    if (!_isHabitRelevantForPreferences(habit, userPreferences)) {
      return false;
    }

    return true;
  }

  /// Check if habit is relevant for current time
  static bool _isHabitRelevantForTime(SunnahHabit habit, DateTime currentTime) {
    final hour = currentTime.hour;

    // Morning habits (Fajr to Dhuhr)
    if (habit.tags.contains('morning') && (hour >= 5 && hour < 12)) {
      return true;
    }

    // Evening habits (Maghrib to Isha)
    if (habit.tags.contains('evening') && (hour >= 18 && hour < 21)) {
      return true;
    }

    // Night habits (Isha to Fajr)
    if (habit.tags.contains('night') && (hour >= 21 || hour < 5)) {
      return true;
    }

    // Prayer time habits
    if (habit.category == 'prayer') {
      return true; // Always show prayer-related habits
    }

    // Default: show all habits that don't have specific time constraints
    if (!habit.tags.any((tag) => ['morning', 'evening', 'night'].contains(tag))) {
      return true;
    }

    return false;
  }

  /// Check if habit is relevant for current place
  static bool _isHabitRelevantForPlace(SunnahHabit habit, Place? currentPlace) {
    if (currentPlace == null) return true;

    // Mosque-specific habits
    if (currentPlace.type == 'mosque') {
      return habit.tags.contains('mosque') ||
             habit.category == 'prayer' ||
             habit.category == 'dhikr';
    }

    // Home-specific habits
    if (currentPlace.type == 'home') {
      return !habit.tags.contains('public_only');
    }

    // Work-specific habits
    if (currentPlace.type == 'work') {
      return habit.tags.contains('work') ||
             habit.tags.contains('silent') ||
             habit.category == 'dhikr';
    }

    return true;
  }

  /// Check if habit matches user preferences
  static bool _isHabitRelevantForPreferences(SunnahHabit habit, List<String>? userPreferences) {
    if (userPreferences == null || userPreferences.isEmpty) return true;

    // Check if habit category or tags match user preferences
    return userPreferences.contains(habit.category) ||
           habit.tags.any((tag) => userPreferences.contains(tag));
  }

  /// Get priority score for sorting
  static int getPriorityScore(SunnahHabit habit) {
    return habit.priority;
  }

  /// Get habit priority level for display
  static String getHabitPriorityLevel(SunnahHabit habit) {
    if (habit.priority >= 8) return 'Fard';
    if (habit.priority >= 5) return 'Recommended';
    return 'Optional';
  }
}
