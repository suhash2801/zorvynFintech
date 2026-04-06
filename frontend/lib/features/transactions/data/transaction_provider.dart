import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../models/transaction.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>((ref) {
  return TransactionNotifier();
});

class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  TransactionNotifier() : super(const AsyncLoading()) {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final data = await ApiClient.get("/transactions");
      state = AsyncValue.data(data.map((e) => Transaction.fromJson(e)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(double amount, String type, String category) async {
    await ApiClient.post("/transactions", {
      "amount": amount,
      "type": type,
      "category": category,
    });
    fetchTransactions(); // Refresh list
  }
}