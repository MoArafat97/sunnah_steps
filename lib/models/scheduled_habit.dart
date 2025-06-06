import 'package:cloud_firestore/cloud_firestore.dart';
import 'sunnah_habit.dart';
import 'habit_schedule.dart';
import 'habit_goal.dart';

/// Model that combines a SunnahHabit with its scheduling and goal information
class ScheduledHabit {
  final SunnahHabit habit;
  final HabitSchedule? schedule;
  final HabitGoal? goal;
  final DateTime addedAt;
  final bool isEnabled;
  final String? userNotes;
  final Map<String, dynamic>? customSettings;

  const ScheduledHabit({
    required this.habit,
    this.schedule,
    this.goal,
    required this.addedAt,
    this.isEnabled = true,
    this.userNotes,
    this.customSettings,
  });

  /// Check if this habit has a custom schedule
  bool get hasSchedule => schedule != null;

  /// Check if this habit has an active goal
  bool get hasGoal => goal != null;

  /// Check if this habit is scheduled for today
  bool get isScheduledForToday {
    if (!isEnabled) return false;
    return schedule?.isActiveToday() ?? true;
  }

  /// Check if the schedule is completed
  bool get isScheduleCompleted {
    return schedule?.isCompleted() ?? false;
  }

  /// Check if the goal is achieved
  bool get isGoalAchieved {
    return goal?.isAchieved ?? false;
  }

  /// Get the priority for today's checklist (higher = more important)
  int get todayPriority {
    int basePriority = habit.priority;
    
    // Boost priority if scheduled for today
    if (hasSchedule && isScheduledForToday) {
      basePriority += 2;
    }
    
    // Boost priority if goal is close to completion
    if (hasGoal && goal!.progressPercentage > 0.8) {
      basePriority += 1;
    }
    
    // Boost priority if schedule is ending soon
    if (hasSchedule && schedule!.getDaysRemaining() <= 3 && schedule!.getDaysRemaining() > 0) {
      basePriority += 1;
    }
    
    return basePriority.clamp(1, 10);
  }

  /// Get display status for UI
  String getDisplayStatus() {
    if (!isEnabled) return 'Paused';
    if (isScheduleCompleted) return 'Schedule Completed';
    if (isGoalAchieved) return 'Goal Achieved';
    if (hasSchedule && !isScheduledForToday) return 'Not Scheduled Today';
    
    if (hasSchedule) {
      final daysRemaining = schedule!.getDaysRemaining();
      if (daysRemaining > 0) {
        return '$daysRemaining days remaining';
      }
    }
    
    return 'Active';
  }

  /// Get progress description for UI
  String? getProgressDescription() {
    if (hasGoal) {
      return goal!.getProgressDescription();
    }
    
    if (hasSchedule && schedule!.type == ScheduleType.duration) {
      final progress = (schedule!.getProgressPercentage() * 100).round();
      return '$progress% complete';
    }
    
    return null;
  }

  /// Create a copy with updated fields
  ScheduledHabit copyWith({
    SunnahHabit? habit,
    HabitSchedule? schedule,
    HabitGoal? goal,
    DateTime? addedAt,
    bool? isEnabled,
    String? userNotes,
    Map<String, dynamic>? customSettings,
  }) {
    return ScheduledHabit(
      habit: habit ?? this.habit,
      schedule: schedule ?? this.schedule,
      goal: goal ?? this.goal,
      addedAt: addedAt ?? this.addedAt,
      isEnabled: isEnabled ?? this.isEnabled,
      userNotes: userNotes ?? this.userNotes,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  /// Update the goal progress
  ScheduledHabit updateGoalProgress(int increment) {
    if (goal == null) return this;
    
    final updatedGoal = goal!.incrementProgress(increment);
    return copyWith(goal: updatedGoal);
  }

  /// Pause/resume the schedule
  ScheduledHabit toggleSchedule() {
    if (schedule == null) return this;
    
    final updatedSchedule = schedule!.copyWith(
      pausedAt: schedule!.pausedAt == null ? DateTime.now() : null,
    );
    return copyWith(schedule: updatedSchedule);
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'habit': habit.toJson(),
      'schedule': schedule?.toJson(),
      'goal': goal?.toJson(),
      'addedAt': addedAt.toIso8601String(),
      'isEnabled': isEnabled,
      'userNotes': userNotes,
      'customSettings': customSettings,
    };
  }

  /// Create from JSON
  factory ScheduledHabit.fromJson(Map<String, dynamic> json) {
    return ScheduledHabit(
      habit: SunnahHabit.fromJson(json['habit']),
      schedule: json['schedule'] != null ? HabitSchedule.fromJson(json['schedule']) : null,
      goal: json['goal'] != null ? HabitGoal.fromJson(json['goal']) : null,
      addedAt: DateTime.parse(json['addedAt']),
      isEnabled: json['isEnabled'] ?? true,
      userNotes: json['userNotes'],
      customSettings: json['customSettings'] != null 
        ? Map<String, dynamic>.from(json['customSettings']) 
        : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'habitId': habit.id,
      'schedule': schedule?.toFirestore(),
      'goal': goal?.toFirestore(),
      'addedAt': Timestamp.fromDate(addedAt),
      'isEnabled': isEnabled,
      'userNotes': userNotes,
      'customSettings': customSettings,
    };
  }

  /// Create from Firestore document (requires habit to be passed separately)
  factory ScheduledHabit.fromFirestore(DocumentSnapshot doc, SunnahHabit habit) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduledHabit(
      habit: habit,
      schedule: data['schedule'] != null
        ? HabitSchedule.fromJson(Map<String, dynamic>.from(data['schedule']))
        : null,
      goal: data['goal'] != null
        ? HabitGoal.fromJson(Map<String, dynamic>.from(data['goal']))
        : null,
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      isEnabled: data['isEnabled'] ?? true,
      userNotes: data['userNotes'],
      customSettings: data['customSettings'] != null
        ? Map<String, dynamic>.from(data['customSettings'])
        : null,
    );
  }

  @override
  String toString() {
    return 'ScheduledHabit(habit: ${habit.title}, hasSchedule: $hasSchedule, hasGoal: $hasGoal, isEnabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduledHabit && 
           other.habit.id == habit.id && 
           other.addedAt == addedAt;
  }

  @override
  int get hashCode => Object.hash(habit.id, addedAt);
}


