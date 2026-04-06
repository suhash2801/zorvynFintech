import 'package:flutter/material.dart';

class StreakCard extends StatelessWidget {
  final int streak;

  // The constructor can be const, but the build method cannot use const for dynamic values
  const StreakCard({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final bool isActive = streak > 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive 
            ? [Colors.orangeAccent, Colors.deepOrange] 
            : [Colors.blueGrey.shade400, Colors.blueGrey.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // Removed const here because of .withOpacity()
            color: isActive 
              ? Colors.orange.withOpacity(0.3) 
              : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? "NO-SPEND STREAK" : "STREAK RESET",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isActive ? "$streak Days Clean!" : "Day 0: Spent Today",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            isActive ? Icons.local_fire_department : Icons.eco_rounded,
            color: Colors.white,
            size: 50,
          ),
        ],
      ),
    );
  }
}