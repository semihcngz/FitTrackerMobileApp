import 'package:flutter/material.dart';
import '../water/water_screen.dart';
import '../steps/steps_screen.dart';
import '../exercise/exercise_screen.dart';
import '../food/food_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int i = 0;
  final pages = const [HomeScreen(), WaterScreen(), StepsScreen(), ExerciseScreen(), FoodScreen(),];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[i]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.local_drink_outlined), selectedIcon: Icon(Icons.local_drink), label: 'Water'),
          NavigationDestination(icon: Icon(Icons.directions_walk_outlined), selectedIcon: Icon(Icons.directions_walk), label: 'Steps'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Exercise'),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined), 
            selectedIcon: Icon(Icons.restaurant), 
            label: 'Food'
          ),
        ],
      ),
    );
  }
}
