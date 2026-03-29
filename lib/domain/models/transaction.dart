enum TransactionType { income, expense }

class Transaction {
  final String id;
  final TransactionType type;
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final String icon;

  Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'category': category,
    'amount': amount,
    'note': note,
    'date': date.toIso8601String(),
    'icon': icon,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    type: TransactionType.values.byName(json['type'] as String),
    category: json['category'] as String,
    amount: (json['amount'] as num).toDouble(),
    note: json['note'] as String,
    date: DateTime.parse(json['date'] as String),
    icon: json['icon'] as String,
  );

  Transaction copyWith({
    String? id,
    TransactionType? type,
    String? category,
    double? amount,
    String? note,
    DateTime? date,
    String? icon,
  }) =>
      Transaction(
        id: id ?? this.id,
        type: type ?? this.type,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        date: date ?? this.date,
        icon: icon ?? this.icon,
      );
}
