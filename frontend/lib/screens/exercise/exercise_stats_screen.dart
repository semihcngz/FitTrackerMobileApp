import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/data_service.dart';

class ExerciseStatsScreen extends StatefulWidget {
  const ExerciseStatsScreen({super.key});

  @override
  State createState() => _ExerciseStatsScreenState();
}

class _ExerciseStatsScreenState extends State {
  final dataService = DataService();
  int weekOffset = 0; // 0=bu hafta, 1=geçen hafta, 2=2 hafta önce
  Map<String, dynamic>? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future _loadStats() async {
    setState(() => loading = true);
    try {
      final data = await dataService.getExerciseWeeklyStats(weekOffset: weekOffset);
      setState(() {
        stats = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    }
  }

  void _previousWeek() {
    if (weekOffset < 3) {
      setState(() => weekOffset++);
      _loadStats();
    }
  }

  void _nextWeek() {
    if (weekOffset > 0) {
      setState(() => weekOffset--);
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Statistics'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Week Navigation
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: weekOffset < 3 ? _previousWeek : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _getWeekTitle(),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getWeekDateRange(),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: weekOffset > 0 ? _nextWeek : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Cards
                  Builder(
                    builder: (context) {
                      final summary = stats?['summary'] as Map<String, dynamic>?;
                      final totalCalories = summary?['totalCalories'] ?? 0;
                      final avgCalories = summary?['avgCaloriesPerDay'] ?? 0;
                      final activeDays = summary?['activeDays'] ?? 0;
                      final totalMinutes = summary?['totalMinutes'] ?? 0;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _summaryCard(
                                  'Total Calories',
                                  '$totalCalories',
                                  'kcal',
                                  Icons.local_fire_department,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _summaryCard(
                                  'Avg/Day',
                                  '$avgCalories',
                                  'kcal',
                                  Icons.trending_up,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _summaryCard(
                                  'Active Days',
                                  '$activeDays',
                                  'days',
                                  Icons.calendar_today,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _summaryCard(
                                  'Total Time',
                                  '$totalMinutes',
                                  'min',
                                  Icons.access_time,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Chart Title
                  const Text(
                    'Daily Calories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  // Bar Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 300,
                        child: _buildBarChart(),
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildBarChart() {
    final days = (stats?['days'] as List<dynamic>?) ?? [];
    
    if (days.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxCalories = days
        .map((d) => (d['totalCalories'] as num?)?.toInt() ?? 0)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCalories > 0 ? maxCalories * 1.2 : 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = days[group.x.toInt()];
              return BarTooltipItem(
                '${day['dayName']}\n${rod.toY.toInt()} kcal',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  final day = days[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      day['dayName'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxCalories > 0 ? maxCalories / 5 : 20,
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          days.length,
          (index) {
            final calories = (days[index]['totalCalories'] as num?)?.toDouble() ?? 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: calories,
                  color: _getBarColor(index),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getBarColor(int index) {
    // Bugün farklı renk
    if (weekOffset == 0 && index == DateTime.now().weekday % 7) {
      return Colors.orange;
    }
    return Colors.blue;
  }

  String _getWeekTitle() {
    switch (weekOffset) {
      case 0:
        return 'This Week';
      case 1:
        return 'Last Week';
      case 2:
        return '2 Weeks Ago';
      case 3:
        return '3 Weeks Ago';
      default:
        return 'Week';
    }
  }

  String _getWeekDateRange() {
    final summary = stats?['summary'] as Map<String, dynamic>?;
    if (summary == null) return '';
    final start = summary['startDate'];
    final end = summary['endDate'];
    return '$start - $end';
  }
}