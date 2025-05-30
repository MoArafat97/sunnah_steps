// lib/models/checklist_item.dart

import '../models/sunnah_habit.dart';

/// Represents a single item in the daily checklist
class ChecklistItem {
  final String id;
  final String title;
  final String benefits;
  final String hadithEnglish;
  final String hadithArabic;
  final List<String> tags;
  final String category;
  final int priority;
  bool isCompleted;
  final DateTime dateAssigned;

  ChecklistItem({
    required this.id,
    required this.title,
    required this.benefits,
    required this.hadithEnglish,
    required this.hadithArabic,
    required this.tags,
    required this.category,
    required this.priority,
    this.isCompleted = false,
    required this.dateAssigned,
  });

  /// Create ChecklistItem from SunnahHabit
  factory ChecklistItem.fromSunnahHabit(SunnahHabit habit) {
    return ChecklistItem(
      id: habit.id,
      title: habit.title,
      benefits: habit.benefits,
      hadithEnglish: habit.hadithEnglish,
      hadithArabic: habit.hadithArabic,
      tags: habit.tags,
      category: habit.category,
      priority: habit.priority,
      isCompleted: false,
      dateAssigned: DateTime.now(),
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'benefits': benefits,
      'hadithEnglish': hadithEnglish,
      'hadithArabic': hadithArabic,
      'tags': tags,
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted,
      'dateAssigned': dateAssigned.toIso8601String(),
    };
  }

  /// Create from JSON for persistence
  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      benefits: json['benefits'] as String,
      hadithEnglish: json['hadithEnglish'] as String,
      hadithArabic: json['hadithArabic'] as String,
      tags: List<String>.from(json['tags'] as List),
      category: json['category'] as String,
      priority: json['priority'] as int,
      isCompleted: json['isCompleted'] as bool,
      dateAssigned: DateTime.parse(json['dateAssigned'] as String),
    );
  }

  /// Create a copy with updated completion status
  ChecklistItem copyWith({
    bool? isCompleted,
    DateTime? dateAssigned,
  }) {
    return ChecklistItem(
      id: id,
      title: title,
      benefits: benefits,
      hadithEnglish: hadithEnglish,
      hadithArabic: hadithArabic,
      tags: tags,
      category: category,
      priority: priority,
      isCompleted: isCompleted ?? this.isCompleted,
      dateAssigned: dateAssigned ?? this.dateAssigned,
    );
  }

  /// Get priority color based on priority level
  /// Following user preferences: 💚 Fard 🟣 Recommended 🟠 Optional
  String get priorityEmoji {
    if (priority >= 8) return '💚'; // Fard
    if (priority >= 6) return '🟣'; // Recommended
    return '🟠'; // Optional
  }

  /// Get priority label
  String get priorityLabel {
    if (priority >= 8) return 'Fard';
    if (priority >= 6) return 'Recommended';
    return 'Optional';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChecklistItem{id: $id, title: $title, isCompleted: $isCompleted}';
  }
}
