import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../widgets/stat_card.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dataService = DataService();
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
    final me = context.watch<AuthService>().user;
    final date = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sol taraf: Kullanıcı bilgileri - Expanded ile sınırla
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: TextStyle(color: Colors.grey.shade400)),
                    Text(
                      me?['name'] ?? 'User',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis, // Uzun isimler için
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Sağ taraf: Profil ve Sign Out butonları
              Row(
                mainAxisSize: MainAxisSize.min, // Minimum alan kapla
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                      _load();
                    },
                    icon: const Icon(Icons.person_outline),
                    tooltip: 'Profile',
                  ),
                  IconButton(
                    onPressed: () => context.read<AuthService>().logout(),
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign Out',
                  ),
                ],
              ),
            ],
          ),
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
                percent: (sum!['water']['percent'] as num).toDouble().clamp(0.0, 1.0),
              )),
              const SizedBox(width: 12),
              Expanded(child: StatCard(
                title: 'Steps',
                topRightIcon: '🦶',
                mainValue: '${sum!['steps']['count']}',
                subtitle: '/ ${sum!['steps']['goal']}',
                percent: (sum!['steps']['percent'] as num).toDouble().clamp(0.0, 1.0),
              )),
              const SizedBox(width: 12),
              Expanded(child: StatCard(
                title: 'Exercise',
                topRightIcon: '🏋️',
                mainValue: '${sum!['exercise']['calories']}',
                subtitle: ' / kcal burned',
                percent: (sum!['exercise']['percent'] as num).toDouble().clamp(0.0, 1.0),
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
                  LinearProgressIndicator(
                    value: (sum!['overall'] as num).toDouble().clamp(0.0, 1.0),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}