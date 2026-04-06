import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/transaction_model.dart';

final financeProvider = StateNotifierProvider<FinanceNotifier, List<TransactionModel>>((ref) => FinanceNotifier());

class FinanceNotifier extends StateNotifier<List<TransactionModel>> {
  FinanceNotifier() : super([]) { fetchAll(); }

  final String api = "http://10.0.2.2:3000/transactions"; // Use your local IP or 10.0.2.2 for Android

  Future<void> fetchAll() async {
    final res = await http.get(Uri.parse(api));
    if (res.statusCode == 200) {
      List data = json.decode(res.body);
      state = data.map((e) => TransactionModel.fromJson(e)).toList();
    }
  }

  Future<void> add(Map<String, dynamic> data) async {
    await http.post(Uri.parse(api), body: json.encode(data), headers: {"Content-Type": "application/json"});
    fetchAll();
  }

  Future<void> delete(String id) async {
    await http.delete(Uri.parse("$api/$id"));
    fetchAll();
  }
}