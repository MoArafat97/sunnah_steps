// lib/models/habit_item.dart

class HabitItem {
  final String name;
  bool completed; // on dashboard: completion; in library: selection

  HabitItem({required this.name, this.completed = false});

  /// Create from JSON
  factory HabitItem.fromJson(Map<String, dynamic> json) {
    return HabitItem(
      name: json['name'] ?? '',
      completed: json['completed'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'completed': completed,
    };
  }

  /// Create a copy with updated fields
  HabitItem copyWith({
    String? name,
    bool? completed,
  }) {
    return HabitItem(
      name: name ?? this.name,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() {
    return 'HabitItem(name: $name, completed: $completed)';
  }
}
