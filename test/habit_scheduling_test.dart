import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/models/habit_schedule.dart';
import '../lib/models/habit_goal.dart';
import '../lib/services/habit_scheduling_service.dart';
import '../lib/data/sample_habits.dart';

void main() {
  group('Habit Scheduling Tests', () {
    setUp(() async {
      // Initialize SharedPreferences with mock
      SharedPreferences.setMockInitialValues({});
    });

    test('HabitSchedule model creation and validation', () {
      final schedule = HabitSchedule(
        id: 'test_schedule',
        type: ScheduleType.duration,
        durationDays: 30,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 29)),
        createdAt: DateTime.now(),
      );

      expect(schedule.id, 'test_schedule');
      expect(schedule.type, ScheduleType.duration);
      expect(schedule.durationDays, 30);
      expect(schedule.isActiveToday(), true);
      expect(schedule.getDaysRemaining(), 30);
      expect(schedule.getProgressPercentage(), greaterThan(0.0));
    });

    test('HabitGoal model creation and progress tracking', () {
      final goal = HabitGoal(
        id: 'test_goal',
        habitId: 'h21',
        type: GoalType.streak,
        targetCount: 30,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(goal.id, 'test_goal');
      expect(goal.type, GoalType.streak);
      expect(goal.targetCount, 30);
      expect(goal.currentCount, 0);
      expect(goal.progressPercentage, 0.0);
      expect(goal.remainingCount, 30);
      expect(goal.isAchieved, false);

      // Test progress increment
      final updatedGoal = goal.incrementProgress(5);
      expect(updatedGoal.currentCount, 5);
      expect(updatedGoal.progressPercentage, 5/30);
      expect(updatedGoal.remainingCount, 25);
    });

    test('HabitSchedulingService basic operations', () async {
      final service = HabitSchedulingService.instance;
      await service.initialize();

      // Test getting schedulable habits
      final schedulableHabits = await service.getSchedulableHabits();
      expect(schedulableHabits.isNotEmpty, true);

      // Test scheduling a habit
      final habit = sampleHabits.first;
      final schedule = HabitSchedule(
        id: 'test_schedule_${habit.id}',
        type: ScheduleType.duration,
        durationDays: 7,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 6)),
        createdAt: DateTime.now(),
      );

      await service.scheduleHabit(habit.id, schedule);

      // Verify habit is scheduled
      final scheduledHabits = await service.getScheduledHabits();
      expect(scheduledHabits.length, 1);
      expect(scheduledHabits.first.habit.id, habit.id);

      // Test getting today's scheduled habits
      final todaysHabits = await service.getTodaysScheduledHabits();
      expect(todaysHabits.length, 1);

      // Test checking if habit is scheduled for today
      final isScheduled = await service.isHabitScheduledForToday(habit.id);
      expect(isScheduled, true);

      // Test removing schedule
      await service.removeSchedule(habit.id);
      final habitsAfterRemoval = await service.getScheduledHabits();
      expect(habitsAfterRemoval.length, 0);
    });

    test('Goal progress tracking integration', () async {
      final service = HabitSchedulingService.instance;
      await service.initialize();

      final habit = sampleHabits.first;
      final schedule = HabitSchedule(
        id: 'test_schedule_${habit.id}',
        type: ScheduleType.duration,
        durationDays: 30,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 29)),
        createdAt: DateTime.now(),
      );

      final goal = HabitGoal(
        id: 'test_goal_${habit.id}',
        habitId: habit.id,
        type: GoalType.streak,
        targetCount: 30,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Schedule habit with goal
      await service.scheduleHabit(habit.id, schedule, goal: goal);

      // Update goal progress
      await service.updateGoalProgress(habit.id, 1);

      // Verify progress was updated
      final scheduledHabits = await service.getScheduledHabits();
      final scheduledHabit = scheduledHabits.first;
      expect(scheduledHabit.goal!.currentCount, 1);
      expect(scheduledHabit.goal!.progressPercentage, 1/30);
    });

    test('Schedule types and validation', () {
      // Test duration schedule
      final durationSchedule = HabitSchedule(
        id: 'duration_test',
        type: ScheduleType.duration,
        durationDays: 21,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 20)),
        createdAt: DateTime.now(),
      );

      expect(durationSchedule.isActiveToday(), true);
      expect(durationSchedule.getDaysRemaining(), 21);

      // Test frequency schedule
      final frequencySchedule = HabitSchedule(
        id: 'frequency_test',
        type: ScheduleType.frequency,
        frequency: 3,
        period: SchedulePeriod.week,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(frequencySchedule.isActiveToday(), true);
      expect(frequencySchedule.frequency, 3);
      expect(frequencySchedule.period, SchedulePeriod.week);

      // Test custom schedule (weekdays)
      final customSchedule = HabitSchedule(
        id: 'custom_test',
        type: ScheduleType.custom,
        weekdays: [1, 2, 3, 4, 5], // Monday to Friday
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(customSchedule.weekdays, [1, 2, 3, 4, 5]);
      // isActiveToday depends on current day of week
    });

    test('JSON serialization and deserialization', () {
      final schedule = HabitSchedule(
        id: 'json_test',
        type: ScheduleType.duration,
        durationDays: 14,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 13)),
        createdAt: DateTime.now(),
        notes: 'Test schedule',
      );

      // Test JSON conversion
      final json = schedule.toJson();
      final fromJson = HabitSchedule.fromJson(json);

      expect(fromJson.id, schedule.id);
      expect(fromJson.type, schedule.type);
      expect(fromJson.durationDays, schedule.durationDays);
      expect(fromJson.notes, schedule.notes);

      // Test goal JSON conversion
      final goal = HabitGoal(
        id: 'goal_json_test',
        habitId: 'h21',
        type: GoalType.total,
        targetCount: 100,
        currentCount: 25,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final goalJson = goal.toJson();
      final goalFromJson = HabitGoal.fromJson(goalJson);

      expect(goalFromJson.id, goal.id);
      expect(goalFromJson.type, goal.type);
      expect(goalFromJson.targetCount, goal.targetCount);
      expect(goalFromJson.currentCount, goal.currentCount);
    });

    tearDown(() async {
      // Clean up after each test
      await HabitSchedulingService.instance.clearAllScheduledHabits();
    });
  });
}
