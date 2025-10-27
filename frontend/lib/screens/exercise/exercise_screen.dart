import 'package:flutter/material.dart';
import '../../services/data_service.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});
  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  Map<String, dynamic>? e; bool loading = true;
  final types = const ['Cardio', 'Strength', 'Flexibility'];
  String type = 'Cardio'; String? activity;
  final minutesCtrl = TextEditingController(text: '30');
  final calCtrl = TextEditingController(text: '200');

  Future<void> _load() async { e = await dataService.getExerciseToday(); setState(() => loading = false); }

  @override void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    final time = e?['minutes'] ?? 0;
    final cal = e?['calories'] ?? 0;
    final list = (e?['list'] as List<dynamic>? ?? []);

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
                  onChanged: (v) => setState(() => type = v!),
                  decoration: const InputDecoration(labelText: 'Exercise Type'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: activity,
                  items: (type == 'Cardio'
                          ? ['Running', 'Cycling', 'Jump Rope']
                          : type == 'Strength'
                              ? ['Push-ups', 'Squats', 'Deadlift']
                              : ['Yoga', 'Stretching'])
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => activity = v),
                  decoration: const InputDecoration(labelText: 'Activity'),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: minutesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (minutes)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories Burned'))),
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
                    await _load();
                  },
                  child: const Text('Add Exercise'),
                )
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.sports_gymnastics), SizedBox(width: 8), Text("Today's Activities", style: TextStyle(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 12),
                if (list.isEmpty) Text('0 activities logged', style: TextStyle(color: Colors.grey.shade400)),
                for (final a in list) Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Text('${a['activity']} · ${a['minutes']}m · ${a['calories']} kcal'),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topCard(String t, String v, String sub, IconData ic) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w600)), Icon(ic)]),
        const SizedBox(height: 12),
        Text(v, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        Text(sub, style: TextStyle(color: Colors.grey.shade400)),
      ]),
    ),
  );
}
