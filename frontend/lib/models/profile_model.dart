class ProfileModel {
  final int? id;
  final int? userId;
  final int? age;
  final String? gender;
  final int? height;
  final double? weight;
  final double? targetWeight;
  final String? activityLevel;
  final String? bmi;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProfileModel({
    this.id,
    this.userId,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.targetWeight,
    this.activityLevel,
    this.bmi,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      height: json['height'] as int?,
      // ✅ String veya num gelebilir, ikisini de handle et
      weight: _parseDouble(json['weight']),
      targetWeight: _parseDouble(json['target_weight']),
      activityLevel: json['activity_level'] as String?,
      bmi: json['bmi'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  // ✅ Yardımcı fonksiyon: String veya num'u double'a çevir
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'target_weight': targetWeight,
      'activity_level': activityLevel,
    };
  }

  String getBmiCategory() {
    if (bmi == null) return '';
    final bmiValue = double.tryParse(bmi!);
    if (bmiValue == null) return '';
    
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  String getActivityLevelText() {
    switch (activityLevel) {
      case 'sedentary': return 'Sedentary (little or no exercise)';
      case 'lightly_active': return 'Lightly Active (1-3 days/week)';
      case 'moderately_active': return 'Moderately Active (3-5 days/week)';
      case 'very_active': return 'Very Active (6-7 days/week)';
      default: return 'Not set';
    }
  }
}