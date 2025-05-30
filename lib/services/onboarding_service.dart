import '../models/user_answers.dart';

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  UserAnswers _userAnswers = UserAnswers();

  // Get current answers
  UserAnswers get userAnswers => _userAnswers;

  // Update age group
  void setAgeGroup(String ageGroup) {
    _userAnswers = _userAnswers.copyWith(ageGroup: ageGroup);
  }

  // Update closeness
  void setCloseness(String closeness) {
    _userAnswers = _userAnswers.copyWith(closeness: closeness);
  }

  // Update struggle
  void setStruggle(String struggle) {
    _userAnswers = _userAnswers.copyWith(struggle: struggle);
  }

  // Update frequency
  void setFrequency(String frequency) {
    _userAnswers = _userAnswers.copyWith(frequency: frequency);
  }

  // Update gender
  void setGender(String gender) {
    _userAnswers = _userAnswers.copyWith(gender: gender);
  }

  // Clear all answers
  void clearAnswers() {
    _userAnswers = UserAnswers();
  }

  // Check if all required answers are provided
  bool get isComplete {
    return _userAnswers.ageGroup != null &&
           _userAnswers.closeness != null &&
           _userAnswers.struggle != null &&
           _userAnswers.frequency != null &&
           _userAnswers.gender != null;
  }
}
