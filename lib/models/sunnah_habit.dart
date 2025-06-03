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
  final bool allowsScheduling; // NEW - whether this habit can be scheduled
  final List<String> suggestedDurations; // NEW - suggested schedule durations (e.g., ["7 days", "30 days"])

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
    this.allowsScheduling = true, // NEW - default to allowing scheduling
    this.suggestedDurations = const ["7 days", "30 days", "90 days"], // NEW - default suggestions
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

  // NEW - Check if this habit can be scheduled
  bool get canBeScheduled => allowsScheduling;

  // NEW - Get suggested duration options for scheduling
  List<String> get schedulingDurations => suggestedDurations;

  // NEW - Convert to JSON (enhanced to include new fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'hadithArabic': hadithArabic,
      'hadithEnglish': hadithEnglish,
      'benefits': benefits,
      'tags': tags,
      'placeTypes': placeTypes,
      'contextTags': contextTags,
      'timeWindow': timeWindow?.toJson(),
      'priority': priority,
      'proximityRadius': proximityRadius,
      'reminder': reminder,
      'allowsScheduling': allowsScheduling,
      'suggestedDurations': suggestedDurations,
    };
  }

  // NEW - Create from JSON (enhanced to include new fields)
  factory SunnahHabit.fromJson(Map<String, dynamic> json) {
    return SunnahHabit(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'daily',
      hadithArabic: json['hadithArabic'] ?? '',
      hadithEnglish: json['hadithEnglish'] ?? '',
      benefits: json['benefits'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : const [],
      placeTypes: json['placeTypes'] != null ? List<String>.from(json['placeTypes']) : const [],
      contextTags: json['contextTags'] != null ? List<String>.from(json['contextTags']) : const [],
      timeWindow: json['timeWindow'] != null ? TimeWindow.fromJson(json['timeWindow']) : null,
      priority: json['priority'] ?? 5,
      proximityRadius: json['proximityRadius'],
      reminder: json['reminder'] ?? false,
      allowsScheduling: json['allowsScheduling'] ?? true,
      suggestedDurations: json['suggestedDurations'] != null
        ? List<String>.from(json['suggestedDurations'])
        : const ["7 days", "30 days", "90 days"],
    );
  }
}