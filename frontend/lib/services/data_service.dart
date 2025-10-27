// lib/services/data_service.dart
// Backend YOKKEN kullanılacak mock servis.
// Ekranları doldurur, hiçbir HTTP isteği atmaz.

class DataService {
  // --- DASHBOARD
  Future<Map<String, dynamic>> getTodaySummary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      "water": {"count": 3, "goal": 8, "percent": 3 / 8},
      "steps": {"count": 4500, "goal": 10000, "percent": 0.45, "distanceKm": 3.2, "calories": 180},
      "exercise": {"count": 2, "minutes": 45, "calories": 260, "percent": 0.45},
      "overall": 0.42
    };
  }

  // --- WATER
  int _waterCount = 3;
  int _waterGoal = 8;

  Future<Map<String, dynamic>> getWaterToday() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return {"count": _waterCount, "goal": _waterGoal};
  }

  Future<void> addWater(int glasses) async {
    _waterCount = (_waterCount + glasses).clamp(0, 99);
    await Future.delayed(const Duration(milliseconds: 120));
  }

  Future<void> setWaterGoal(int glasses) async {
    _waterGoal = glasses.clamp(1, 30);
    await Future.delayed(const Duration(milliseconds: 120));
  }

  // --- STEPS
  int _steps = 4500;
  int _stepsGoal = 10000;

  Future<Map<String, dynamic>> getStepsToday() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final distanceKm = _steps * 0.0007; // kaba tahmin
    final calories = (_steps * 0.04).toInt();
    return {"count": _steps, "goal": _stepsGoal, "distanceKm": distanceKm, "calories": calories};
  }

  Future<void> addSteps(int count) async {
    _steps = (_steps + count).clamp(0, 100000);
    await Future.delayed(const Duration(milliseconds: 120));
  }

  Future<void> setStepsGoal(int count) async {
    _stepsGoal = count.clamp(1000, 50000);
    await Future.delayed(const Duration(milliseconds: 120));
  }

  // --- EXERCISE
  final List<Map<String, dynamic>> _exerciseList = [
    {"type": "Cardio", "activity": "Running", "minutes": 30, "calories": 200},
  ];

  Future<Map<String, dynamic>> getExerciseToday() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final minutes = _exerciseList.fold<int>(0, (s, e) => s + (e['minutes'] as int));
    final calories = _exerciseList.fold<int>(0, (s, e) => s + (e['calories'] as int));
    return {"minutes": minutes, "calories": calories, "count": _exerciseList.length, "list": List.of(_exerciseList)};
  }

  Future<void> addExercise({
    required String type,
    required String activity,
    required int minutes,
    required int calories,
  }) async {
    _exerciseList.insert(0, {
      "type": type,
      "activity": activity,
      "minutes": minutes,
      "calories": calories,
    });
    await Future.delayed(const Duration(milliseconds: 120));
  }
}

final dataService = DataService();
