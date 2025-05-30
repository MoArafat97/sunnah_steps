class TimeWindow {
  final int startHour; // 0-23
  final int endHour;   // 0-23
  final String? description;

  TimeWindow({
    required this.startHour,
    required this.endHour,
    this.description,
  });

  bool isCurrentTimeInWindow() {
    final now = DateTime.now();
    final currentHour = now.hour;

    if (startHour <= endHour) {
      // Normal range (e.g., 9-17)
      return currentHour >= startHour && currentHour <= endHour;
    } else {
      // Overnight range (e.g., 22-6)
      return currentHour >= startHour || currentHour <= endHour;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'startHour': startHour,
      'endHour': endHour,
      'description': description,
    };
  }

  factory TimeWindow.fromJson(Map<String, dynamic> json) {
    return TimeWindow(
      startHour: json['startHour'],
      endHour: json['endHour'],
      description: json['description'],
    );
  }
}

class SunnahHabit {
  final String id;
  final String title;
  final String category; // "daily", "weekly", "occasional"
  final String hadithArabic;   // new
  final String hadithEnglish;  // new
  final String benefits;
  final List<String> tags;     // new
  final List<String> placeTypes; // new - place types where this habit is relevant
  final List<String> contextTags; // new - context tags for matching with places
  final TimeWindow? timeWindow; // new - optional time window when this habit is relevant
  final int priority;          // new - priority for ranking (1-10, higher = more important)
  final int? proximityRadius;  // new - optional custom radius in meters for this habit
  bool reminder;

  SunnahHabit({
    required this.id,
    required this.title,
    required this.category,
    required this.hadithArabic,
    required this.hadithEnglish,
    required this.benefits,
    this.tags = const [],       // default empty
    this.placeTypes = const [], // default empty
    this.contextTags = const [], // default empty
    this.timeWindow,            // default null (always applicable)
    this.priority = 5,          // default medium priority
    this.proximityRadius,       // default null (use global radius)
    this.reminder = false,
  });

  // Check if this habit is relevant for the current time
  bool isRelevantForCurrentTime() {
    return timeWindow?.isCurrentTimeInWindow() ?? true;
  }

  // Check if this habit matches a place's context tags
  bool matchesPlaceContext(List<String> placeTags) {
    if (contextTags.isEmpty) return true; // No context restrictions
    return contextTags.any((tag) => placeTags.contains(tag));
  }
}