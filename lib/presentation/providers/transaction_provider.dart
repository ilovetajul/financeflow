import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/database_helper.dart';
import '../../domain/models/transaction.dart';

final transactionsProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
        TransactionNotifier.new);

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  final _db = DatabaseHelper.instance;

  @override
  Future<List<Transaction>> build() => _db.getAllTransactions();

  Future<void> add({
    required TransactionType type,
    required String category,
    required double amount,
    required String note,
    required DateTime date,
    required String icon,
  }) async {
    final tx = Transaction(
      id: const Uuid().v4(),
      type: type,
      category: category,
      amount: amount,
      note: note,
      date: date,
      icon: icon,
    );
    await _db.insertTransaction(tx);
    ref.invalidateSelf();
  }

  // ── Edit/Update ─────────────────────────────────────────
  Future<void> update(Transaction tx) async {
    await _db.updateTransaction(tx);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await _db.deleteTransaction(id);
    ref.invalidateSelf();
  }

  Future<void> restoreAll(List<Transaction> txs) async {
    await _db.deleteAll();
    await _db.insertAll(txs);
    ref.invalidateSelf();
  }
}

// ── Month Provider ───────────────────────────────────────────
final selectedMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month));

// ── Filtered by Month ────────────────────────────────────────
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final selectedMonth = ref.watch(selectedMonthProvider);
  return ref.watch(transactionsProvider).maybeWhen(
    data: (txs) => txs
        .where((t) =>
            t.date.year == selectedMonth.year &&
            t.date.month == selectedMonth.month)
        .toList(),
    orElse: () => [],
  );
});

// ── This Month Income ────────────────────────────────────────
final totalIncomeProvider = Provider<double>((ref) {
  return ref
      .watch(filteredTransactionsProvider)
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// ── This Month Expense ───────────────────────────────────────
final totalExpenseProvider = Provider<double>((ref) {
  return ref
      .watch(filteredTransactionsProvider)
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// ── All Time Balance ─────────────────────────────────────────
final balanceProvider = Provider<double>((ref) =>
    ref.watch(totalIncomeProvider) - ref.watch(totalExpenseProvider));

final allTimeBalanceProvider = Provider<double>((ref) {
  return ref.watch(transactionsProvider).maybeWhen(
    data: (txs) {
      final income = txs
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final expense = txs
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      return income - expense;
    },
    orElse: () => 0.0,
  );
});
