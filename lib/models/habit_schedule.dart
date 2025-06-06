import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents different types of habit scheduling
enum ScheduleType { 
  duration,   // Schedule for a specific duration (X days/weeks/months)
  frequency,  // Schedule for a specific frequency (X times per period)
  custom      // Custom schedule with specific days/times
}

/// Represents time periods for scheduling
enum SchedulePeriod { 
  day,    // Daily frequency
  week,   // Weekly frequency  
  month   // Monthly frequency
}

/// Model for custom habit scheduling configuration
class HabitSchedule {
  final String id;
  final ScheduleType type;
  final int? durationDays;           // For duration-based schedules
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int>? weekdays;         // For weekly schedules (1=Monday, 7=Sunday)
  final int? frequency;              // Times per period
  final SchedulePeriod? period;      // Period for frequency-based schedules
  final bool isActive;
  final DateTime createdAt;
  final DateTime? pausedAt;          // When schedule was paused
  final String? notes;               // Optional user notes

  const HabitSchedule({
    required this.id,
    required this.type,
    this.durationDays,
    this.startDate,
    this.endDate,
    this.weekdays,
    this.frequency,
    this.period,
    this.isActive = true,
    required this.createdAt,
    this.pausedAt,
    this.notes,
  });

  /// Check if this schedule is active for today
  bool isActiveToday() {
    if (!isActive || pausedAt != null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check date range
    if (startDate != null) {
      final startDay = DateTime(startDate!.year, startDate!.month, startDate!.day);
      if (today.isBefore(startDay)) return false;
    }

    if (endDate != null) {
      final endDay = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (today.isAfter(endDay)) return false;
    }

    // Check weekday restrictions for custom schedules
    if (type == ScheduleType.custom && weekdays != null) {
      final todayWeekday = now.weekday; // 1=Monday, 7=Sunday
      return weekdays!.contains(todayWeekday);
    }

    return true;
  }

  /// Check if the schedule is completed (for duration-based schedules)
  bool isCompleted() {
    if (type != ScheduleType.duration || endDate == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return today.isAfter(endDate!);
  }

  /// Get number of days remaining in the schedule
  int getDaysRemaining() {
    if (endDate == null) return -1; // Infinite/no end date
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (today.isAfter(endDate!)) return 0;
    
    return endDate!.difference(today).inDays + 1;
  }

  /// Get total duration in days
  int getTotalDurationDays() {
    if (startDate == null || endDate == null) return durationDays ?? 0;
    
    return endDate!.difference(startDate!).inDays + 1;
  }

  /// Get progress percentage (0.0 to 1.0)
  double getProgressPercentage() {
    if (type != ScheduleType.duration || startDate == null || endDate == null) {
      return 0.0;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (today.isBefore(startDate!)) return 0.0;
    if (today.isAfter(endDate!)) return 1.0;
    
    final totalDays = getTotalDurationDays();
    final daysPassed = today.difference(startDate!).inDays + 1;
    
    return totalDays > 0 ? daysPassed / totalDays : 0.0;
  }

  /// Create a copy with updated fields
  HabitSchedule copyWith({
    String? id,
    ScheduleType? type,
    int? durationDays,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? weekdays,
    int? frequency,
    SchedulePeriod? period,
    bool? isActive,
    DateTime? createdAt,
    DateTime? pausedAt,
    String? notes,
  }) {
    return HabitSchedule(
      id: id ?? this.id,
      type: type ?? this.type,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      weekdays: weekdays ?? this.weekdays,
      frequency: frequency ?? this.frequency,
      period: period ?? this.period,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      pausedAt: pausedAt ?? this.pausedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'durationDays': durationDays,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'weekdays': weekdays,
      'frequency': frequency,
      'period': period?.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'pausedAt': pausedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Create from JSON
  factory HabitSchedule.fromJson(Map<String, dynamic> json) {
    return HabitSchedule(
      id: json['id'] ?? '',
      type: ScheduleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ScheduleType.duration,
      ),
      durationDays: json['durationDays'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      weekdays: json['weekdays'] != null ? List<int>.from(json['weekdays']) : null,
      frequency: json['frequency'],
      period: json['period'] != null 
        ? SchedulePeriod.values.firstWhere(
            (e) => e.name == json['period'],
            orElse: () => SchedulePeriod.day,
          )
        : null,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      pausedAt: json['pausedAt'] != null ? DateTime.parse(json['pausedAt']) : null,
      notes: json['notes'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type.name,
      'durationDays': durationDays,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'weekdays': weekdays,
      'frequency': frequency,
      'period': period?.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'pausedAt': pausedAt != null ? Timestamp.fromDate(pausedAt!) : null,
      'notes': notes,
    };
  }

  /// Create from Firestore document
  factory HabitSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitSchedule(
      id: data['id'] ?? doc.id,
      type: ScheduleType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ScheduleType.duration,
      ),
      durationDays: data['durationDays'],
      startDate: data['startDate'] != null ? (data['startDate'] as Timestamp).toDate() : null,
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      weekdays: data['weekdays'] != null ? List<int>.from(data['weekdays']) : null,
      frequency: data['frequency'],
      period: data['period'] != null
        ? SchedulePeriod.values.firstWhere(
            (e) => e.name == data['period'],
            orElse: () => SchedulePeriod.day,
          )
        : null,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      pausedAt: data['pausedAt'] != null ? (data['pausedAt'] as Timestamp).toDate() : null,
      notes: data['notes'],
    );
  }

  @override
  String toString() {
    return 'HabitSchedule(id: $id, type: $type, isActive: $isActive, daysRemaining: ${getDaysRemaining()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitSchedule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
