import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String topRightIcon; // emoji hızlı çözüm: 💧, 🦶, 🏋️
  final String mainValue;
  final String? subtitle;
  final double percent; // 0..1

  const StatCard({
    super.key,
    required this.title,
    required this.topRightIcon,
    required this.mainValue,
    this.subtitle,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(topRightIcon),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(mainValue, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Text(subtitle!, style: TextStyle(color: Colors.grey.shade400))
            ]
          ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: percent.clamp(0, 1), minHeight: 6, borderRadius: BorderRadius.circular(8)),
        ]),
      ),
    );
  }
}
