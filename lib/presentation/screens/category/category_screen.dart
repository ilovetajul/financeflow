import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/transaction.dart';

// ── Category Model ──
class AppCategory {
  final String id;
  final String name;
  final String icon;
  final TransactionType type;

  AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });
}

// ── Category Provider ──
final categoriesProvider =
    StateNotifierProvider<CategoryNotifier, List<AppCategory>>(
        (ref) => CategoryNotifier());

class CategoryNotifier extends StateNotifier<List<AppCategory>> {
  CategoryNotifier()
      : super([
          AppCategory(id: '1', name: 'বেতন', icon: '💼', type: TransactionType.income),
          AppCategory(id: '2', name: 'ফ্রিল্যান্স', icon: '💻', type: TransactionType.income),
          AppCategory(id: '3', name: 'বিনিয়োগ', icon: '📈', type: TransactionType.income),
          AppCategory(id: '4', name: 'বোনাস', icon: '🎁', type: TransactionType.income),
          AppCategory(id: '5', name: 'বাড়িভাড়া', icon: '🏠', type: TransactionType.expense),
          AppCategory(id: '6', name: 'বাজার', icon: '🛒', type: TransactionType.expense),
          AppCategory(id: '7', name: 'বিল', icon: '⚡', type: TransactionType.expense),
          AppCategory(id: '8', name: 'যাতায়াত', icon: '🚗', type: TransactionType.expense),
          AppCategory(id: '9', name: 'খাবার', icon: '🍜', type: TransactionType.expense),
          AppCategory(id: '10', name: 'স্বাস্থ্য', icon: '💊', type: TransactionType.expense),
          AppCategory(id: '11', name: 'শিক্ষা', icon: '📚', type: TransactionType.expense),
          AppCategory(id: '12', name: 'বিনোদন', icon: '🎬', type: TransactionType.expense),
        ]);

  void add(AppCategory cat) => state = [...state, cat];

  void remove(String id) =>
      state = state.where((c) => c.id != id).toList();
}

// ── Category Screen ──
class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() =>
      _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _showAddDialog(TransactionType type) {
    final nameCtrl = TextEditingController();
    String selectedIcon = '💰';

    final icons = [
      '💰','💳','🏦','📊','💎','🎯','🏪','🎪',
      '🏠','🛒','⚡','🚗','🍜','💊','📚','🎬',
      '✈️','👔','🎮','🏋️','🐾','🌿','🎵','📱',
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF141C2E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            type == TransactionType.income
                ? '✅ আয়ের Category যোগ করো'
                : '📦 খরচের Category যোগ করো',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name input
              TextField(
                controller: nameCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Category নাম লেখো',
                  hintStyle: const TextStyle(
                      color: AppColors.textDim, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.gold, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Icon picker
              const Text('Icon বেছে নাও:',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: icons.map((icon) => GestureDetector(
                  onTap: () =>
                      setState(() => selectedIcon = icon),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: selectedIcon == icon
                          ? AppColors.gold.withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedIcon == icon
                            ? AppColors.gold
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(icon,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                ref.read(categoriesProvider.notifier).add(
                  AppCategory(
                    id: DateTime.now().toString(),
                    name: nameCtrl.text.trim(),
                    icon: selectedIcon,
                    type: type,
                  ),
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF0A0E1A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('যোগ করো',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final allTxs = ref.watch(transactionsProvider).maybeWhen(
      data: (t) => t,
      orElse: () => <Transaction>[],
    );

    final incomeCategories =
        categories.where((c) => c.type == TransactionType.income).toList();
    final expenseCategories =
        categories.where((c) => c.type == TransactionType.expense).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Categories',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Syne',
                    )),
                  GestureDetector(
                    onTap: () => _showAddDialog(
                      _tab.index == 0
                          ? TransactionType.income
                          : TransactionType.expense,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradGold,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(
                          color: AppColors.gold.withOpacity(0.3),
                          blurRadius: 8,
                        )],
                      ),
                      child: const Row(children: [
                        Icon(Icons.add, color: Color(0xFF0A0E1A), size: 16),
                        SizedBox(width: 4),
                        Text('নতুন',
                          style: TextStyle(
                            color: Color(0xFF0A0E1A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          )),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: AppColors.gradTeal,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(
                    color: AppColors.teal.withOpacity(0.3),
                    blurRadius: 8,
                  )],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '↑ আয়ের Category'),
                  Tab(text: '↓ খরচের Category'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _CategoryList(
                    categories: incomeCategories,
                    allTxs: allTxs,
                    color: AppColors.teal,
                    onAdd: () => _showAddDialog(TransactionType.income),
                  ),
                  _CategoryList(
                    categories: expenseCategories,
                    allTxs: allTxs,
                    color: AppColors.rose,
                    onAdd: () =>
                        _showAddDialog(TransactionType.expense),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final List<AppCategory> categories;
  final List<Transaction> allTxs;
  final Color color;
  final VoidCallback onAdd;

  const _CategoryList({
    required this.categories,
    required this.allTxs,
    required this.color,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏷️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('কোনো Category নেই',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 15)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onAdd,
              child: Text('+ নতুন Category যোগ করো',
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final catTxs = allTxs
            .where((t) => t.category == cat.name)
            .toList();
        final total = catTxs.fold<double>(
            0, (s, t) => s + t.amount);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryDetailScreen(
                category: cat,
                transactions: catTxs,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141C2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(cat.icon,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
                    Text('${catTxs.length} টি লেনদেন',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Syne',
                    ),
                  ),
                  const Text('মোট',
                    style: TextStyle(
                        color: AppColors.textDim, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textDim, size: 18),
            ]),
          ),
        );
      },
    );
  }
}

// ── Category Detail Screen ──
class CategoryDetailScreen extends StatelessWidget {
  final AppCategory category;
  final List<Transaction> transactions;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = category.type == TransactionType.income;
    final color = isIncome ? AppColors.teal : AppColors.rose;
    final total =
        transactions.fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(children: [
          Text(category.icon,
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(category.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
            )),
        ]),
        backgroundColor: AppColors.bg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Total card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('মোট ${isIncome ? 'আয়' : 'খরচ'}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                      Text('৳${total.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Syne',
                        )),
                    ],
                  ),
                  Text(category.icon,
                      style: const TextStyle(fontSize: 44)),
                ],
              ),
            ),
          ),

          // Transaction list
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Text('কোনো লেনদেন নেই',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 14)),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: transactions.length,
                    itemBuilder: (_, i) {
                      final tx = transactions[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141C2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(tx.note,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  )),
                                Text(
                                  '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(
                            '${isIncome ? '+' : '-'}৳${tx.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Syne',
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
