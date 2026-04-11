import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/transaction.dart';
import '../edit_transaction/edit_transaction_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filterType = 'সব'; // সব, আয়, খরচ
  String? _filterCategory;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Transaction> _applyFilters(List<Transaction> all) {
    return all.where((tx) {
      // Text search
      final q = _query.toLowerCase();
      final matchQuery = q.isEmpty ||
          tx.note.toLowerCase().contains(q) ||
          tx.category.toLowerCase().contains(q) ||
          tx.amount.toString().contains(q);

      // Type filter
      final matchType = _filterType == 'সব' ||
          (_filterType == 'আয়' && tx.type == TransactionType.income) ||
          (_filterType == 'খরচ' && tx.type == TransactionType.expense);

      // Category filter
      final matchCategory =
          _filterCategory == null || tx.category == _filterCategory;

      // Date filter
      final matchFrom =
          _fromDate == null || !tx.date.isBefore(_fromDate!);
      final matchTo =
          _toDate == null || !tx.date.isAfter(_toDate!.add(const Duration(days: 1)));

      return matchQuery && matchType && matchCategory &&
          matchFrom && matchTo;
    }).toList();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.gold)),
        child: child!),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTxs = ref.watch(transactionsProvider).maybeWhen(
      data: (t) => t,
      orElse: () => <Transaction>[],
    );
    final categories = allTxs.map((t) => t.category).toSet().toList();
    final filtered = _applyFilters(allTxs);

    final totalIncome = filtered
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = filtered
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary)),
        title: const Text('Search & History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: Column(
        children: [
          // ── Search Box ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'খরচের নাম, category বা পরিমাণ লেখো...',
                hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.gold, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        })
                    : null,
                filled: true,
                fillColor: const Color(0xFF141C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // ── Filters ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              // Type filter
              ...['সব', 'আয়', 'খরচ'].map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filterType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _filterType == t
                          ? AppColors.gold.withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _filterType == t
                            ? AppColors.gold : Colors.white.withOpacity(0.08)),
                    ),
                    child: Text(t,
                      style: TextStyle(
                        color: _filterType == t
                            ? AppColors.gold : AppColors.textMuted,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              )),

              // Date From
              _DateChip(
                label: _fromDate != null
                    ? '${_fromDate!.day}/${_fromDate!.month}'
                    : 'শুরু তারিখ',
                icon: '📅',
                active: _fromDate != null,
                onTap: () => _pickDate(true),
                onClear: _fromDate != null
                    ? () => setState(() => _fromDate = null) : null,
              ),

              const SizedBox(width: 8),

              // Date To
              _DateChip(
                label: _toDate != null
                    ? '${_toDate!.day}/${_toDate!.month}'
                    : 'শেষ তারিখ',
                icon: '📅',
                active: _toDate != null,
                onTap: () => _pickDate(false),
                onClear: _toDate != null
                    ? () => setState(() => _toDate = null) : null,
              ),

              // Category filter
              if (categories.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF141C2E),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Category বেছে নাও',
                            style: TextStyle(color: AppColors.textPrimary,
                                fontFamily: 'Syne', fontWeight: FontWeight.w700))),
                        ListTile(
                          title: const Text('সব Category',
                            style: TextStyle(color: AppColors.textPrimary)),
                          trailing: _filterCategory == null
                              ? const Icon(Icons.check, color: AppColors.gold) : null,
                          onTap: () {
                            setState(() => _filterCategory = null);
                            Navigator.pop(context);
                          }),
                        ...categories.map((c) => ListTile(
                          title: Text(c,
                            style: const TextStyle(color: AppColors.textPrimary)),
                          trailing: _filterCategory == c
                              ? const Icon(Icons.check, color: AppColors.gold) : null,
                          onTap: () {
                            setState(() => _filterCategory = c);
                            Navigator.pop(context);
                          })),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _filterCategory != null
                          ? AppColors.purple.withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _filterCategory != null
                            ? AppColors.purple : Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(children: [
                      Text(_filterCategory ?? '🏷️ Category',
                        style: TextStyle(
                          color: _filterCategory != null
                              ? AppColors.purple : AppColors.textMuted,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                      if (_filterCategory != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _filterCategory = null),
                          child: const Icon(Icons.close, size: 14,
                              color: AppColors.purple)),
                      ],
                    ]),
                  ),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 12),

          // ── Result Summary ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('${filtered.length} টি ফলাফল',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const Spacer(),
              Text('↑ ৳${totalIncome.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.teal,
                    fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Text('↓ ৳${totalExpense.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.rose,
                    fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),

          const SizedBox(height: 8),

          // ── Results ──
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🔍', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 16),
                      Text('কোনো ফলাফল পাওয়া যায়নি',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final tx = filtered[i];
                      final isIncome = tx.type == TransactionType.income;
                      return GestureDetector(
                        onLongPress: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditTransactionScreen(transaction: tx))),
                        child: Dismissible(
                          key: Key(tx.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.rose,
                              borderRadius: BorderRadius.circular(16)),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.white)),
                          onDismissed: (_) =>
                              ref.read(transactionsProvider.notifier).remove(tx.id),
                          child: Container(
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
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text('${tx.category} · ${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                    style: const TextStyle(
                                        color: AppColors.textMuted, fontSize: 11)),
                                ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('${isIncome ? '+' : '-'}৳${tx.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: isIncome ? AppColors.teal : AppColors.rose,
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    fontFamily: 'Syne')),
                                const Text('ধরতে রাখো = Edit',
                                  style: TextStyle(color: AppColors.textDim, fontSize: 9)),
                              ]),
                            ]),
                          ),
                        ),
                      );
                    }),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label, icon;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DateChip({
    required this.label, required this.icon,
    required this.active, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.teal.withOpacity(0.2) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.teal : Colors.white.withOpacity(0.08)),
        ),
        child: Row(children: [
          Text('$icon $label',
            style: TextStyle(
              color: active ? AppColors.teal : AppColors.textMuted,
              fontSize: 12, fontWeight: FontWeight.w600)),
          if (onClear != null) ...[
            const SizedBox(width: 4),
            GestureDetector(onTap: onClear,
              child: const Icon(Icons.close, size: 14, color: AppColors.teal)),
          ],
        ]),
      ),
    );
  }
}
