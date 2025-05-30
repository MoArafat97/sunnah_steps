// lib/models/habit_item.dart

class HabitItem {
  final String name;
  bool completed; // on dashboard: completion; in library: selection
  HabitItem({required this.name, this.completed = false});
}
