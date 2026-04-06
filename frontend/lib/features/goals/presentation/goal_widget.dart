import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import '../../transactions/data/transaction_provider.dart';

// 1. Centralized Formatter - Ensures ₹ is used everywhere
class CurrencyFormatter {
  static String format(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN', 
      symbol: '₹',     
      decimalDigits: 0,
    ).format(amount);
  }
}

// 2. Goal Provider
final savingsGoalProvider = StateProvider<double>((ref) => 50000.0);

class GoalWidget extends ConsumerWidget {
  const GoalWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(savingsGoalProvider);
    final txState = ref.watch(transactionProvider);

    return txState.when(
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (err, stack) => const SizedBox.shrink(),
      data: (transactions) {
        // Calculate Savings
        final income = transactions
            .where((t) => t.type == 'income')
            .fold(0.0, (p, t) => p + t.amount);
        final expense = transactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (p, t) => p + t.amount);
        
        final savings = income - expense;
        double progress = (goal > 0) ? (savings / goal).clamp(0.0, 1.0) : 0.0;
        double percentage = progress * 100;

        return Card(
          elevation: 0, // Matches the flat look in your screenshot
          color: Colors.transparent, 
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Monthly Savings Progress", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
              const SizedBox(height: 16),
              
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: Colors.indigo[700],
                  minHeight: 12,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // THE FIXED TEXT LINE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      // We removed \$ and used CurrencyFormatter.format(goal)
                      "${percentage.toStringAsFixed(1)}% of ${CurrencyFormatter.format(goal)} goal reached",
                      style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit, size: 18, color: Colors.indigo),
                    onPressed: () => _showEditGoalDialog(context, ref, goal),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditGoalDialog(BuildContext context, WidgetRef ref, double currentGoal) {
    final controller = TextEditingController(text: currentGoal.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Savings Goal"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: "₹ ", 
            border: OutlineInputBorder(),
            labelText: "Target Amount",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700]),
            onPressed: () {
              final newGoal = double.tryParse(controller.text) ?? currentGoal;
              ref.read(savingsGoalProvider.notifier).state = newGoal;
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}