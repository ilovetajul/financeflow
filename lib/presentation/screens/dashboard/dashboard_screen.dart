import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/debt_provider.dart';
import '../../../domain/models/transaction.dart';
import '../all_transactions/all_transactions_screen.dart';
import '../search/search_screen.dart';
import '../edit_transaction/edit_transaction_screen.dart';
import '../profile/profile_screen.dart';
import '../debt/debt_screens.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _fmtShort(double v) {
    if (v >= 100000) return '৳${(v/100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '৳${(v/1000).toStringAsFixed(1)}k';
    return '৳${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTxs = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <Transaction>[]);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final filtered = ref.watch(filteredTransactionsProvider);
    final balance = ref.watch(allTimeBalanceProvider);
    final monthIncome = ref.watch(totalIncomeProvider);
    final monthExpense = ref.watch(totalExpenseProvider);
    final profile = ref.watch(profileProvider);
    final totalDebtNet = ref.watch(totalOwedToMeProvider);
    final now = DateTime.now();

    final todayTxs = allTxs.where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day).toList();
    final todayIncome = todayTxs.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
    final todayExpense = todayTxs.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekTxs = allTxs.where((t) => t.date.isAfter(weekStart.subtract(const Duration(days: 1))) && t.date.isBefore(now.add(const Duration(days: 1)))).toList();

    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthTxs = allTxs.where((t) => t.date.year == lastMonth.year && t.date.month == lastMonth.month).toList();
    final lastMonthIncome = lastMonthTxs.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
    final lastMonthExpense = lastMonthTxs.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
    final lastMonthBalance = lastMonthIncome - lastMonthExpense;

    final months = ['জানু','ফেব্রু','মার্চ','এপ্রিল','মে','জুন','জুলাই','আগস্ট','সেপ্টে','অক্টো','নভে','ডিসে'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: () async => ref.invalidate(transactionsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Header
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${now.day}/${now.month}/${now.year}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    Text(profile.name.isNotEmpty ? 'স্বাগতম, ${profile.name}!' : 'FinanceFlow',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                  ]),
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                      child: Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))),
                        child: const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 20))),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      child: profile.photoPath != null
                          ? CircleAvatar(radius: 20, backgroundImage: FileImage(File(profile.photoPath!)))
                          : Container(width: 40, height: 40,
                              decoration: BoxDecoration(gradient: AppColors.gradGold, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20))),
                  ]),
                ])),

              const SizedBox(height: 16),

              // Month selector
              SizedBox(height: 38, child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal, itemCount: 12,
                itemBuilder: (_, i) {
                  final isSel = selectedMonth.month == i+1 && selectedMonth.year == now.year;
                  return GestureDetector(
                    onTap: () => ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, i+1),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isSel ? AppColors.gradGold : null,
                        color: isSel ? null : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSel ? Colors.transparent : Colors.white.withOpacity(0.08))),
                      child: Text(months[i], style: TextStyle(color: isSel ? const Color(0xFF0A0E1A) : AppColors.textMuted, fontSize: 12, fontWeight: isSel ? FontWeight.w800 : FontWeight.w500))));
                })),

              const SizedBox(height: 16),

              // Balance hero
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(width: double.infinity, padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradBalance, borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.gold.withOpacity(0.15)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${months[selectedMonth.month-1]} মাসের ব্যালেন্স',
                      style: TextStyle(color: AppColors.gold.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: balance), duration: const Duration(milliseconds: 1200), curve: Curves.easeOutCubic,
                      builder: (_, val, __) => Text('৳${val.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, fontFamily: 'Syne'))),
                    const SizedBox(height: 16),
                    Row(children: [
                      _MiniStat(label: '${months[selectedMonth.month-1]} আয়', value: _fmtShort(monthIncome), color: AppColors.teal, arrow: '↑'),
                      const SizedBox(width: 10),
                      _MiniStat(label: '${months[selectedMonth.month-1]} খরচ', value: _fmtShort(monthExpense), color: AppColors.rose, arrow: '↓'),
                    ]),
                  ]))),

              const SizedBox(height: 14),

              // Today / Week
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _SummaryCard(title: 'আজকে', income: todayIncome, expense: todayExpense, icon: '📅'),
                  const SizedBox(width: 10),
                  _SummaryCard(
                    title: 'এই সপ্তাহ',
                    income: weekTxs.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount),
                    expense: weekTxs.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount),
                    icon: '📆'),
                ])),

              const SizedBox(height: 14),

              // Last month
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF141C2E), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.06))),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('গত মাস (${months[lastMonth.month-1]})',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: lastMonthBalance >= 0 ? AppColors.teal.withOpacity(0.15) : AppColors.rose.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)),
                        child: Text('${lastMonthBalance >= 0 ? '+' : ''}৳${lastMonthBalance.toStringAsFixed(0)}',
                          style: TextStyle(color: lastMonthBalance >= 0 ? AppColors.teal : AppColors.rose, fontSize: 12, fontWeight: FontWeight.w700))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _LastMonthItem(label: 'আয়', value: lastMonthIncome, color: AppColors.teal, icon: '↑')),
                      Expanded(child: _LastMonthItem(label: 'খরচ', value: lastMonthExpense, color: AppColors.rose, icon: '↓')),
                      Expanded(child: _LastMonthItem(label: 'লেনদেন', value: lastMonthTxs.length.toDouble(), color: AppColors.gold, icon: '📊', isCount: true)),
                    ]),
                  ]))),

              const SizedBox(height: 14),

              // ── দেনা-পাওনা card ───────────────────────────────────
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtManagementScreen())),
                  child: Container(padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1A1040), Color(0xFF0D0A2E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.purple.withOpacity(0.3))),
                    child: Row(children: [
                      Container(width: 48, height: 48,
                        decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.15), borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.purple.withOpacity(0.3))),
                        child: const Center(child: Text('🤝', style: TextStyle(fontSize: 22)))),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('দেনা-পাওনা', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
                        Text(
                          totalDebtNet == 0 ? 'সব হিসাব সমান'
                              : totalDebtNet > 0 ? '৳${totalDebtNet.toStringAsFixed(0)} পাওনা আছে'
                              : '৳${totalDebtNet.abs().toStringAsFixed(0)} দেনা আছে',
                          style: TextStyle(
                            color: totalDebtNet >= 0 ? AppColors.teal : AppColors.rose,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                      ])),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text('বিস্তারিত →', style: TextStyle(color: AppColors.purple.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w700))),
                    ]))));

              const SizedBox(height: 14),

              // Stats
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _StatCard(icon: '💎', label: 'সঞ্চয়',
                    value: monthIncome > 0 ? '${(((monthIncome-monthExpense)/monthIncome)*100).toStringAsFixed(0)}%' : '0%',
                    color: AppColors.teal),
                  const SizedBox(width: 10),
                  _StatCard(icon: '📊', label: 'লেনদেন', value: '${filtered.length}', color: AppColors.gold),
                  const SizedBox(width: 10),
                  _StatCard(icon: '🏷️', label: 'Category', value: '${filtered.map((x) => x.category).toSet().length}', color: AppColors.purple),
                ])),

              const SizedBox(height: 20),

              // Recent
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Recent Activity', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllTransactionsScreen())),
                    child: const Text('সব দেখো →', style: TextStyle(color: AppColors.gold, fontSize: 13))),
                ])),

              const SizedBox(height: 12),

              if (filtered.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(20)),
                    child: const Center(child: Column(children: [
                      Text('💰', style: TextStyle(fontSize: 40)), SizedBox(height: 12),
                      Text('এই মাসে কোনো লেনদেন নেই', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                      Text('নিচের ➕ বাটন চেপে যোগ করুন', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                    ]))))
              else
                ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length > 6 ? 6 : filtered.length,
                  itemBuilder: (_, i) => _TxTile(tx: filtered[i])),

              const SizedBox(height: 80),
            ])),
        )),
    );
  }
}

