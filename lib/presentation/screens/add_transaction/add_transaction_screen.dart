import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../domain/models/transaction.dart';
import '../../providers/transaction_provider.dart';

const _incomeCategories = [
  {'name': 'Salary',      'icon': '💼'},
  {'name': 'Freelancing', 'icon': '💻'},
  {'name': 'Investment',  'icon': '📈'},
  {'name': 'Business',    'icon': '🏢'},
  {'name': 'Bonus',       'icon': '🎁'},
  {'name': 'Other',       'icon': '💰'},
];

const _expenseCategories = [
  {'name': 'Rent',          'icon': '🏠'},
  {'name': 'Groceries',     'icon': '🛒'},
  {'name': 'Bills',         'icon': '⚡'},
  {'name': 'Transport',     'icon': '🚗'},
  {'name': 'Food',          'icon': '🍜'},
  {'name': 'Health',        'icon': '💊'},
  {'name': 'Shopping',      'icon': '🛍️'},
  {'name': 'Education',     'icon': '📚'},
  {'name': 'Entertainment', 'icon': '🎬'},
  {'name': 'Other',         'icon': '📦'},
];

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  Map<String, dynamic>? _selectedCategory;
  DateTime _date = DateTime.now();
  bool _saving = false;

  List<Map<String, dynamic>> get _categories =>
      _type == TransactionType.income
          ? _incomeCategories
          : _expenseCategories;

  Color get _typeColor =>
      _type == TransactionType.income ? AppColors.teal : AppColors.rose;

  Gradient get _typeGrad =>
      _type == TransactionType.income
          ? AppColors.gradTeal
          : AppColors.gradRose;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty || _selectedCategory == null) return;
    setState(() => _saving = true);

    await ref.read(transactionsProvider.notifier).add(
      type: _type,
      category: _selectedCategory!['name'] as String,
      amount: double.parse(_amountCtrl.text),
      note: _noteCtrl.text.isNotEmpty
          ? _noteCtrl.text
          : _selectedCategory!['name'] as String,
      date: _date,
      icon: _selectedCategory!['icon'] as String,
    );

    setState(() => _saving = false);
    _amountCtrl.clear();
    _noteCtrl.clear();
    setState(() => _selectedCategory = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.teal,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          content: const Row(children: [
            Text('✅ ', style: TextStyle(fontSize: 16)),
            Text('Transaction সফলভাবে সেভ হয়েছে!',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        _amountCtrl.text.isNotEmpty && _selectedCategory != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              const Text('Add Transaction',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24, fontWeight: FontWeight.w800,
                  fontFamily: 'Syne',
                )),
              const SizedBox(height: 4),
              const Text('তোমার আয় বা খরচ লিখো',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),

              const SizedBox(height: 24),

              // ── Type Toggle ──
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    TransactionType.income,
                    TransactionType.expense,
                  ].map((t) {
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
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected ? _typeGrad : null,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: isSelected
                                ? [BoxShadow(
                                    color: _typeColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  )]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isIncome ? '↑  Income' : '↓  Expense',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // ── Amount Input ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A2440), Color(0xFF0D1428)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _typeColor.withOpacity(0.2)),
                ),
                child: Column(children: [
                  const Text('পরিমাণ লিখো',
                    style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12,
                      letterSpacing: 1.1, fontWeight: FontWeight.w600,
                    )),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('৳',
                        style: TextStyle(
                          color: _typeColor, fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Syne',
                        )),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textAlign: TextAlign.center,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            fontFamily: 'Syne',
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 40,
                              fontFamily: 'Syne',
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: _typeGrad,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Category ──
              const Text('Category',
                style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 1.1,
                )),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected =
                      _selectedCategory?['name'] == cat['name'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected
                            ? _typeColor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.04),
                        border: Border.all(
                          color: selected
                              ? _typeColor
                              : Colors.white.withOpacity(0.07),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat['icon'] as String,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(cat['name'] as String,
                            style: TextStyle(
                              color: selected
                                  ? _typeColor
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Note ──
              const Text('Note',
                style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 1.1,
                )),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'কীসের জন্য?',
                  hintStyle: const TextStyle(
                      color: AppColors.textDim, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.07)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.07)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.gold, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 16),

              // ── Date ──
              const Text('Date',
                style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 1.1,
                )),
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
                        colorScheme: const ColorScheme.dark(
                            primary: AppColors.gold),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.gold, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      '${_date.day}/${_date.month}/${_date.year}',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 28),

              // ── Save Button ──
              GestureDetector(
                onTap: _saving ? null : _save,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: canSave ? AppColors.gradGold : null,
                    color: canSave
                        ? null
                        : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canSave
                        ? [BoxShadow(
                            color: AppColors.gold.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          )]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text('Save Transaction',
                          style: TextStyle(
                            color: canSave
                                ? const Color(0xFF0A0E1A)
                                : AppColors.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Syne',
                          )),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
