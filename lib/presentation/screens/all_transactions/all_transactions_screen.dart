// lib/presentation/screens/all_transactions/all_transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/transaction.dart';
import '../edit_transaction/edit_transaction_screen.dart';

class AllTransactionsScreen extends ConsumerWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final filtered      = ref.watch(filteredTransactionsProvider);
    final months = ['জানুয়ারি','ফেব্রুয়ারি','মার্চ','এপ্রিল','মে','জুন','জুলাই','আগস্ট','সেপ্টেম্বর','অক্টোবর','নভেম্বর','ডিসেম্বর'];

    final totalIncome  = filtered.where((t) => t.type == TransactionType.income).fold(0.0,  (s, t) => s + t.amount);
    final totalExpense = filtered.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);

    // Group by date
    final grouped = <String, List<Transaction>>{};
    for (final tx in filtered) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2,'0')}-${tx.date.day.toString().padLeft(2,'0')}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(
          '${months[selectedMonth.month - 1]} ${selectedMonth.year}',
          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
        ),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${filtered.length} টি', style: const TextStyle(color: AppColors.gold, fontSize: 13)))),
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('💰', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text('এই মাসে কোনো লেনদেন নেই', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            ]))
          : Column(children: [

              // Summary strip
              Container(margin: const EdgeInsets.fromLTRB(16, 8, 16, 0), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF141C2E), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _Chip(label: 'আয়',      value: totalIncome,              color: AppColors.teal),
                  Container(width: 1, height: 30, color: Colors.white12),
                  _Chip(label: 'খরচ',     value: totalExpense,             color: AppColors.rose),
                  Container(width: 1, height: 30, color: Colors.white12),
                  _Chip(label: 'ব্যালেন্স', value: totalIncome - totalExpense, color: totalIncome >= totalExpense ? AppColors.gold : AppColors.rose),
                ])),

              // Hint
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.textDim, size: 12),
                  SizedBox(width: 4),
                  Text('ধরে রাখো = Edit | বামে সোয়াইপ = Delete', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                ])),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: sortedKeys.length,
                  itemBuilder: (_, i) {
                    final key  = sortedKeys[i];
                    final txs  = grouped[key]!;
                    final parts = key.split('-');
                    final dateStr = '${parts[2]}/${parts[1]}/${parts[0]}';
                    final dayBal  = txs.fold<double>(0, (s, t) => t.type == TransactionType.income ? s + t.amount : s - t.amount);

                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Date header
                      Padding(padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(dateStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('${dayBal >= 0 ? '+' : ''}৳${dayBal.toStringAsFixed(0)}',
                            style: TextStyle(color: dayBal >= 0 ? AppColors.teal : AppColors.rose, fontSize: 12, fontWeight: FontWeight.w700)),
                        ])),
                      ...txs.map((tx) => _TxTile(tx: tx)),
                    ]);
                  },
                ),
              ),
            ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label; final double value; final Color color;
  const _Chip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
    const SizedBox(height: 2),
    Text('৳${value.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
  ]);
}

class _TxTile extends ConsumerWidget {
  final Transaction tx;
  const _TxTile({required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = tx.type == TransactionType.income;
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: AppColors.rose, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 22),
          Text('Delete', style: TextStyle(color: Colors.white, fontSize: 10)),
        ]),
      ),
      // ── Confirm before delete ─────────────────────────────────
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (dCtx) => AlertDialog(
            backgroundColor: const Color(0xFF141C2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete করবে?',
              style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700)),
            content: Text('"${tx.note}" — ৳${tx.amount.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx, false),
                child: const Text('না', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dCtx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rose, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('হ্যাঁ, Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => ref.read(transactionsProvider.notifier).remove(tx.id),
      child: GestureDetector(
        onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditTransactionScreen(transaction: tx))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF141C2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(
                color: isIncome ? AppColors.teal.withOpacity(0.15) : AppColors.rose.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: isIncome ? AppColors.teal.withOpacity(0.3) : AppColors.rose.withOpacity(0.3))),
              child: Center(child: Text(tx.icon, style: const TextStyle(fontSize: 18)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.note, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${tx.category} · ${tx.date.day}/${tx.date.month}/${tx.date.year}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ])),
            Text('${isIncome ? '+' : '-'}৳${tx.amount.toStringAsFixed(0)}',
              style: TextStyle(color: isIncome ? AppColors.teal : AppColors.rose, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
          ]),
        ),
      ),
    );
  }
}
