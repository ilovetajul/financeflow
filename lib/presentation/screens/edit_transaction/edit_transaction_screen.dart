import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../domain/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../category/category_screen.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction transaction;
  const EditTransactionScreen({super.key, required this.transaction});

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState
    extends ConsumerState<EditTransactionScreen> {
  late TransactionType _type;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late DateTime _date;
  AppCategory? _selectedCategory;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.transaction.type;
    _amountCtrl = TextEditingController(
        text: widget.transaction.amount.toStringAsFixed(0));
    _noteCtrl = TextEditingController(text: widget.transaction.note);
    _date = widget.transaction.date;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Color get _typeColor =>
      _type == TransactionType.income ? AppColors.teal : AppColors.rose;

  Gradient get _typeGrad =>
      _type == TransactionType.income ? AppColors.gradTeal : AppColors.gradRose;

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty) return;
    setState(() => _saving = true);

    final updated = widget.transaction.copyWith(
      type: _type,
      category: _selectedCategory?.name ?? widget.transaction.category,
      icon: _selectedCategory?.icon ?? widget.transaction.icon,
      amount: double.parse(_amountCtrl.text),
      note: _noteCtrl.text.isNotEmpty
          ? _noteCtrl.text : widget.transaction.note,
      date: _date,
    );

    await ref.read(transactionsProvider.notifier).update(updated);
    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        content: Row(children: [
          Text('✅ ', style: TextStyle(fontSize: 16)),
          Text('সফলভাবে update হয়েছে!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(categoriesProvider);
    final categories = allCategories.where((c) => c.type == _type).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Edit Transaction',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary)),
        actions: [
          // Delete button
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF141C2E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('Delete করবে?',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontFamily: 'Syne', fontWeight: FontWeight.w700)),
                  content: Text('"${widget.transaction.note}"',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false),
                      child: const Text('বাতিল',
                          style: TextStyle(color: AppColors.textMuted))),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                      child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await ref.read(transactionsProvider.notifier)
                    .remove(widget.transaction.id);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_rounded, color: AppColors.rose),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Current info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
              ),
              child: Row(children: [
                Text(widget.transaction.icon,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.transaction.note,
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('আগের পরিমাণ: ৳${widget.transaction.amount.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                ]),
              ]),
            ),

            const SizedBox(height: 20),

            // Type Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [TransactionType.income, TransactionType.expense].map((t) {
                  final isSelected = _type == t;
                  final isIncome = t == TransactionType.income;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = t;
                        _selectedCategory = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected ? _typeGrad : null,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: Text(isIncome ? '↑  Income' : '↓  Expense',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textMuted,
                            fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Amount
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2440), Color(0xFF0D1428)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _typeColor.withOpacity(0.2)),
              ),
              child: Column(children: [
                const Text('নতুন পরিমাণ',
                  style: TextStyle(color: AppColors.textMuted,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('৳', style: TextStyle(color: _typeColor,
                      fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 40, fontWeight: FontWeight.w800,
                        letterSpacing: -1, fontFamily: 'Syne'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(color: AppColors.textDim,
                          fontSize: 40, fontFamily: 'Syne')),
                  )),
                ]),
              ]),
            ),

            const SizedBox(height: 20),

            // Category
            const Text('Category (optional)',
              style: TextStyle(color: AppColors.textMuted,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('বর্তমান: ${widget.transaction.category}',
              style: const TextStyle(color: AppColors.gold, fontSize: 11)),
            const SizedBox(height: 10),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8,
                childAspectRatio: 0.9),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final selected = _selectedCategory?.id == cat.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? _typeColor.withOpacity(0.15)
                          : Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: selected ? _typeColor : Colors.white.withOpacity(0.07),
                        width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(cat.name,
                        style: TextStyle(
                          color: selected ? _typeColor : AppColors.textMuted,
                          fontSize: 10, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center, maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Note
            const Text('Note',
              style: TextStyle(color: AppColors.textMuted,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.07))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.07))),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 16),

            // Date
            const Text('Date',
              style: TextStyle(color: AppColors.textMuted,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(primary: AppColors.gold)),
                    child: child!),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.gold, size: 18),
                  const SizedBox(width: 12),
                  Text('${_date.day}/${_date.month}/${_date.year}',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
                ]),
              ),
            ),

            const SizedBox(height: 28),

            // Save Button
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.gradGold,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                    color: AppColors.gold.withOpacity(0.35),
                    blurRadius: 20, offset: const Offset(0, 6))],
                ),
                alignment: Alignment.center,
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text('Update করো ✓',
                        style: TextStyle(
                          color: Color(0xFF0A0E1A), fontSize: 16,
                          fontWeight: FontWeight.w800, fontFamily: 'Syne')),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
