import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? sum;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await dataService.getTodaySummary();
    setState(() { sum = s; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthService>().me;
    final date = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome back,', style: TextStyle(color: Colors.grey.shade400)),
              Text(me?['name'] ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(color: Colors.grey.shade500)),
            ]),
            TextButton.icon(onPressed: () => context.read<AuthService>().logout(), icon: const Icon(Icons.person), label: const Text('Sign Out')),
          ]),
          const SizedBox(height: 16),
          if (loading) const LinearProgressIndicator(),
          if (!loading && sum != null) ...[
            // Top 3 cards
            Row(children: [
              Expanded(child: StatCard(
                title: 'Water Intake',
                topRightIcon: '💧',
                mainValue: '${sum!['water']['count']}',
                subtitle: '/ ${sum!['water']['goal']} glasses',
                percent: (sum!['water']['percent'] as num).toDouble(),
              )),
              const SizedBox(width: 12),
              Expanded(child: StatCard(
                title: 'Steps',
                topRightIcon: '🦶',
                mainValue: '${sum!['steps']['count']}',
                subtitle: '/ ${sum!['steps']['goal']}',
                percent: (sum!['steps']['percent'] as num).toDouble(),
              )),
              const SizedBox(width: 12),
              Expanded(child: StatCard(
                title: 'Exercise',
                topRightIcon: '🏋️',
                mainValue: '${sum!['exercise']['count']}',
                subtitle: 'activities',
                percent: (sum!['exercise']['percent'] as num).toDouble(),
              )),
            ]),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Today's Summary", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Your progress at a glance', style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.radio_button_checked, size: 18),
                    const SizedBox(width: 8),
                    const Text('Overall Progress'),
                    const Spacer(),
                    Text('${((sum!['overall'] as num).toDouble() * 100).toStringAsFixed(0)}%'),
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: (sum!['overall'] as num).toDouble(), minHeight: 8, borderRadius: BorderRadius.circular(8)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
