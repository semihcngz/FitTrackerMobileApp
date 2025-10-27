import 'package:flutter/material.dart';
import '../../services/data_service.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});
  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  Map<String, dynamic>? s; bool loading = true; final customCtrl = TextEditingController();

  Future<void> _load() async { s = await dataService.getStepsToday(); setState(() => loading = false); }

  @override void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    final count = s?['count'] ?? 0;
    final goal = s?['goal'] ?? 10000;
    final percent = (goal == 0) ? 0.0 : (count / goal).clamp(0, 1).toDouble();
    final distance = (s?['distanceKm'] ?? 0.0).toStringAsFixed(2);
    final calories = (s?['calories'] ?? 0).toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Step Counter')),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.directions_walk), SizedBox(width: 8), Text("Today's Steps", style: TextStyle(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                Text('Keep moving to reach your daily goal', style: TextStyle(color: Colors.grey.shade400)),
                const SizedBox(height: 16),
                Center(child: Column(children: [
                  Text('$count', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  const Text('steps'),
                ])),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: percent, minHeight: 8, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 6),
                Center(child: Text('$count / $goal steps', style: TextStyle(color: Colors.grey.shade400))),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _miniStat('Distance', '$distance km'),
                  _miniStat('Calories', '$calories kcal'),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Add Steps', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Manually log your steps', style: TextStyle(color: Colors.grey.shade400)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () async { await dataService.addSteps(100); await _load(); }, child: const Text('+ 100'))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: () async { await dataService.addSteps(500); await _load(); }, child: const Text('+ 500'))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: () async { await dataService.addSteps(1000); await _load(); }, child: const Text('+ 1000'))),
                ]),
                const SizedBox(height: 12),
                Text('Custom amount', style: TextStyle(color: Colors.grey.shade400)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(controller: customCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Enter steps'))),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: () async {
                    final v = int.tryParse(customCtrl.text.trim());
                    if (v != null && v > 0) { await dataService.addSteps(v); customCtrl.clear(); await _load(); }
                  }, child: const Text('Add')),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String t, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t, style: TextStyle(color: Colors.grey.shade400)),
    const SizedBox(height: 4),
    Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
  ]);
}
