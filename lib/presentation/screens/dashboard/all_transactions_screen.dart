import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/transaction.dart';

class AllTransactionsScreen extends ConsumerWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final filtered = ref.watch(filteredTransactionsProvider);

    final months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল',
      'মে', 'জুন', 'জুলাই', 'আগস্ট',
      'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          '${months[selectedMonth.month - 1]} ${selectedMonth.year}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Syne',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.bg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${filtered.length} টি',
                style: const TextStyle(
                    color: AppColors.gold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: txAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) {
          if (filtered.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💰', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text('এই মাসে কোনো লেনদেন নেই',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 15)),
                ],
              ),
            );
          }

          // Group by date
          final grouped = <String, List<Transaction>>{};
          for (final tx in filtered) {
            final key =
                '${tx.date.day}/${tx.date.month}/${tx.date.year}';
            grouped.putIfAbsent(key, () => []).add(tx);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (_, i) {
              final date = grouped.keys.elementAt(i);
              final txs = grouped[date]!;
              final dayTotal = txs.fold<double>(
                0,
                (sum, t) => t.type == TransactionType.income
                    ? sum + t.amount
                    : sum - t.amount,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(date,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          )),
                        Text(
                          '${dayTotal >= 0 ? '+' : ''}৳${dayTotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: dayTotal >= 0
                                ? AppColors.teal
                                : AppColors.rose,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...txs.map((tx) => _DeleteableTile(tx: tx)),
                  const SizedBox(height: 4),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DeleteableTile extends ConsumerWidget {
  final Transaction tx;
  const _DeleteableTile({required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = tx.type == TransactionType.income;
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.rose,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 24),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF141C2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete করবে?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Syne',
                fontWeight: FontWeight.w700,
              )),
            content: Text('"${tx.note}" — ৳${tx.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('বাতিল',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rose,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          ref.read(transactionsProvider.notifier).remove(tx.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141C2E),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.teal.withOpacity(0.15)
                  : AppColors.rose.withOpacity(0.15),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isIncome
                    ? AppColors.teal.withOpacity(0.3)
                    : AppColors.rose.withOpacity(0.3),
              ),
            ),
            child: Center(
                child: Text(tx.icon,
                    style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.note,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
                Text('${tx.category} · ${tx.date.day}/${tx.date.month}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}৳${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: isIncome ? AppColors.teal : AppColors.rose,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Syne',
            ),
          ),
        ]),
      ),
    );
  }
}
