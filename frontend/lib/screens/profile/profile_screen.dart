import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  ProfileModel? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _profileService.getProfile();
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileEditScreen(profile: _profile),
                  ),
                );
                if (result == true) _loadProfile();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // User Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              (user?['name'] as String? ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 32, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?['name'] as String? ?? 'User',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user?['email'] as String? ?? '',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Info
                  if (_profile == null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No profile information',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileEditScreen(),
                                  ),
                                );
                                if (result == true) _loadProfile();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Profile'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // BMI Card
                    if (_profile!.bmi != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Body Mass Index (BMI)', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _profile!.bmi!,
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                  ),
                                  Chip(
                                    label: Text(_profile!.getBmiCategory()),
                                    backgroundColor: _getBmiColor(_profile!.bmi!),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Physical Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Physical Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 16),
                            _buildInfoRow('Age', '${_profile!.age ?? '-'} years'),
                            _buildInfoRow('Gender', _profile!.gender ?? '-'),
                            _buildInfoRow('Height', '${_profile!.height ?? '-'} cm'),
                            _buildInfoRow('Weight', '${_profile!.weight ?? '-'} kg'),
                            if (_profile!.targetWeight != null)
                              _buildInfoRow('Target Weight', '${_profile!.targetWeight} kg'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Activity Level
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Activity Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 12),
                            Text(_profile!.getActivityLevelText()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getBmiColor(String bmi) {
    final bmiValue = double.tryParse(bmi);
    if (bmiValue == null) return Colors.grey;
    if (bmiValue < 18.5) return Colors.blue.shade100;
    if (bmiValue < 25) return Colors.green.shade100;
    if (bmiValue < 30) return Colors.orange.shade100;
    return Colors.red.shade100;
  }
}