// Static dataset mapping age groups and gender to frequency percentages
const Map<String, Map<String, Map<String, int>>> sunnahNorms = {
  "18-25": {
    "male": {
      "Several times a day": 10,
      "Once a day": 20,
      "Once a week": 25,
      "Once a month": 25,
      "Rarely": 20,
      "Never": 0,
    },
    "female": {
      "Several times a day": 15,
      "Once a day": 30,
      "Once a week": 25,
      "Once a month": 20,
      "Rarely": 10,
      "Never": 0,
    },
  },
  "25-40": {
    "male": {
      "Several times a day": 15,
      "Once a day": 30,
      "Once a week": 25,
      "Once a month": 20,
      "Rarely": 10,
      "Never": 0,
    },
    "female": {
      "Several times a day": 20,
      "Once a day": 40,
      "Once a week": 25,
      "Once a month": 10,
      "Rarely": 5,
      "Never": 0,
    },
  },
  "40-60": {
    "male": {
      "Several times a day": 20,
      "Once a day": 35,
      "Once a week": 25,
      "Once a month": 15,
      "Rarely": 5,
      "Never": 0,
    },
    "female": {
      "Several times a day": 25,
      "Once a day": 45,
      "Once a week": 20,
      "Once a month": 7,
      "Rarely": 3,
      "Never": 0,
    },
  },
  "60+": {
    "male": {
      "Several times a day": 25,
      "Once a day": 45,
      "Once a week": 20,
      "Once a month": 8,
      "Rarely": 2,
      "Never": 0,
    },
    "female": {
      "Several times a day": 30,
      "Once a day": 55,
      "Once a week": 10,
      "Once a month": 4,
      "Rarely": 1,
      "Never": 0,
    },
  },
};

// Helper function to get peer percentage
int getPeerPercentage(String ageGroup, String gender, String frequency) {
  return sunnahNorms[ageGroup]?[gender]?[frequency] ?? 0;
}

// Map frequency to engagement score (0-100%)
int getEngagementScore(String frequency) {
  switch (frequency) {
    case 'Several times a day':
      return 100;
    case 'Once a day':
      return 80;
    case 'Once a week':
      return 60;
    case 'Once a month':
      return 40;
    case 'Rarely':
      return 20;
    case 'Never':
      return 0;
    default:
      return 0;
  }
}

// Calculate peer average engagement score for a demographic
double getPeerAverageEngagement(String ageGroup, String gender) {
  final cohortData = sunnahNorms[ageGroup]?[gender];
  if (cohortData == null) return 0.0;

  double totalWeightedScore = 0.0;
  int totalPercentage = 0;

  cohortData.forEach((frequency, percentage) {
    final engagementScore = getEngagementScore(frequency);
    totalWeightedScore += (engagementScore * percentage);
    totalPercentage += percentage;
  });

  return totalPercentage > 0 ? totalWeightedScore / totalPercentage : 0.0;
}
