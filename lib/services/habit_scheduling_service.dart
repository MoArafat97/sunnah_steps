import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sunnah_habit.dart';
import '../models/habit_schedule.dart';
import '../models/habit_goal.dart';
import '../models/scheduled_habit.dart';
import '../data/sample_habits.dart';
import 'firebase_service.dart';

/// Service for managing custom habit scheduling and goals
class HabitSchedulingService {
  static const String _scheduledHabitsKey = 'scheduled_habits';
  static const String _activeGoalsKey = 'active_goals';
  static const String _lastSyncKey = 'scheduling_last_sync';

  static HabitSchedulingService? _instance;
  static HabitSchedulingService get instance => _instance ??= HabitSchedulingService._();
  HabitSchedulingService._();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Schedule a habit with custom configuration
  Future<void> scheduleHabit(String habitId, HabitSchedule schedule, {HabitGoal? goal}) async {
    await initialize();

    // Find the habit
    final habit = sampleHabits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw Exception('Habit not found: $habitId'),
    );

    if (!habit.canBeScheduled) {
      throw Exception('This habit cannot be scheduled');
    }

    // Create scheduled habit
    final scheduledHabit = ScheduledHabit(
      habit: habit,
      schedule: schedule,
      goal: goal,
      addedAt: DateTime.now(),
    );

    // Save locally
    await _saveScheduledHabit(scheduledHabit);

    // Sync to Firestore
    await _syncScheduledHabitToFirestore(scheduledHabit);

