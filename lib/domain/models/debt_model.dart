// lib/domain/models/debt_model.dart

enum DebtType { gave, received }

class DebtPerson {
  final String id;
  final String name;
  final String phone;
  final String? imagePath;

  DebtPerson({
    required this.id,
    required this.name,
    required this.phone,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'imagePath': imagePath,
  };

  factory DebtPerson.fromJson(Map<String, dynamic> j) => DebtPerson(
    id: j['id'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String,
    imagePath: j['imagePath'] as String?,
  );
}

class DebtTransaction {
  final String id;
  final String personId;
  final double amount;
  final DebtType type; // gave = আমি দিয়েছি, received = আমি পেয়েছি
  final DateTime date;
  final String note;

  DebtTransaction({
    required this.id,
    required this.personId,
    required this.amount,
    required this.type,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'personId': personId,
    'amount': amount,
    'type': type.name,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory DebtTransaction.fromJson(Map<String, dynamic> j) => DebtTransaction(
    id: j['id'] as String,
    personId: j['personId'] as String,
    amount: (j['amount'] as num).toDouble(),
    type: DebtType.values.byName(j['type'] as String),
    date: DateTime.parse(j['date'] as String),
    note: j['note'] as String,
  );
}
