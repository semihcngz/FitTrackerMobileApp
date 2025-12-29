import 'package:flutter/material.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final ProfileModel? profile;

  const ProfileEditScreen({super.key, this.profile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;

  String? _gender;
  String? _activityLevel;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.profile?.age?.toString() ?? '');
    _heightController = TextEditingController(text: widget.profile?.height?.toString() ?? '');
    _weightController = TextEditingController(text: widget.profile?.weight?.toString() ?? '');
    _targetWeightController = TextEditingController(text: widget.profile?.targetWeight?.toString() ?? '');
    _gender = widget.profile?.gender;
    _activityLevel = widget.profile?.activityLevel;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);

  try {
    print('📤 Sending data:');  // ← DEBUG
    print('age: ${int.parse(_ageController.text)}');
    print('gender: $_gender');
    print('height: ${int.parse(_heightController.text)}');
    print('weight: ${double.parse(_weightController.text)}');
    print('target_weight: ${_targetWeightController.text.isNotEmpty ? double.parse(_targetWeightController.text) : null}');
    print('activity_level: $_activityLevel');

    final profile = await _profileService.upsertProfile(
      age: int.parse(_ageController.text),
      gender: _gender!,
      height: int.parse(_heightController.text),
      weight: double.parse(_weightController.text),
      targetWeight: _targetWeightController.text.isNotEmpty 
          ? double.parse(_targetWeightController.text) 
          : null,
      activityLevel: _activityLevel,
    );

    print('📥 Response profile: $profile');  // ← DEBUG

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
      Navigator.pop(context, true);
    }
  } catch (e, stackTrace) {
    print('❌ Error: $e');  // ← DEBUG
    print('Stack trace: $stackTrace');  // ← DEBUG
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? 'Create Profile' : 'Edit Profile'),
        actions: [
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ))
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Age
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                suffixText: 'years',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final age = int.tryParse(v);
                if (age == null || age < 1 || age > 120) return 'Invalid age';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Height
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height',
                border: OutlineInputBorder(),
                suffixText: 'cm',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final height = int.tryParse(v);
                if (height == null || height < 50 || height > 300) return 'Invalid height';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Weight
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Current Weight',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final weight = double.tryParse(v);
                if (weight == null || weight < 20 || weight > 300) return 'Invalid weight';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Target Weight
            TextFormField(
              controller: _targetWeightController,
              decoration: const InputDecoration(
                labelText: 'Target Weight (Optional)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final weight = double.tryParse(v);
                if (weight == null || weight < 20 || weight > 300) return 'Invalid weight';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Activity Level
            DropdownButtonFormField<String>(
              value: _activityLevel,
              decoration: const InputDecoration(
                labelText: 'Activity Level',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'sedentary', child: Text('Sedentary (little or no exercise)')),
                DropdownMenuItem(value: 'lightly_active', child: Text('Lightly Active (1-3 days/week)')),
                DropdownMenuItem(value: 'moderately_active', child: Text('Moderately Active (3-5 days/week)')),
                DropdownMenuItem(value: 'very_active', child: Text('Very Active (6-7 days/week)')),
              ],
              onChanged: (v) => setState(() => _activityLevel = v),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _loading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}