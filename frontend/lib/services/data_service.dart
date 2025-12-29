// lib/services/data_service.dart
import 'api_client.dart';

class DataService {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getTodaySummary() async {
    final res = await _api.getJson('/api/dashboard/today');
    return res; // { water: {count,goal,percent}, steps: {...}, exercise: {...}, overall: ... }
  }

  Future<Map<String, dynamic>> getWaterToday() async {
    final res = await _api.getJson('/api/water/today');
    return res; // {count, goal}
  }

  Future<Map<String, dynamic>> addWater({int glasses = 1}) async {
    final res = await _api.postJson('/api/water/add', {'glasses': glasses});
    return res; // {count, goal}
  }

  Future<Map<String, dynamic>> setWaterGoal(int goal) async {
    final res = await _api.postJson('/api/water/goal', {'goal': goal});
    return res; // {count, goal}
  }

  Future<Map<String, dynamic>> getStepsToday() async {
    final res = await _api.getJson('/api/steps/today');
    return res; // {count, goal, distanceKm, calories}
  }

  Future<Map<String, dynamic>> addSteps(int steps) async {
    final res = await _api.postJson('/api/steps/add', {'steps': steps});
    return res; // {count, goal, distanceKm, calories}
  }

  Future<Map<String, dynamic>> getExerciseToday() async {
    final res = await _api.getJson('/api/exercise/today');
    return res; // {minutes, calories, list: [...]}
  }

  Future<Map<String, dynamic>> addExercise({
    required String type,
    required String activity,
    required int minutes,
    required int calories,
  }) async {
    final res = await _api.postJson('/api/exercise/add', {
      'type': type,
      'activity': activity,
      'minutes': minutes,
      'calories': calories,
    });
    return res; // {minutes, calories, list: [...]}
  }

  Future<Map<String, dynamic>> getExerciseWeeklyStats({int weekOffset = 0}) async {
    final res = await _api.getJson('/api/exercise/stats/weekly?week_offset=$weekOffset');
    return res;
  }

  Future<Map> analyzeFood(String imageBase64, {String? mealType}) async {
  final res = await _api.postJson('/api/food/analyze', {
    'image_base64': imageBase64,
    'meal_type': mealType,
  });
  return res;
}

Future<Map> getTodayFood() async {
  final res = await _api.getJson('/api/food/today');
  return res;
}

Future deleteFood(int id) async {
  await _api.deleteJson('/api/food/$id');
}
}
