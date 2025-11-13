import 'package:flutter/material.dart';
import '../../services/data_service.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});
  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final dataService = DataService();
  Map<String, dynamic>? w;
  bool loading = true;
  final goalCtrl = TextEditingController();

  Future<void> _load() async {
    final res = await dataService.getWaterToday();
    setState(() { w = res; loading = false; goalCtrl.text = '${w!['goal']}'; });
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    final count = w?['count'] ?? 0;
    final goal = w?['goal'] ?? 8;
    final percent = (goal == 0) ? 0.0 : (count / goal).clamp(0, 1).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Water Intake')),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(
                  children: [Icon(Icons.water_drop), SizedBox(width: 8), Text("Today's Water Intake", style: TextStyle(fontWeight: FontWeight.w600))],
                ),
                const SizedBox(height: 8),
                Text('Stay hydrated throughout the day', style: TextStyle(color: Colors.grey.shade400)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(onPressed: () async { await dataService.addWater(glasses: -1); await _load(); }, icon: const Icon(Icons.remove_circle_outline, size: 28)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(children: [
                      Text('$count', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                      const Text('glasses')
                    ]),
                  ),
                  IconButton(onPressed: () async { await dataService.addWater(glasses: 1); await _load(); }, icon: const Icon(Icons.add_circle_outline, size: 28)),
                ]),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: percent, minHeight: 8, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 6),
                Center(child: Text('$count / $goal glasses', style: TextStyle(color: Colors.grey.shade400))),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Daily Goal', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Set your daily water intake target', style: TextStyle(color: Colors.grey.shade400)),
                const SizedBox(height: 16),
                TextField(controller: goalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Glasses per day')),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () async {
                      final g = int.tryParse(goalCtrl.text.trim());
                      if (g != null && g > 0) { await dataService.setWaterGoal(g); await _load(); }
                    },
                    child: const Text('Update Goal'),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Recommended: 8 glasses (2 liters) per day', style: TextStyle(color: Colors.grey.shade500)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _slotCard('Morning', 'Target: 3 glasses')),
            const SizedBox(width: 12),
            Expanded(child: _slotCard('Afternoon', 'Target: 4 glasses')),
            const SizedBox(width: 12),
            Expanded(child: _slotCard('Evening', 'Target: 3 glasses')),
          ])
        ],
      ),
    );
  }

  Widget _slotCard(String t, String s) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8), Text(s, style: TextStyle(color: Colors.grey.shade400))])));
}
