import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/transaction.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _fmtShort(double v) {
    if (v >= 100000) return '৳${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '৳${(v / 1000).toStringAsFixed(1)}k';
    return '৳${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final balance = ref.watch(balanceProvider);
    final income = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: () async => ref.invalidate(transactionsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good morning 👋',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('FinanceFlow',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradGold,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 12, offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Balance Hero Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradBalance,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.gold.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30, offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Balance',
                        style: TextStyle(
                          color: AppColors.gold.withOpacity(0.7),
                          fontSize: 12, letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: balance),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, __) => Text(
                          '৳${val.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 34, fontWeight: FontWeight.w800,
                            letterSpacing: -1.0, fontFamily: 'Syne',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _MiniStat(
                            label: 'Income',
                            value: _fmtShort(income),
                            color: AppColors.teal,
                            arrow: '↑',
                          ),
                          const SizedBox(width: 12),
                          _MiniStat(
                            label: 'Expense',
                            value: _fmtShort(expense),
                            color: AppColors.rose,
                            arrow: '↓',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Quick Stats ──
                Row(
                  children: [
                    _StatCard(
                      icon: '💎',
                      label: 'Savings',
                      value: income > 0
                          ? '${((balance / income) * 100).toStringAsFixed(0)}%'
                          : '0%',
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: '📊',
                      label: 'Records',
                      value: txAsync.maybeWhen(
                        data: (t) => '${t.length}',
                        orElse: () => '0',
                      ),
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: '🏷️',
                      label: 'Categories',
                      value: txAsync.maybeWhen(
                        data: (t) => '${t.map((x) => x.category).toSet().length}',
                        orElse: () => '0',
                      ),
                      color: AppColors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Recent Transactions ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('See all →',
                        style: const TextStyle(
                            color: AppColors.gold, fontSize: 13)),
                  ],
                ),

                const SizedBox(height: 12),

                txAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (txs) => txs.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.06)),
                          ),
                          child: const Center(
                            child: Column(children: [
                              Text('💰', style: TextStyle(fontSize: 40)),
                              SizedBox(height: 12),
                              Text('কোনো লেনদেন নেই',
                                style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 14)),
                              Text('নিচের ➕ বাটন চেপে যোগ করুন',
                                style: TextStyle(
                                  color: AppColors.textDim, fontSize: 12)),
                            ]),
                          ),
                        )
                      : Column(
                          children: txs.take(8).map((tx) =>
                            _TransactionTile(tx: tx)).toList(),
                        ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value, arrow;
  final Color color;
  const _MiniStat({
    required this.label, required this.value,
    required this.color, required this.arrow,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(arrow, style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            color: color, fontSize: 16,
            fontWeight: FontWeight.w700, fontFamily: 'Syne',
          )),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _StatCard({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            color: color, fontSize: 16,
            fontWeight: FontWeight.w800, fontFamily: 'Syne',
          )),
          Text(label, style: const TextStyle(
              color: AppColors.textMuted, fontSize: 10)),
        ]),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
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
          child: Center(child: Text(tx.icon,
              style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tx.note, style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w600,
            )),
            Text('${tx.category} · ${tx.date.day}/${tx.date.month}',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
          ],
        )),
        Text(
          '${isIncome ? '+' : '-'}৳${tx.amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: isIncome ? AppColors.teal : AppColors.rose,
            fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Syne',
          ),
        ),
      ]),
    );
  }
}
