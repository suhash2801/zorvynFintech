class Transaction {
  final String id;
  final String title; 
  final double amount;
  final String type;
  final String category;
  final DateTime date;
  final String description;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.description,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? '',
      title: json['description'] ?? json['title'] ?? 'Unnamed', 
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'expense',
      category: json['category'] ?? 'General',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      description: json['description'] ?? 'No description',
    );
  }

  Map<String, dynamic> toJson() => {
    'description': title, 
    'amount': amount,
    'type': type,
    'category': category,
    'date': date.toIso8601String(),
  };
}