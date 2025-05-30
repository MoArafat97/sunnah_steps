// test/unit/streak_data_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sunnah_steps/models/streak_data.dart';

void main() {
  group('StreakData Model Tests', () {
    group('Initial State Tests', () {
      test('should create initial streak data correctly', () {
        final streakData = StreakData.initial();
        
        expect(streakData.currentStreak, equals(0));
        expect(streakData.longestStreak, equals(0));
        expect(streakData.lastCompletionDate, isNull);
        expect(streakData.streakStartDate, isNotNull);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly', () {
        final now = DateTime.now();
        final streakData = StreakData(
          currentStreak: 5,
          longestStreak: 10,
          lastCompletionDate: now,
          streakStartDate: now.subtract(const Duration(days: 4)),
        );
        
        final json = streakData.toJson();
        
        expect(json['currentStreak'], equals(5));
        expect(json['longestStreak'], equals(10));
        expect(json['lastCompletionDate'], equals(now.toIso8601String()));
        expect(json['streakStartDate'], isNotNull);
      });

      test('should deserialize from JSON correctly', () {
        final now = DateTime.now();
        final json = {
          'currentStreak': 7,
          'longestStreak': 15,
          'lastCompletionDate': now.toIso8601String(),
          'streakStartDate': now.subtract(const Duration(days: 6)).toIso8601String(),
        };
        
        final streakData = StreakData.fromJson(json);
        
        expect(streakData.currentStreak, equals(7));
        expect(streakData.longestStreak, equals(15));
        expect(streakData.lastCompletionDate?.day, equals(now.day));
      });

      test('should handle null lastCompletionDate in JSON', () {
        final now = DateTime.now();
        final json = {
          'currentStreak': 0,
          'longestStreak': 5,
          'lastCompletionDate': null,
          'streakStartDate': now.toIso8601String(),
        };
        
        final streakData = StreakData.fromJson(json);
        
        expect(streakData.currentStreak, equals(0));
        expect(streakData.lastCompletionDate, isNull);
      });
    });

    group('Streak Update Logic Tests', () {
      test('should start new streak on first completion', () {
        final initial = StreakData.initial();
        final today = DateTime.now();
        
        final updated = initial.updateWithCompletion(today);
        
        expect(updated.currentStreak, equals(1));
        expect(updated.longestStreak, equals(1));
        expect(updated.lastCompletionDate?.day, equals(today.day));
      });

      test('should increment streak on consecutive day', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        final initial = StreakData(
          currentStreak: 1,
          longestStreak: 1,
          lastCompletionDate: yesterday,
          streakStartDate: yesterday,
        );
        
        final updated = initial.updateWithCompletion(today);
        
        expect(updated.currentStreak, equals(2));
        expect(updated.longestStreak, equals(2));
      });

      test('should not change streak for same day completion', () {
        final today = DateTime.now();
        
        final initial = StreakData(
          currentStreak: 3,
          longestStreak: 5,
          lastCompletionDate: today,
          streakStartDate: today.subtract(const Duration(days: 2)),
        );
        
        final updated = initial.updateWithCompletion(today);
        
        expect(updated.currentStreak, equals(3)); // No change
        expect(updated.longestStreak, equals(5)); // No change
      });

      test('should reset streak after gap', () {
        final today = DateTime.now();
        final threeDaysAgo = today.subtract(const Duration(days: 3));
        
        final initial = StreakData(
          currentStreak: 5,
          longestStreak: 8,
          lastCompletionDate: threeDaysAgo,
          streakStartDate: threeDaysAgo.subtract(const Duration(days: 4)),
        );
        
        final updated = initial.updateWithCompletion(today);
        
        expect(updated.currentStreak, equals(1)); // Reset to 1
        expect(updated.longestStreak, equals(8)); // Maintain longest
      });

      test('should update longest streak when current exceeds it', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        final initial = StreakData(
          currentStreak: 4,
          longestStreak: 4,
          lastCompletionDate: yesterday,
          streakStartDate: yesterday.subtract(const Duration(days: 3)),
        );
        
        final updated = initial.updateWithCompletion(today);
        
        expect(updated.currentStreak, equals(5));
        expect(updated.longestStreak, equals(5)); // Updated
      });
    });

    group('Streak Reset Logic Tests', () {
      test('should reset streak when more than 1 day has passed', () {
        final today = DateTime.now();
        final threeDaysAgo = today.subtract(const Duration(days: 3));
        
        final streakData = StreakData(
          currentStreak: 7,
          longestStreak: 10,
          lastCompletionDate: threeDaysAgo,
          streakStartDate: threeDaysAgo.subtract(const Duration(days: 6)),
        );
        
        final checked = streakData.checkForStreakReset();
        
        expect(checked.currentStreak, equals(0)); // Reset
        expect(checked.longestStreak, equals(10)); // Maintain longest
      });

      test('should not reset streak if completed yesterday', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        final streakData = StreakData(
          currentStreak: 5,
          longestStreak: 8,
          lastCompletionDate: yesterday,
          streakStartDate: yesterday.subtract(const Duration(days: 4)),
        );
        
        final checked = streakData.checkForStreakReset();
        
        expect(checked.currentStreak, equals(5)); // No change
        expect(checked.longestStreak, equals(8)); // No change
      });

      test('should not reset streak if completed today', () {
        final today = DateTime.now();
        
        final streakData = StreakData(
          currentStreak: 3,
          longestStreak: 6,
          lastCompletionDate: today,
          streakStartDate: today.subtract(const Duration(days: 2)),
        );
        
        final checked = streakData.checkForStreakReset();
        
        expect(checked.currentStreak, equals(3)); // No change
        expect(checked.longestStreak, equals(6)); // No change
      });

      test('should handle null lastCompletionDate', () {
        final streakData = StreakData.initial();
        
        final checked = streakData.checkForStreakReset();
        
        expect(checked.currentStreak, equals(0));
        expect(checked.longestStreak, equals(0));
        expect(checked.lastCompletionDate, isNull);
      });
    });

    group('Status Message Tests', () {
      test('should return correct message for zero streak', () {
        final streakData = StreakData.initial();
        
        expect(streakData.statusMessage, equals("Start your Sunnah journey today!"));
      });

      test('should return correct message for 1 day streak', () {
        final streakData = StreakData(
          currentStreak: 1,
          longestStreak: 1,
          lastCompletionDate: DateTime.now(),
          streakStartDate: DateTime.now(),
        );
        
        expect(streakData.statusMessage, equals("Great start! Keep it going tomorrow."));
      });

      test('should return correct message for short streak', () {
        final streakData = StreakData(
          currentStreak: 5,
          longestStreak: 5,
          lastCompletionDate: DateTime.now(),
          streakStartDate: DateTime.now().subtract(const Duration(days: 4)),
        );
        
        expect(streakData.statusMessage, equals("5 days strong! Building momentum."));
      });

      test('should return correct message for medium streak', () {
        final streakData = StreakData(
          currentStreak: 15,
          longestStreak: 15,
          lastCompletionDate: DateTime.now(),
          streakStartDate: DateTime.now().subtract(const Duration(days: 14)),
        );
        
        expect(streakData.statusMessage, equals("15 days! You're developing a beautiful habit."));
      });

      test('should return correct message for long streak', () {
        final streakData = StreakData(
          currentStreak: 45,
          longestStreak: 45,
          lastCompletionDate: DateTime.now(),
          streakStartDate: DateTime.now().subtract(const Duration(days: 44)),
        );
        
        expect(streakData.statusMessage, equals("45 days! MashaAllah, what dedication!"));
      });
    });

    group('Streak Emoji Tests', () {
      test('should return correct emoji for different streak lengths', () {
        expect(StreakData.initial().streakEmoji, equals("🌱"));
        
        final shortStreak = StreakData(
          currentStreak: 3,
          longestStreak: 3,
          lastCompletionDate: DateTime.now(),
          streakStartDate: DateTime.now().subtract(const Duration(days: 2)),
        );
        expect(shortStreak.streakEmoji, equals("🔥"));
        
        final mediumStreak = StreakData(
          currentStreak: 15,
          longestStreak: 15,
          lastCompletionDate: DateTime.now(),
          streakStartDate: DateTime.now().subtract(const Duration(days: 14)),
        );
        expect(mediumStreak.streakEmoji, equals("⭐"));
        
        final longStreak = StreakData(
          currentStreak: 35,
          longestStreak: 35,
          lastCompletionDate: DateTime.now(),
          streakStartDate: DateTime.now().subtract(const Duration(days: 34)),
        );
        expect(longStreak.streakEmoji, equals("🏆"));
      });
    });

    group('Equality Tests', () {
      test('should be equal when all properties match', () {
        final now = DateTime.now();
        final streakData1 = StreakData(
          currentStreak: 5,
          longestStreak: 10,
          lastCompletionDate: now,
          streakStartDate: now.subtract(const Duration(days: 4)),
        );
        
        final streakData2 = StreakData(
          currentStreak: 5,
          longestStreak: 10,
          lastCompletionDate: now,
          streakStartDate: now.subtract(const Duration(days: 4)),
        );
        
        expect(streakData1, equals(streakData2));
        expect(streakData1.hashCode, equals(streakData2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final now = DateTime.now();
        final streakData1 = StreakData(
          currentStreak: 5,
          longestStreak: 10,
          lastCompletionDate: now,
          streakStartDate: now.subtract(const Duration(days: 4)),
        );
        
        final streakData2 = StreakData(
          currentStreak: 6, // Different
          longestStreak: 10,
          lastCompletionDate: now,
          streakStartDate: now.subtract(const Duration(days: 4)),
        );
        
        expect(streakData1, isNot(equals(streakData2)));
      });
    });
  });
}