class _TxTile extends ConsumerWidget {
  final Transaction tx;
  const _TxTile({required this.tx});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = tx.type == TransactionType.income;
    return Dismissible(
      key: Key(tx.id), direction: DismissDirection.endToStart,
      background: Container(margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: AppColors.rose, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 22),
          Text('Delete', style: TextStyle(color: Colors.white, fontSize: 10))])),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF141C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete করবে?', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700)),
          content: Text('"${tx.note}" — ৳${tx.amount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না', style: TextStyle(color: AppColors.textMuted, fontSize: 15))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('হ্যাঁ, Delete')),
          ])),
      onDismissed: (_) => ref.read(transactionsProvider.notifier).remove(tx.id),
      child: GestureDetector(
        onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditTransactionScreen(transaction: tx))),
        child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
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
              Text('${tx.category} · ${tx.date.day}/${tx.date.month}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ])),
            Text('${isIncome ? '+' : '-'}৳${tx.amount.toStringAsFixed(0)}',
              style: TextStyle(color: isIncome ? AppColors.teal : AppColors.rose, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
          ]))));
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, icon; final double income, expense;
  const _SummaryCard({required this.title, required this.icon, required this.income, required this.expense});
  String _f(double v) => v >= 1000 ? '৳${(v/1000).toStringAsFixed(1)}k' : '৳${v.toStringAsFixed(0)}';
  @override
  Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF141C2E), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.06))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text(icon, style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))]),
      const SizedBox(height: 10),
      Row(children: [const Text('↑', style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Text(_f(income), style: const TextStyle(color: AppColors.teal, fontSize: 12, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 4),
      Row(children: [const Text('↓', style: TextStyle(color: AppColors.rose, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Text(_f(expense), style: const TextStyle(color: AppColors.rose, fontSize: 12, fontWeight: FontWeight.w700))]),
    ])));
}

class _LastMonthItem extends StatelessWidget {
  final String label, icon; final double value; final Color color; final bool isCount;
  const _LastMonthItem({required this.label, required this.value, required this.color, required this.icon, this.isCount = false});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(icon, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(isCount ? '${value.toInt()} টি' : '৳${value.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
    Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
  ]);
}

class _MiniStat extends StatelessWidget {
  final String label, value, arrow; final Color color;
  const _MiniStat({required this.label, required this.value, required this.color, required this.arrow});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.07))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text(arrow, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(width: 4),
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
    ])));
}

class _StatCard extends StatelessWidget {
  final String icon, label, value; final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 18)), const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
    ])));
}
