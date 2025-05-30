class UserAnswers {
  String? ageGroup;
  String? closeness;
  String? struggle;
  String? frequency;
  String? gender;

  UserAnswers({
    this.ageGroup,
    this.closeness,
    this.struggle,
    this.frequency,
    this.gender,
  });

  // Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'ageGroup': ageGroup,
      'closeness': closeness,
      'struggle': struggle,
      'frequency': frequency,
      'gender': gender,
    };
  }

  // Create from JSON
  factory UserAnswers.fromJson(Map<String, dynamic> json) {
    return UserAnswers(
      ageGroup: json['ageGroup'],
      closeness: json['closeness'],
      struggle: json['struggle'],
      frequency: json['frequency'],
      gender: json['gender'],
    );
  }

  // Copy with method for immutable updates
  UserAnswers copyWith({
    String? ageGroup,
    String? closeness,
    String? struggle,
    String? frequency,
    String? gender,
  }) {
    return UserAnswers(
      ageGroup: ageGroup ?? this.ageGroup,
      closeness: closeness ?? this.closeness,
      struggle: struggle ?? this.struggle,
      frequency: frequency ?? this.frequency,
      gender: gender ?? this.gender,
    );
  }

  @override
  String toString() {
    return 'UserAnswers(ageGroup: $ageGroup, closeness: $closeness, struggle: $struggle, frequency: $frequency, gender: $gender)';
  }
}
