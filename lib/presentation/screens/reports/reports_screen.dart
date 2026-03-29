import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme.dart';
import '../../../domain/models/transaction.dart';
import '../../providers/transaction_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static const _pieColors = [
    AppColors.rose,
    AppColors.gold,
    AppColors.teal,
    AppColors.purple,
    AppColors.blue,
    Color(0xFFFB923C),
  ];

  Map<String, double> _groupByCategory(List<Transaction> txs) {
    final map = <String, double>{};
    for (final tx in txs) {
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  String _fmtShort(double v) {
    if (v >= 100000) return '৳${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '৳${(v / 1000).toStringAsFixed(1)}k';
    return '৳${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final income  = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);
    final balance = ref.watch(balanceProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: txAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (transactions) {
            final expTxs = transactions
                .where((t) => t.type == TransactionType.expense)
                .toList();
            final expByCategory = _groupByCategory(expTxs);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ──
                  const Text('Reports',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24, fontWeight: FontWeight.w800,
                      fontFamily: 'Syne',
                    )),
                  const Text('তোমার আর্থিক বিশ্লেষণ',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),

                  const SizedBox(height: 24),

                  // ── Income / Expense Summary ──
                  Row(children: [
                    _SummaryBox(
                      label: 'Total Income',
                      value: _fmtShort(income),
                      color: AppColors.teal,
                      gradient: AppColors.gradTeal,
                      arrow: '↑',
                    ),
                    const SizedBox(width: 12),
                    _SummaryBox(
                      label: 'Total Expense',
                      value: _fmtShort(expense),
                      color: AppColors.rose,
                      gradient: AppColors.gradRose,
                      arrow: '↓',
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // ── Savings Rate ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141C2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Savings Rate',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              income > 0
                                  ? '${((balance / income) * 100).toStringAsFixed(1)}%'
                                  : '0%',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Syne',
                              ),
                            ),
                            Text(
                              'Balance: ${_fmtShort(balance)}',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        const Text('💎',
                            style: TextStyle(fontSize: 44)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Pie Chart ──
                  if (expByCategory.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141C2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Spending Breakdown',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Syne',
                            )),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: Row(children: [
                              Expanded(
                                child: PieChart(PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 44,
                                  sections: expByCategory.entries
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map((e) {
                                    final idx = e.key;
                                    final entry = e.value;
                                    final pct = expense > 0
                                        ? (entry.value / expense * 100)
                                        : 0.0;
                                    return PieChartSectionData(
                                      color: _pieColors[
                                          idx % _pieColors.length],
                                      value: entry.value,
                                      title:
                                          '${pct.toStringAsFixed(0)}%',
                                      radius: 52,
                                      titleStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                )),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: expByCategory.entries
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((e) {
                                  final idx = e.key;
                                  final entry = e.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 6),
                                    child: Row(children: [
                                      Container(
                                        width: 8, height: 8,
                                        decoration: BoxDecoration(
                                          color: _pieColors[
                                              idx % _pieColors.length],
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(entry.key,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        )),
                                    ]),
                                  );
                                }).toList(),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Category Bar List ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141C2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category Details',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Syne',
                            )),
                          const SizedBox(height: 16),
                          ...expByCategory.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((e) {
                            final idx = e.key;
                            final entry = e.value;
                            final pct = expense > 0
                                ? entry.value / expense
                                : 0.0;
                            final color =
                                _pieColors[idx % _pieColors.length];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 14),
                              child: Column(children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      )),
                                    Row(children: [
                                      Text(_fmtShort(entry.value),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Syne',
                                        )),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(pct * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        )),
                                    ]),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 5,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.06),
                                    valueColor:
                                        AlwaysStoppedAnimation(color),
                                  ),
                                ),
                              ]),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  if (expByCategory.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Column(children: [
                          Text('📊', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 12),
                          Text('কোনো খরচ নেই',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14)),
                        ]),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label, value, arrow;
  final Color color;
  final Gradient gradient;

  const _SummaryBox({
    required this.label, required this.value,
    required this.color, required this.gradient,
    required this.arrow,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141C2E),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(arrow,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  )),
              ),
              const SizedBox(width: 8),
              Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 8),
            Text(value,
              style: TextStyle(
                color: color, fontSize: 22,
                fontWeight: FontWeight.w800, fontFamily: 'Syne',
              )),
          ],
        ),
      ),
    );
  }
}
