import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/transaction_provider.dart';
import '../models/transaction.dart';
import '../../dashboard/presentation/dashboard_screen.dart'; // To use CurrencyFormatter
import '../../../core/api_client.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Transactions"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: txState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (transactions) {
          final sortedList = List<Transaction>.from(transactions)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            itemCount: sortedList.length,
            itemBuilder: (context, index) {
              final tx = sortedList[index];
              return ListTile(
                // --- ENABLE EDITING ---
                onTap: () => _showTransactionForm(context, ref, tx),
                
                // --- ENABLE DELETION ---
                onLongPress: () => _confirmDelete(context, ref, tx),
                
                leading: CircleAvatar(
                  backgroundColor: tx.type == 'income' ? Colors.green[50] : Colors.red[50],
                  child: Icon(
                    tx.type == 'income' ? Icons.add : Icons.remove,
                    color: tx.type == 'income' ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${tx.category} • ${DateFormat('yMMMd').format(tx.date)}"),
                trailing: Text(
                  CurrencyFormatter.format(tx.amount),
                  style: TextStyle(
                    color: tx.type == 'income' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Form Logic (Same as Dashboard) ---
  void _showTransactionForm(BuildContext context, WidgetRef ref, Transaction tx) {
    final titleController = TextEditingController(text: tx.title);
    final amountController = TextEditingController(text: tx.amount.toString());
    String selectedType = tx.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit Transaction", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Description")),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹)")),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text("Expense")),
                  DropdownMenuItem(value: 'income', child: Text("Income")),
                ],
                onChanged: (val) => setModalState(() => selectedType = val!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                onPressed: () async {
                  final data = {
                    'description': titleController.text,
                    'amount': double.tryParse(amountController.text) ?? 0,
                    'type': selectedType,
                    'category': tx.category,
                    'date': tx.date.toIso8601String(),
                  };
                  try {
                    await ApiClient.put('transactions/${tx.id}', data);
                    ref.invalidate(transactionProvider);
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text("Update"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Transaction tx) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Transaction?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await ApiClient.delete('transactions/${tx.id}');
              ref.invalidate(transactionProvider);
              Navigator.pop(c);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}