    print('HabitSchedulingService: Scheduled habit ${habit.title} with schedule ${schedule.id}');
  }

  /// Remove a habit schedule
  Future<void> removeSchedule(String habitId) async {
    await initialize();

    final scheduledHabits = await getScheduledHabits();
    final updatedHabits = scheduledHabits.where((sh) => sh.habit.id != habitId).toList();

    await _saveScheduledHabits(updatedHabits);
    await _syncScheduledHabitsToFirestore(updatedHabits);

    print('HabitSchedulingService: Removed schedule for habit $habitId');
  }

  /// Get all scheduled habits
  Future<List<ScheduledHabit>> getScheduledHabits() async {
    await initialize();

    final json = _prefs!.getString(_scheduledHabitsKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((item) => ScheduledHabit.fromJson(item)).toList();
    } catch (e) {
      print('HabitSchedulingService: Error loading scheduled habits - $e');
      return [];
    }
  }

  /// Get scheduled habits for today
  Future<List<ScheduledHabit>> getTodaysScheduledHabits() async {
    final allScheduled = await getScheduledHabits();
    return allScheduled.where((sh) => sh.isScheduledForToday).toList();
  }

  /// Get a specific scheduled habit
  Future<ScheduledHabit?> getScheduledHabit(String habitId) async {
    final scheduledHabits = await getScheduledHabits();
    try {
      return scheduledHabits.firstWhere((sh) => sh.habit.id == habitId);
    } catch (e) {
      return null;
    }
  }

  /// Check if a habit is scheduled for today
  Future<bool> isHabitScheduledForToday(String habitId) async {
    final scheduledHabit = await getScheduledHabit(habitId);
    return scheduledHabit?.isScheduledForToday ?? false;
  }

  /// Create a goal for a habit
  Future<void> createGoal(String habitId, HabitGoal goal) async {
    await initialize();

    final scheduledHabits = await getScheduledHabits();
    final habitIndex = scheduledHabits.indexWhere((sh) => sh.habit.id == habitId);

    if (habitIndex == -1) {
      throw Exception('Habit not scheduled: $habitId');
    }

    // Update the scheduled habit with the goal
    scheduledHabits[habitIndex] = scheduledHabits[habitIndex].copyWith(goal: goal);

    await _saveScheduledHabits(scheduledHabits);
    await _syncScheduledHabitsToFirestore(scheduledHabits);

    print('HabitSchedulingService: Created goal for habit $habitId');
  }

  /// Update goal progress
  Future<void> updateGoalProgress(String habitId, int increment) async {
    await initialize();

    final scheduledHabits = await getScheduledHabits();
    final habitIndex = scheduledHabits.indexWhere((sh) => sh.habit.id == habitId);

    if (habitIndex == -1) return; // No scheduled habit found

    final scheduledHabit = scheduledHabits[habitIndex];
    if (scheduledHabit.goal == null) return; // No goal set

    // Update goal progress
    final updatedHabit = scheduledHabit.updateGoalProgress(increment);
    scheduledHabits[habitIndex] = updatedHabit;

    await _saveScheduledHabits(scheduledHabits);
    await _syncScheduledHabitsToFirestore(scheduledHabits);

    print('HabitSchedulingService: Updated goal progress for habit $habitId (+$increment)');
  }

  /// Get all active goals
  Future<List<HabitGoal>> getActiveGoals() async {
    final scheduledHabits = await getScheduledHabits();
    return scheduledHabits
        .where((sh) => sh.hasGoal && sh.goal!.isActive)
        .map((sh) => sh.goal!)
        .toList();
  }

  /// Pause/resume a scheduled habit
  Future<void> toggleScheduledHabit(String habitId) async {
    await initialize();

    final scheduledHabits = await getScheduledHabits();
    final habitIndex = scheduledHabits.indexWhere((sh) => sh.habit.id == habitId);

    if (habitIndex == -1) return;

    // Toggle the schedule
    scheduledHabits[habitIndex] = scheduledHabits[habitIndex].toggleSchedule();

    await _saveScheduledHabits(scheduledHabits);
    await _syncScheduledHabitsToFirestore(scheduledHabits);

    print('HabitSchedulingService: Toggled schedule for habit $habitId');
  }

  /// Get habits that can be scheduled (not already scheduled)
  Future<List<SunnahHabit>> getSchedulableHabits() async {
    final scheduledHabits = await getScheduledHabits();
    final scheduledIds = scheduledHabits.map((sh) => sh.habit.id).toSet();

    return sampleHabits
        .where((habit) => habit.canBeScheduled && !scheduledIds.contains(habit.id))
        .toList();
  }

  /// Save a single scheduled habit locally
  Future<void> _saveScheduledHabit(ScheduledHabit scheduledHabit) async {
    final scheduledHabits = await getScheduledHabits();
    
    // Remove existing entry for this habit
    scheduledHabits.removeWhere((sh) => sh.habit.id == scheduledHabit.habit.id);
    
    // Add the new/updated entry
    scheduledHabits.add(scheduledHabit);

    await _saveScheduledHabits(scheduledHabits);
  }

  /// Save all scheduled habits locally
  Future<void> _saveScheduledHabits(List<ScheduledHabit> scheduledHabits) async {
    await initialize();

    final json = jsonEncode(scheduledHabits.map((sh) => sh.toJson()).toList());
    await _prefs!.setString(_scheduledHabitsKey, json);
  }

  /// Sync a single scheduled habit to Firestore
  Future<void> _syncScheduledHabitToFirestore(ScheduledHabit scheduledHabit) async {
    try {
      final user = FirebaseService.currentUser;
      if (user == null) return;

      await FirebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .collection('scheduled_habits')
          .doc(scheduledHabit.habit.id)
          .set(scheduledHabit.toFirestore());

      print('HabitSchedulingService: Synced scheduled habit ${scheduledHabit.habit.id} to Firestore');
    } catch (e) {
      print('HabitSchedulingService: Error syncing to Firestore - $e');
    }
  }

  /// Sync all scheduled habits to Firestore
  Future<void> _syncScheduledHabitsToFirestore(List<ScheduledHabit> scheduledHabits) async {
    for (final scheduledHabit in scheduledHabits) {
      await _syncScheduledHabitToFirestore(scheduledHabit);
    }
  }

  /// Sync from Firestore (load user's scheduled habits from cloud)
  Future<void> syncFromFirestore() async {
    try {
      final user = FirebaseService.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .collection('scheduled_habits')
          .get();

      final scheduledHabits = <ScheduledHabit>[];
      
      for (final doc in snapshot.docs) {
        try {
          final habitId = doc.data()['habitId'] as String;
          final habit = sampleHabits.firstWhere(
            (h) => h.id == habitId,
            orElse: () => throw Exception('Habit not found: $habitId'),
          );
          
          final scheduledHabit = ScheduledHabit.fromFirestore(doc, habit);
          scheduledHabits.add(scheduledHabit);
        } catch (e) {
          print('HabitSchedulingService: Error loading scheduled habit from Firestore - $e');
        }
      }

      await _saveScheduledHabits(scheduledHabits);
      await _updateLastSyncTime();

      print('HabitSchedulingService: Synced ${scheduledHabits.length} scheduled habits from Firestore');
    } catch (e) {
      print('HabitSchedulingService: Error syncing from Firestore - $e');
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTime() async {
    await initialize();
    await _prefs!.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    await initialize();
    final syncTime = _prefs!.getString(_lastSyncKey);
    return syncTime != null ? DateTime.parse(syncTime) : null;
  }

  /// Clear all scheduled habits (for testing/reset)
  Future<void> clearAllScheduledHabits() async {
    await initialize();
    await _prefs!.remove(_scheduledHabitsKey);
    await _prefs!.remove(_lastSyncKey);
    
    // Also clear from Firestore
    try {
      final user = FirebaseService.currentUser;
      if (user != null) {
        final batch = FirebaseService.firestore.batch();
        final snapshot = await FirebaseService.firestore
            .collection('users')
            .doc(user.uid)
            .collection('scheduled_habits')
            .get();
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
      }
    } catch (e) {
      print('HabitSchedulingService: Error clearing Firestore data - $e');
    }

    print('HabitSchedulingService: Cleared all scheduled habits');
  }
}
