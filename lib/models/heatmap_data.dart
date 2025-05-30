// lib/models/heatmap_data.dart

/// Model for tracking daily habit completion data for heatmap visualization
class HeatmapData {
  final DateTime date;
  final int completionCount;
  final List<String> completedHabitIds;

  const HeatmapData({
    required this.date,
    required this.completionCount,
    required this.completedHabitIds,
  });

  /// Create empty heatmap data for a date
  factory HeatmapData.empty(DateTime date) {
    return HeatmapData(
      date: DateTime(date.year, date.month, date.day),
      completionCount: 0,
      completedHabitIds: [],
    );
  }

  /// Create from JSON for persistence
  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      date: DateTime.parse(json['date'] as String),
      completionCount: json['completionCount'] as int,
      completedHabitIds: List<String>.from(json['completedHabitIds'] as List),
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'completionCount': completionCount,
      'completedHabitIds': completedHabitIds,
    };
  }

  /// Add a habit completion to this day
  HeatmapData addCompletion(String habitId) {
    if (completedHabitIds.contains(habitId)) {
      return this; // Already completed today
    }

    return HeatmapData(
      date: date,
      completionCount: completionCount + 1,
      completedHabitIds: [...completedHabitIds, habitId],
    );
  }

  /// Remove a habit completion from this day
  HeatmapData removeCompletion(String habitId) {
    if (!completedHabitIds.contains(habitId)) {
      return this; // Not completed today
    }

    final newHabitIds = completedHabitIds.where((id) => id != habitId).toList();
    return HeatmapData(
      date: date,
      completionCount: newHabitIds.length,
      completedHabitIds: newHabitIds,
    );
  }

  /// Get intensity level for heatmap coloring
  /// 0 = no completions (grey)
  /// 1 = 1 completion (light green)
  /// 2 = 2 completions (medium green)
  /// 3 = 3+ completions (dark green)
  int get intensityLevel {
    if (completionCount == 0) return 0;
    if (completionCount == 1) return 1;
    if (completionCount == 2) return 2;
    return 3; // 3+ completions
  }

  /// Get color for heatmap visualization
  String get colorHex {
    switch (intensityLevel) {
      case 0:
        return '#E5E7EB'; // Grey - no completions
      case 1:
        return '#BBF7D0'; // Light green - 1 habit
      case 2:
        return '#86EFAC'; // Medium green - 2 habits
      case 3:
        return '#22C55E'; // Dark green - 3+ habits
      default:
        return '#E5E7EB';
    }
  }

  /// Get descriptive text for this day's activity
  String get activityDescription {
    if (completionCount == 0) {
      return "No Sunnahs completed";
    } else if (completionCount == 1) {
      return "1 Sunnah completed";
    } else {
      return "$completionCount Sunnahs completed";
    }
  }

  /// Check if this is today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAtSameMomentAs(today);
  }

  /// Check if this is yesterday
  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return date.isAtSameMomentAs(yesterday);
  }

  /// Get day name (Mon, Tue, etc.)
  String get dayName {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayNames[date.weekday - 1];
  }

  /// Get day number
  int get dayNumber => date.day;

  @override
  String toString() {
    return 'HeatmapData(date: ${date.toIso8601String().split('T')[0]}, count: $completionCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HeatmapData &&
        other.date == date &&
        other.completionCount == completionCount &&
        _listEquals(other.completedHabitIds, completedHabitIds);
  }

  @override
  int get hashCode {
    return date.hashCode ^ completionCount.hashCode ^ completedHabitIds.hashCode;
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Weekly heatmap data containing 7 days
class WeeklyHeatmapData {
  final List<HeatmapData> days;
  final DateTime weekStartDate;

  const WeeklyHeatmapData({
    required this.days,
    required this.weekStartDate,
  });

  /// Create weekly heatmap for current week
  factory WeeklyHeatmapData.currentWeek() {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    
    final days = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      return HeatmapData.empty(date);
    });

    return WeeklyHeatmapData(
      days: days,
      weekStartDate: weekStart,
    );
  }

  /// Get total completions for the week
  int get totalCompletions {
    return days.fold(0, (sum, day) => sum + day.completionCount);
  }

  /// Get average completions per day
  double get averageCompletions {
    return totalCompletions / 7.0;
  }

  /// Get the most active day
  HeatmapData? get mostActiveDay {
    if (days.isEmpty) return null;
    return days.reduce((a, b) => a.completionCount > b.completionCount ? a : b);
  }

  /// Update a specific day's data
  WeeklyHeatmapData updateDay(DateTime date, HeatmapData newData) {
    final dayIndex = days.indexWhere((day) => 
        day.date.year == date.year &&
        day.date.month == date.month &&
        day.date.day == date.day);
    
    if (dayIndex == -1) return this;

    final newDays = List<HeatmapData>.from(days);
    newDays[dayIndex] = newData;

    return WeeklyHeatmapData(
      days: newDays,
      weekStartDate: weekStartDate,
    );
  }

  /// Get week start date (Monday)
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final daysToSubtract = weekday - 1; // Monday = 1, so subtract (weekday - 1)
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }
}
