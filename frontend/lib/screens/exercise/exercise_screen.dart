import 'package:flutter/material.dart';
import '../../services/data_service.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});
  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final dataService = DataService();
  Map<String, dynamic>? e; bool loading = true;
  final types = const ['Cardio', 'Strength', 'Flexibility'];
  String type = 'Cardio'; String? activity;
  final minutesCtrl = TextEditingController(text: '30');
  final calCtrl = TextEditingController(text: '200');

  List<String> _getActivitiesForType(String exerciseType) {
    switch (exerciseType) {
      case 'Cardio':
        return ['Running', 'Cycling', 'Jump Rope'];
      case 'Strength':
        return ['Push-ups', 'Squats', 'Deadlift'];
      case 'Flexibility':
        return ['Yoga', 'Stretching'];
      default:
        return [];
    }
  }

  Future<void> _load() async { e = await dataService.getExerciseToday(); setState(() => loading = false); }

  @override void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    final time = e?['minutes'] ?? 0;
    final cal = e?['calories'] ?? 0;
    final exercisesList = (e?['list'] as List<dynamic>? ?? []);
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Tracker')),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: _topCard('Total Time', '$time', 'minutes today', Icons.access_time)),
            const SizedBox(width: 12),
            Expanded(child: _topCard('Calories Burned', '$cal', 'kcal today', Icons.local_fire_department)),
          ]),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.add), SizedBox(width: 8), Text('Add Exercise', style: TextStyle(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  items: types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) {
                    setState(() {
                      type = v!;
                      // Reset activity when type changes
                      final availableActivities = _getActivitiesForType(type);
                      if (activity == null || !availableActivities.contains(activity)) {
                        activity = null;
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Exercise Type'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: activity,
                  items: _getActivitiesForType(type)
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => activity = v),
                  decoration: const InputDecoration(labelText: 'Activity'),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Flexible(child: TextField(controller: minutesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (minutes)'))),
                  const SizedBox(width: 8),
                  Flexible(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories Burned'))),
                ]),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    if (activity == null) return;
                    await dataService.addExercise(
                      type: type,
                      activity: activity!,
                      minutes: int.tryParse(minutesCtrl.text) ?? 0,
                      calories: int.tryParse(calCtrl.text) ?? 0,
                    );
                    // Reset form after adding exercise
                    setState(() {
                      activity = null;
                      minutesCtrl.text = '30';
                      calCtrl.text = '200';
                    });
                    await _load();
                  },
                  child: const Text('Add Exercise'),
                )
              ]),
            ),
          ),
          const SizedBox(height: 16),
          if (exercisesList.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.list, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text('Today\'s Exercises', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            ]),
            const SizedBox(height: 12),
            ...exercisesList.map((exercise) => _exerciseItem(exercise)).toList(),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _topCard(String t, String v, String sub, IconData ic) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Icon(ic),
          ],
        ),
        const SizedBox(height: 12),
        Text(v, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        Text(sub, style: TextStyle(color: Colors.grey.shade400)),
      ]),
    ),
  );

  Widget _exerciseItem(dynamic exercise) {
    final activity = exercise['activity'] ?? 'Unknown';
    final type = exercise['type'] ?? '';
    final minutes = exercise['minutes'] ?? 0;
    final calories = exercise['calories'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTypeColor(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getTypeIcon(type), color: _getTypeColor(type)),
        ),
        title: Text(
          activity,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(type),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$minutes min',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '$calories kcal',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Cardio':
        return Colors.red;
      case 'Strength':
        return Colors.blue;
      case 'Flexibility':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Cardio':
        return Icons.directions_run;
      case 'Strength':
        return Icons.fitness_center;
      case 'Flexibility':
        return Icons.self_improvement;
      default:
        return Icons.sports;
    }
  }
}
