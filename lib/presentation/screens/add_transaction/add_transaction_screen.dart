// lib/presentation/screens/add_transaction/add_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../domain/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../category/category_screen.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  ConsumerState<AddTransactionScreen> createState() => _AddState();
}

class _AddState extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  AppCategory? _selectedCat;
  DateTime _date = DateTime.now();
  bool _saving   = false;

  Color    get _col  => _type == TransactionType.income ? AppColors.teal : AppColors.rose;
  Gradient get _grad => _type == TransactionType.income ? AppColors.gradTeal : AppColors.gradRose;

  @override
  void dispose() { _amountCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty || _selectedCat == null) return;
    setState(() => _saving = true);
    await ref.read(transactionsProvider.notifier).add(
      type: _type,
      category: _selectedCat!.name,
      amount: double.parse(_amountCtrl.text),
      note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : _selectedCat!.name,
      date: _date,
      icon: _selectedCat!.icon,
    );
    setState(() { _saving = false; _selectedCat = null; });
    _amountCtrl.clear(); _noteCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.teal, behavior: SnackBarBehavior.floating,
        content: Row(children: [
          Text('✅ ', style: TextStyle(fontSize: 16)),
          Text('সফলভাবে সেভ হয়েছে!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ));
    }
  }

  void _openCalc() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _CalcSheet(onResult: (r) => setState(() => _amountCtrl.text = r)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCats = ref.watch(categoriesProvider);
    final cats    = allCats.where((c) => c.type == _type).toList();
    final canSave = _amountCtrl.text.isNotEmpty && _selectedCat != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCalc, backgroundColor: AppColors.purple, elevation: 8,
        child: const Text('🧮', style: TextStyle(fontSize: 22))),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Transaction', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
              Text('তোমার আয় বা খরচ লিখো', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ])),
            GestureDetector(onTap: _openCalc,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.purple.withOpacity(0.3))),
                child: const Row(children: [Text('🧮', style: TextStyle(fontSize: 16)), SizedBox(width: 6), Text('Calculator', style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w600))]))),
          ]),
          const SizedBox(height: 24),
          // Type toggle
          Container(padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
            child: Row(children: [TransactionType.income, TransactionType.expense].map((t) {
              final isSel = _type == t;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() { _type = t; _selectedCat = null; }),
                child: AnimatedContainer(duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(gradient: isSel ? _grad : null, borderRadius: BorderRadius.circular(13)),
                  alignment: Alignment.center,
                  child: Text(t == TransactionType.income ? '↑  Income' : '↓  Expense',
                    style: TextStyle(color: isSel ? Colors.white : AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w700)))));
            }).toList())),
          const SizedBox(height: 20),
          // Amount
          Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A2440), Color(0xFF0D1428)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20), border: Border.all(color: _col.withOpacity(0.2))),
            child: Column(children: [
              const Text('পরিমাণ লিখো', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('৳', style: TextStyle(color: _col, fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center, onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1, fontFamily: 'Syne'),
                  decoration: const InputDecoration(hintText: '0.00', hintStyle: TextStyle(color: AppColors.textDim, fontSize: 40, fontFamily: 'Syne'), border: InputBorder.none))),
              ]),
              const SizedBox(height: 8),
              Container(height: 2, decoration: BoxDecoration(gradient: _grad, borderRadius: BorderRadius.circular(1))),
            ])),
          const SizedBox(height: 20),
          // Category
          const Text('Category বেছে নাও', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          cats.isEmpty
              ? Container(padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text('🏷️ Category ট্যাব থেকে যোগ করো', style: TextStyle(color: _col, fontSize: 13, fontWeight: FontWeight.w600))))
              : GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9),
                  itemCount: cats.length,
                  itemBuilder: (_, i) {
                    final cat = cats[i]; final sel = _selectedCat?.id == cat.id;
                    return GestureDetector(onTap: () => setState(() => _selectedCat = cat),
                      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(color: sel ? _col.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                          border: Border.all(color: sel ? _col : Colors.white.withOpacity(0.07), width: 1.5), borderRadius: BorderRadius.circular(14)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(cat.icon, style: const TextStyle(fontSize: 22)), const SizedBox(height: 4),
                          Text(cat.name, style: TextStyle(color: sel ? _col : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])));
                  }),
          const SizedBox(height: 20),
          // Note
          const Text('Note', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _noteCtrl, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(hintText: 'কীসের জন্য? (ঐচ্ছিক)', hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
              filled: true, fillColor: Colors.white.withOpacity(0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.07))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.07))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
          const SizedBox(height: 16),
          // Date
          const Text('Date', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.gold)), child: child!));
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.07))),
              child: Row(children: [const Icon(Icons.calendar_today_rounded, color: AppColors.gold, size: 18), const SizedBox(width: 12),
                Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))]))),
          const SizedBox(height: 28),
          // Save
          GestureDetector(onTap: _saving ? null : _save,
            child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: double.infinity, height: 56,
              decoration: BoxDecoration(gradient: canSave ? AppColors.gradGold : null, color: canSave ? null : Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(16),
                boxShadow: canSave ? [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))] : null),
              alignment: Alignment.center,
              child: _saving ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(canSave ? 'Save Transaction ✓' : 'পরিমাণ ও Category দিন',
                      style: TextStyle(color: canSave ? const Color(0xFF0A0E1A) : AppColors.textMuted, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')))),
          const SizedBox(height: 80),
        ]),
      )),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CALCULATOR  — chained ops: 30+40+50+70 shows 190 live in display
