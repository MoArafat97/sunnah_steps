import 'package:flutter/material.dart';
import '../models/sunnah_habit.dart';
import '../services/context_matching_service.dart';

class PriorityRibbon extends StatelessWidget {
  final SunnahHabit habit;
  final bool isCompact;

  const PriorityRibbon({
    super.key,
    required this.habit,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final priorityLevel = ContextMatchingService.getHabitPriorityLevel(habit);
    final color = _getPriorityColor(priorityLevel);
    final emoji = _getPriorityEmoji(priorityLevel);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            priorityLevel,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priorityLevel) {
    switch (priorityLevel) {
      case 'Fard':
        return const Color(0xFF4CAF50); // 💚 Green
      case 'Recommended':
        return const Color(0xFF9C27B0); // 🟣 Purple
      case 'Optional':
        return const Color(0xFFFF9800); // 🟠 Orange
      default:
        return Colors.grey;
    }
  }

  String _getPriorityEmoji(String priorityLevel) {
    switch (priorityLevel) {
      case 'Fard':
        return '💚';
      case 'Recommended':
        return '🟣';
      case 'Optional':
        return '🟠';
      default:
        return '⚪';
    }
  }
}

// Timeline category colors for grouping
class TimelineColors {
  static const Color next30Min = Color(0xFF4CAF50); // 💚 Green
  static const Color today = Color(0xFF9C27B0); // 🟣 Purple
  static const Color thisWeek = Color(0xFFFF9800); // 🟠 Orange
  static const Color general = Color(0xFF607D8B); // Grey

  static Color getColorForTimeCategory(String category) {
    switch (category.toLowerCase()) {
      case 'next 30 min':
      case 'next30min':
        return next30Min;
      case 'today':
        return today;
      case 'this week':
      case 'thisweek':
        return thisWeek;
      default:
        return general;
    }
  }

  static String getEmojiForTimeCategory(String category) {
    switch (category.toLowerCase()) {
      case 'next 30 min':
      case 'next30min':
        return '💚';
      case 'today':
        return '🟣';
      case 'this week':
      case 'thisweek':
        return '🟠';
      default:
        return '⚪';
    }
  }
}

// Time category helper widget
class TimeCategoryLabel extends StatelessWidget {
  final String category;
  final bool isSelected;

  const TimeCategoryLabel({
    super.key,
    required this.category,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = TimelineColors.getColorForTimeCategory(category);
    final emoji = TimelineColors.getEmojiForTimeCategory(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
