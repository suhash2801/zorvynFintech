class TransactionModel {
  final String id;
  final double amount;
  final String type;
  final String category;
  final DateTime date;

  TransactionModel({required this.id, required this.amount, required this.type, required this.category, required this.date});

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'],
      amount: json['amount'].toDouble(),
      type: json['type'],
      category: json['category'],
      date: DateTime.parse(json['date']),
    );
  }
}