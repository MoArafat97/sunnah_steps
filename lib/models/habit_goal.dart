import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents different types of habit goals
enum GoalType {
  streak,     // Consecutive days goal (e.g., "30 day streak")
  total,      // Total completions goal (e.g., "100 total completions")
  frequency   // Frequency goal (e.g., "3 times per week")
}

/// Model for habit goal tracking
class HabitGoal {
  final String id;
  final String habitId;
  final GoalType type;
  final int targetCount;
  final int currentCount;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;
  final Map<String, dynamic>? metadata; // For additional goal-specific data

  const HabitGoal({
    required this.id,
    required this.habitId,
    required this.type,
    required this.targetCount,
    this.currentCount = 0,
    required this.startDate,
    this.endDate,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.notes,
    this.metadata,
  });

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetCount <= 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// Get remaining count to reach target
  int get remainingCount {
    return (targetCount - currentCount).clamp(0, targetCount);
  }

  /// Check if goal is achieved
  bool get isAchieved {
    return currentCount >= targetCount;
  }

  /// Get days remaining (for time-bound goals)
  int getDaysRemaining() {
    if (endDate == null) return -1; // No end date
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (today.isAfter(endDate!)) return 0;
    
    return endDate!.difference(today).inDays + 1;
  }

  /// Check if goal is still active (not expired)
  bool get isActive {
    if (isCompleted) return false;
    if (endDate == null) return true; // No expiry
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return !today.isAfter(endDate!);
  }

  /// Get goal description for display
  String getDescription() {
    switch (type) {
      case GoalType.streak:
        return '$targetCount day streak';
      case GoalType.total:
        return '$targetCount total completions';
      case GoalType.frequency:
        final period = metadata?['period'] ?? 'week';
        return '$targetCount times per $period';
    }
  }

  /// Get progress description for display
  String getProgressDescription() {
    switch (type) {
      case GoalType.streak:
        return '$currentCount / $targetCount days';
      case GoalType.total:
        return '$currentCount / $targetCount completions';
      case GoalType.frequency:
        return '$currentCount / $targetCount this period';
    }
  }

  /// Create a copy with updated fields
  HabitGoal copyWith({
    String? id,
    String? habitId,
    GoalType? type,
    int? targetCount,
    int? currentCount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return HabitGoal(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Increment progress by specified amount
  HabitGoal incrementProgress(int amount) {
    final newCount = currentCount + amount;
    final achieved = newCount >= targetCount;
    
    return copyWith(
      currentCount: newCount,
      isCompleted: achieved,
      completedAt: achieved && completedAt == null ? DateTime.now() : completedAt,
    );
  }

  /// Reset progress to zero
  HabitGoal resetProgress() {
    return copyWith(
      currentCount: 0,
      isCompleted: false,
      completedAt: null,
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'type': type.name,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory HabitGoal.fromJson(Map<String, dynamic> json) {
    return HabitGoal(
      id: json['id'] ?? '',
      habitId: json['habitId'] ?? '',
      type: GoalType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GoalType.total,
      ),
      targetCount: json['targetCount'] ?? 0,
      currentCount: json['currentCount'] ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      notes: json['notes'],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'habitId': habitId,
      'type': type.name,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory HabitGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitGoal(
      id: data['id'] ?? doc.id,
      habitId: data['habitId'] ?? '',
      type: GoalType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => GoalType.total,
      ),
      targetCount: data['targetCount'] ?? 0,
      currentCount: data['currentCount'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      notes: data['notes'],
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
    );
  }

  @override
  String toString() {
    return 'HabitGoal(id: $id, type: $type, progress: $currentCount/$targetCount, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitGoal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
