// lib/models/streak_data.dart

/// Model for tracking user's habit completion streaks
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletionDate;
  final DateTime streakStartDate;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletionDate,
    required this.streakStartDate,
  });

  /// Create initial streak data
  factory StreakData.initial() {
    return StreakData(
      currentStreak: 0,
      longestStreak: 0,
      lastCompletionDate: null,
      streakStartDate: DateTime.now(),
    );
  }

  /// Create from JSON for persistence
  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      lastCompletionDate: json['lastCompletionDate'] != null
          ? DateTime.parse(json['lastCompletionDate'] as String)
          : null,
      streakStartDate: DateTime.parse(json['streakStartDate'] as String),
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletionDate': lastCompletionDate?.toIso8601String(),
      'streakStartDate': streakStartDate.toIso8601String(),
    };
  }

  /// Update streak based on completion date
  StreakData updateWithCompletion(DateTime completionDate) {
    final completionDay = DateTime(
      completionDate.year,
      completionDate.month,
      completionDate.day,
    );

    // If no previous completion, start new streak
    if (lastCompletionDate == null) {
      return StreakData(
        currentStreak: 1,
        longestStreak: longestStreak > 1 ? longestStreak : 1,
        lastCompletionDate: completionDay,
        streakStartDate: completionDay,
      );
    }

    final lastDay = DateTime(
      lastCompletionDate!.year,
      lastCompletionDate!.month,
      lastCompletionDate!.day,
    );

    // Same day completion - no change
    if (completionDay.isAtSameMomentAs(lastDay)) {
      return this;
    }

    // Next day completion - extend streak
    if (completionDay.difference(lastDay).inDays == 1) {
      final newStreak = currentStreak + 1;
      return StreakData(
        currentStreak: newStreak,
        longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
        lastCompletionDate: completionDay,
        streakStartDate: streakStartDate,
      );
    }

    // Gap in completion - reset streak
    return StreakData(
      currentStreak: 1,
      longestStreak: longestStreak,
      lastCompletionDate: completionDay,
      streakStartDate: completionDay,
    );
  }

  /// Check if streak should be reset due to missed day
  StreakData checkForStreakReset() {
    if (lastCompletionDate == null) return this;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      lastCompletionDate!.year,
      lastCompletionDate!.month,
      lastCompletionDate!.day,
    );

    // If more than 1 day has passed without completion, reset streak
    if (today.difference(lastDay).inDays > 1) {
      return StreakData(
        currentStreak: 0,
        longestStreak: longestStreak,
        lastCompletionDate: lastCompletionDate,
        streakStartDate: today,
      );
    }

    return this;
  }

  /// Get streak status message
  String get statusMessage {
    if (currentStreak == 0) {
      return "Start your Sunnah journey today!";
    } else if (currentStreak == 1) {
      return "Great start! Keep it going tomorrow.";
    } else if (currentStreak < 7) {
      return "$currentStreak days strong! Building momentum.";
    } else if (currentStreak < 30) {
      return "$currentStreak days! You're developing a beautiful habit.";
    } else {
      return "$currentStreak days! MashaAllah, what dedication!";
    }
  }

  /// Get streak emoji based on current streak
  String get streakEmoji {
    if (currentStreak == 0) return "🌱";
    if (currentStreak < 7) return "🔥";
    if (currentStreak < 30) return "⭐";
    return "🏆";
  }

  @override
  String toString() {
    return 'StreakData(current: $currentStreak, longest: $longestStreak, last: $lastCompletionDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreakData &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.lastCompletionDate == lastCompletionDate &&
        other.streakStartDate == streakStartDate;
  }

  @override
  int get hashCode {
    return currentStreak.hashCode ^
        longestStreak.hashCode ^
        lastCompletionDate.hashCode ^
        streakStartDate.hashCode;
  }
}