// ══════════════════════════════════════════════════════════════════
class _CalcSheet extends StatefulWidget {
  final Function(String) onResult;
  const _CalcSheet({required this.onResult});
  @override
  State<_CalcSheet> createState() => _CalcState();
}

class _CalcState extends State<_CalcSheet> {
  String  _display = '0';
  String  _expr    = '';
  double? _acc;    // accumulator — running total
  String? _op;     // pending operator
  bool    _fresh   = false; // next digit starts new number

  String _fmt(double v) {
    if (v == v.truncateToDouble() && v.abs() < 1e12) return v.toInt().toString();
    return double.parse(v.toStringAsFixed(8)).toString();
  }

  double _calc(double a, String op, double b) {
    switch (op) {
      case '+': return a + b;
      case '-': return a - b;
      case '×': return a * b;
      case '÷': return b != 0 ? a / b : 0;
    }
    return b;
  }

  void _press(String v) {
    setState(() {
      if (v == 'C') {
        _display = '0'; _expr = ''; _acc = null; _op = null; _fresh = false; return;
      }
      if (v == '⌫') {
        _display = _display.length > 1 ? _display.substring(0, _display.length - 1) : '0'; return;
      }

      if (['+', '-', '×', '÷'].contains(v)) {
        final cur = double.tryParse(_display) ?? 0;
        if (_acc != null && _op != null && !_fresh) {
          // ── Chained op: compute running total and show it ──────
          final res = _calc(_acc!, _op!, cur);
          _acc     = res;
          _display = _fmt(res);      // <-- shows the result live
        } else {
          _acc = cur;
        }
        _op    = v;
        _expr  = '$_display $v';
        _fresh = true;
        return;
      }

      if (v == '=') {
        if (_acc != null && _op != null) {
          final cur = double.tryParse(_display) ?? 0;
          final res = _calc(_acc!, _op!, cur);
          _expr    = '$_expr ${_fresh ? '0' : _display} =';
          _display = _fmt(res);
          _acc = null; _op = null; _fresh = true;
        }
        return;
      }

      if (v == '.') {
        if (_fresh) { _display = '0.'; _fresh = false; return; }
        if (!_display.contains('.')) _display += '.';
        return;
      }

      // Digit
      if (_fresh || _display == '0') { _display = v; _fresh = false; }
      else if (_display.length < 12) _display += v;
    });
  }

  Widget _btn(String label, {Color? bg, Color? fg, int flex = 1}) {
    return Expanded(flex: flex, child: Padding(padding: const EdgeInsets.all(4),
      child: GestureDetector(onTap: () => _press(label),
        child: Container(height: 64,
          decoration: BoxDecoration(color: bg ?? const Color(0xFF1E2A40), borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: fg ?? AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Syne'))))));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0D1428), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('🧮 Calculator', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18))),
          ])),
        // Expression history
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
          child: Align(alignment: Alignment.centerRight,
            child: Text(_expr, style: const TextStyle(color: AppColors.textMuted, fontSize: 12), maxLines: 2, textAlign: TextAlign.right))),
        // Display box
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF141C2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gold.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              // Running total hint
              if (_acc != null && _op != null)
                Padding(padding: const EdgeInsets.only(bottom: 4),
                  child: Text('= ${_fmt(_acc!)}', style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600))),
              // Current input / result
              Text(_display, textAlign: TextAlign.right,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1, fontFamily: 'Syne')),
            ]))),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Column(children: [
            Row(children: [
              _btn('C', bg: AppColors.rose.withOpacity(0.2), fg: AppColors.rose),
              _btn('⌫', bg: Colors.orange.withOpacity(0.2),  fg: Colors.orange),
              _btn('%', fg: AppColors.gold),
              _btn('÷', bg: AppColors.gold.withOpacity(0.2),  fg: AppColors.gold),
            ]),
            Row(children: [_btn('7'), _btn('8'), _btn('9'), _btn('×', bg: AppColors.gold.withOpacity(0.2), fg: AppColors.gold)]),
            Row(children: [_btn('4'), _btn('5'), _btn('6'), _btn('-', bg: AppColors.gold.withOpacity(0.2), fg: AppColors.gold)]),
            Row(children: [_btn('1'), _btn('2'), _btn('3'), _btn('+', bg: AppColors.gold.withOpacity(0.2), fg: AppColors.gold)]),
            Row(children: [
              _btn('0', flex: 2), _btn('.'),
              Expanded(child: Padding(padding: const EdgeInsets.all(4),
                child: GestureDetector(
                  onTap: () {
                    double result;
                    if (_acc != null && _op != null && !_fresh) {
                      final cur = double.tryParse(_display) ?? 0;
                      result = _calc(_acc!, _op!, cur);
                    } else {
                      result = double.tryParse(_display) ?? 0;
                    }
                    widget.onResult(_fmt(result));
                    Navigator.pop(context);
                  },
                  child: Container(height: 64,
                    decoration: BoxDecoration(gradient: AppColors.gradGold, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 3))]),
                    alignment: Alignment.center,
                    child: const Text('✓ Use', style: TextStyle(color: Color(0xFF0A0E1A), fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Syne')))))),
            ]),
          ])),
        const SizedBox(height: 8),
      ]),
    );
  }
}
