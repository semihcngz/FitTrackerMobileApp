import '../models/profile_model.dart';
import 'api_client.dart';

class ProfileService {
  final _api = ApiClient.instance;

  Future<ProfileModel?> getProfile() async {
    final res = await _api.getJson('/api/profile');
    final profileData = res['profile'];
    if (profileData == null) return null;
    return ProfileModel.fromJson(profileData as Map<String, dynamic>);
  }

  Future<ProfileModel> upsertProfile({
    required int age,
    required String gender,
    required int height,
    required double weight,
    double? targetWeight,
    String? activityLevel,
  }) async {
    final res = await _api.postJson('/api/profile', {
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'target_weight': targetWeight,
      'activity_level': activityLevel,
    });
    return ProfileModel.fromJson(res['profile'] as Map<String, dynamic>);
  }

  Future<ProfileModel> updateWeight(double weight) async {
    final res = await _api.postJson('/api/profile/weight', {
      'weight': weight,
    });
    return ProfileModel.fromJson(res['profile'] as Map<String, dynamic>);
  }
}