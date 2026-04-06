import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../transactions/data/transaction_provider.dart';
import '../../transactions/models/transaction.dart';
import '../../goals/presentation/goal_widget.dart';
import '../../transactions/presentation/transaction_list_screen.dart';
import '../../../core/api_client.dart'; 
import '../../../main.dart'; 
import 'streak_card.dart';
import 'insights_screen.dart'; 
// Import your notification service provider
import '../../../core/notification_service.dart'; 

// --- 1. ROBUST STREAK PROVIDER ---
final streakProvider = FutureProvider<int>((ref) async {
  try {
    final response = await ApiClient.get('streak');
    // Adjusting to your specific response structure: response[0]['currentStreak']
    final rawValue = response.isNotEmpty ? response[0]['currentStreak'] : null;

    if (rawValue == null) return 0;
    
    if (rawValue is int) {
      return rawValue;
    } else {
      return int.tryParse(rawValue.toString()) ?? 0;
    }
  } catch (e) {
    debugPrint("Streak API Error: $e");
    return 0; 
  }
});

final searchProvider = StateProvider<String>((ref) => "");

class CurrencyFormatter {
  static final _rupeeFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static String format(double amount) => _rupeeFormat.format(amount);
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider);
    final streakState = ref.watch(streakProvider);
    final searchQuery = ref.watch(searchProvider);
    final themeMode = ref.watch(themeProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Finance Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => ref.read(themeProvider.notifier).state = 
                themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InsightsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () => _showTransactionForm(context, ref),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionProvider);
          ref.invalidate(streakProvider);
        },
        child: txState.when(
          loading: () => _buildGlobalLoading(isDark),
          error: (err, stack) => Center(child: Text("Connection Error: $err")),
          data: (List<Transaction> transactions) {
            final income = transactions.where((t) => t.type == 'income').fold(0.0, (p, t) => p + t.amount);
            final expense = transactions.where((t) => t.type == 'expense').fold(0.0, (p, t) => p + t.amount);
            
            final recentList = transactions
                .where((t) => t.title.toLowerCase().contains(searchQuery.toLowerCase()))
                .take(5).toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // --- SEARCH BAR ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: (val) => ref.read(searchProvider.notifier).state = val,
                      decoration: InputDecoration(
                        hintText: "Search transactions...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, 
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                      ),
                    ),
                  ),
                  
                  // --- STREAK CARD WITH SKELETON LOADING ---
                  streakState.when(
                    data: (val) => StreakCard(streak: val), 
                    loading: () => _buildSkeletonCard(height: 110, isDark: isDark),
                    error: (_, __) => const StreakCard(streak: 0),
                  ),
                  
                  _buildSummaryCard(context, income - expense, income, expense),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text("Spending vs Income", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  
                  SizedBox(height: 180, child: _buildPieChart(income, expense)),
                  
                  const GoalWidget(),
                  
                  _buildSectionHeader(context, "Recent History"),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentList.length,
                    itemBuilder: (context, index) {
                      final tx = recentList[index];
                      return _buildTransactionTile(context, ref, tx);
                    },
                  ),
                  const SizedBox(height: 80), 
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- LOADING / SKELETON UI ---

  Widget _buildGlobalLoading(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildSkeletonCard(height: 50, isDark: isDark), 
          _buildSkeletonCard(height: 110, isDark: isDark), 
          _buildSkeletonCard(height: 160, isDark: isDark), 
          _buildSkeletonCard(height: 200, isDark: isDark), 
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({required double height, required bool isDark}) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.white24 : Colors.black26),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionListScreen())), 
            child: const Text("View All")
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, WidgetRef ref, Transaction tx) {
    return ListTile(
      onTap: () => _showTransactionForm(context, ref, tx),
      onLongPress: () => _confirmDelete(context, ref, tx),
      leading: CircleAvatar(
        backgroundColor: tx.type == 'income' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        child: Icon(tx.type == 'income' ? Icons.add : Icons.remove, color: tx.type == 'income' ? Colors.green : Colors.red),
      ),
      title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("${tx.category} • ${DateFormat('yMMMd').format(tx.date)}"),
      trailing: Text(
        CurrencyFormatter.format(tx.amount), 
        style: TextStyle(color: tx.type == 'income' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double bal, double inc, double exp) {
    return Card(
      margin: const EdgeInsets.all(16), 
      elevation: 4, 
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20), 
        child: Column(children: [
          Text("Net Balance", style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7))),
          Text(CurrencyFormatter.format(bal), style: TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _statItem("Income", inc, Colors.green),
            _statItem("Expenses", exp, Colors.red),
          ])
        ])
      ),
    );
  }

  Widget _statItem(String l, double a, Color c) => Column(children: [
    Text(l, style: const TextStyle(fontSize: 12)), 
    Text(CurrencyFormatter.format(a), style: TextStyle(color: c, fontWeight: FontWeight.bold))
  ]);

  Widget _buildPieChart(double inc, double exp) => PieChart(PieChartData(sections: [
    PieChartSectionData(value: inc, color: Colors.green, showTitle: false, radius: 45), 
    PieChartSectionData(value: exp, color: Colors.red, showTitle: false, radius: 45)
  ]));

  // --- FORM WITH SAVING OVERLAY & NOTIFICATIONS ---

  void _showTransactionForm(BuildContext context, WidgetRef ref, [Transaction? tx]) {
    final titleController = TextEditingController(text: tx?.title ?? "");
    final amountController = TextEditingController(text: tx?.amount.toString() ?? "");
    final categoryController = TextEditingController(text: tx?.category ?? "");
    String selectedType = tx?.type ?? 'expense';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Description")),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹)")),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: "Category")),
              DropdownButton<String>(
                value: selectedType, isExpanded: true,
                items: const [DropdownMenuItem(value: 'expense', child: Text("Expense")), DropdownMenuItem(value: 'income', child: Text("Income"))],
                onChanged: (val) => setModalState(() => selectedType = val!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Show Saving Loader Overlay
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  final data = {
                    'description': titleController.text, 
                    'amount': double.tryParse(amountController.text) ?? 0.0,
                    'type': selectedType,
                    'category': categoryController.text.isEmpty ? 'General' : categoryController.text,
                  };
                  try {
                    if (tx != null) {
                      await ApiClient.put('transactions/${tx.id}', data);
                    } else {
                      await ApiClient.post('transactions', data);
                      
                      // TRIGGER NOTIFICATION IF EXPENSE
                      if (selectedType == 'expense') {
                        ref.read(notificationServiceProvider).showNotification(
                          title: "Streak Broken! 💸",
                          body: "You recorded an expense. Your streak has reset to Day 0.",
                        );
                      }
                    }
                    
                    ref.invalidate(transactionProvider);
                    ref.invalidate(streakProvider); 
                    
                    Navigator.pop(context); // Close Loader
                    Navigator.pop(context); // Close Form
                  } catch (e) {
                    Navigator.pop(context); // Close Loader
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text("Save"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Transaction tx) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Delete?"), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
        TextButton(onPressed: () async { 
          await ApiClient.delete('transactions/${tx.id}'); 
          ref.invalidate(transactionProvider); 
          ref.invalidate(streakProvider); 
          Navigator.pop(c); 
        }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
      ]
    ));
  }
}