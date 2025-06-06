import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:sunnah_steps/pages/dashboard_page.dart';
import 'package:sunnah_steps/models/habit_item.dart';

void main() {
  group('Dashboard Fixes Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    test('HabitItem should support completion state changes', () {
      final habit = HabitItem(name: 'Test Habit', completed: false);
      
      expect(habit.completed, isFalse);
      expect(habit.name, equals('Test Habit'));
      
      // Test completion state change
      habit.completed = true;
      expect(habit.completed, isTrue);
    });

    test('Haptic feedback should be available', () {
      // Test that HapticFeedback methods are available
      expect(() => HapticFeedback.mediumImpact(), returnsNormally);
      expect(() => HapticFeedback.lightImpact(), returnsNormally);
      expect(() => HapticFeedback.selectionClick(), returnsNormally);
    });

    test('Dashboard page should be instantiable', () {
      const dashboard = DashboardPage();
      expect(dashboard, isNotNull);
      expect(dashboard.initialChecklistOverlayVisible, isFalse);
    });

    test('Dashboard page with overlay should be instantiable', () {
      const dashboard = DashboardPage(initialChecklistOverlayVisible: true);
      expect(dashboard, isNotNull);
      expect(dashboard.initialChecklistOverlayVisible, isTrue);
    });
  });
}
