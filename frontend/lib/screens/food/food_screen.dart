import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/data_service.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State createState() => _FoodScreenState();
}

class _FoodScreenState extends State {
  final dataService = DataService();
  final picker = ImagePicker();
  Map? foodData;
  bool loading = true;
  bool analyzing = false;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future _loadToday() async {
    setState(() => loading = true);
    try {
      final data = await dataService.getTodayFood();
      setState(() {
        foodData = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source, String mealType) async {
  try {
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 800,   // ← 1024'ten 800'e düşürdük
      maxHeight: 800,  // ← 1024'ten 800'e düşürdük
      imageQuality: 70, // ← 85'ten 70'e düşürdük (daha fazla sıkıştırma)
    );

    if (image == null) return;

    setState(() => analyzing = true);

    // Base64'e çevir
    final bytes = await File(image.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    print('📸 Image size: ${bytes.length} bytes'); // ← DEBUG

    // API'ye gönder
    final result = await dataService.analyzeFood(base64Image, mealType: mealType);

    setState(() => analyzing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food analyzed successfully!')),
      );
      _loadToday();
    }
  } catch (e) {
    setState(() => analyzing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

  Future _deleteFood(int id) async {
    try {
      await dataService.deleteFood(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted')),
        );
        _loadToday();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAddFoodOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add Food', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _showMealTypeDialog(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _showMealTypeDialog(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMealTypeDialog(ImageSource source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Meal Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('🌅 Breakfast'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(source, 'breakfast');
              },
            ),
            ListTile(
              title: const Text('🌞 Lunch'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(source, 'lunch');
              },
            ),
            ListTile(
              title: const Text('🌙 Dinner'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(source, 'dinner');
              },
            ),
            ListTile(
              title: const Text('🍎 Snack'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(source, 'snack');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = (foodData?['logs'] as List?) ?? [];
    final total = foodData?['total'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Tracker'),
      ),
      body: analyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing food...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadToday,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary Cards
                      if (total != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                'Total Calories',
                                '${total['calories']}',
                                'kcal',
                                Icons.local_fire_department,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                'Protein',
                                '${total['protein']}',
                                'g',
                                Icons.fitness_center,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                'Carbs',
                                '${total['carbs']}',
                                'g',
                                Icons.grain,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                'Fat',
                                '${total['fat']}',
                                'g',
                                Icons.water_drop,
                                Colors.yellow.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Food List
                      if (logs.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 48),
                              Icon(Icons.restaurant, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No food logged today',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showAddFoodOptions,
                                icon: const Icon(Icons.add_a_photo),
                                label: const Text('Add First Meal'),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Icon(Icons.restaurant_menu, size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Today\'s Meals',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...logs.map((log) => _foodItem(log)).toList(),
                      ],
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoodOptions,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Food'),
      ),
    );
  }

  Widget _summaryCard(String title, String value, String unit, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodItem(dynamic log) {
    final foodName = log['food_name'] ?? 'Unknown';
    final description = log['description'] ?? '';
    final calories = log['calories'] ?? 0;
    final protein = log['protein'] ?? 0;
    final carbs = log['carbs'] ?? 0;
    final fat = log['fat'] ?? 0;
    final mealType = log['meal_type'] ?? 'snack';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMealTypeColor(mealType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getMealTypeEmoji(mealType),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foodName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteFood(log['id']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _nutrientChip('🔥 $calories kcal', Colors.orange),
                const SizedBox(width: 8),
                _nutrientChip('🥩 ${protein}g protein', Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _nutrientChip('🍞 ${carbs}g carbs', Colors.blue),
                const SizedBox(width: 8),
                _nutrientChip('🧈 ${fat}g fat', Colors.yellow.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutrientChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _getMealTypeColor(String type) {
    switch (type) {
      case 'breakfast': return Colors.orange;
      case 'lunch': return Colors.green;
      case 'dinner': return Colors.blue;
      case 'snack': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getMealTypeEmoji(String type) {
    switch (type) {
      case 'breakfast': return '🌅';
      case 'lunch': return '🌞';
      case 'dinner': return '🌙';
      case 'snack': return '🍎';
      default: return '🍽️';
    }
  }
}