import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/transaction.dart';

// ── Category Model ──────────────────────────────────────────
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

  AppCategory copyWith({String? name, String? icon}) =>
      AppCategory(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        type: type,
      );
}

// ── Category Provider ───────────────────────────────────────
final categoriesProvider =
    StateNotifierProvider<CategoryNotifier, List<AppCategory>>(
        (ref) => CategoryNotifier());

class CategoryNotifier extends StateNotifier<List<AppCategory>> {
  CategoryNotifier()
      : super([
          AppCategory(id: 'i1', name: 'বেতন', icon: '💼', type: TransactionType.income),
          AppCategory(id: 'i2', name: 'ফ্রিল্যান্স', icon: '💻', type: TransactionType.income),
          AppCategory(id: 'i3', name: 'বিনিয়োগ', icon: '📈', type: TransactionType.income),
          AppCategory(id: 'i4', name: 'বোনাস', icon: '🎁', type: TransactionType.income),
          AppCategory(id: 'i5', name: 'ব্যক্তিগত আয়', icon: '💰', type: TransactionType.income),
          AppCategory(id: 'e1', name: 'বাড়িভাড়া', icon: '🏠', type: TransactionType.expense),
          AppCategory(id: 'e2', name: 'বাজার', icon: '🛒', type: TransactionType.expense),
          AppCategory(id: 'e3', name: 'বিল', icon: '⚡', type: TransactionType.expense),
          AppCategory(id: 'e4', name: 'যাতায়াত', icon: '🚗', type: TransactionType.expense),
          AppCategory(id: 'e5', name: 'খাবার', icon: '🍜', type: TransactionType.expense),
          AppCategory(id: 'e6', name: 'স্বাস্থ্য', icon: '💊', type: TransactionType.expense),
          AppCategory(id: 'e7', name: 'শিক্ষা', icon: '📚', type: TransactionType.expense),
          AppCategory(id: 'e8', name: 'বিনোদন', icon: '🎬', type: TransactionType.expense),
          AppCategory(id: 'e9', name: 'ব্যক্তিগত খরচ', icon: '💳', type: TransactionType.expense),
        ]);

  void add(AppCategory cat) => state = [...state, cat];

  void remove(String id) =>
      state = state.where((c) => c.id != id).toList();

  void edit(String id, String newName, String newIcon) {
    state = state
        .map((c) => c.id == id ? c.copyWith(name: newName, icon: newIcon) : c)
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════
// CATEGORY SCREEN
// ═══════════════════════════════════════════════════════════
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
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Add Dialog ──────────────────────────────────────────
  void _showAddDialog(TransactionType type) {
    final nameCtrl = TextEditingController();
    String selectedIcon = '💰';
    final icons = [
      '💰','💳','🏦','📊','💎','🎯','🏪','🎪',
      '🏠','🛒','⚡','🚗','🍜','💊','📚','🎬',
      '✈️','👔','🎮','🏋️','🐾','🌿','🎵','📱',
      '🧴','👶','🎓','🏥','🔧','🍕','☕','🧹',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF141C2E),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24))),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(
                  type == TransactionType.income
                      ? '↑ নতুন আয়ের Category'
                      : '↓ নতুন খরচের Category',
                  style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 18,
                    fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl, autofocus: true,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Category নাম লেখো',
                    hintStyle: const TextStyle(
                        color: AppColors.textDim, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: type == TransactionType.income
                            ? AppColors.teal : AppColors.rose,
                        width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14))),
                const SizedBox(height: 16),
                const Text('Icon বেছে নাও:',
                  style: TextStyle(color: AppColors.textMuted,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 160,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 6, crossAxisSpacing: 6),
                    itemCount: icons.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setS(() => selectedIcon = icons[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selectedIcon == icons[i]
                              ? (type == TransactionType.income
                                  ? AppColors.teal.withOpacity(0.2)
                                  : AppColors.rose.withOpacity(0.2))
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedIcon == icons[i]
                                ? (type == TransactionType.income
                                    ? AppColors.teal : AppColors.rose)
                                : Colors.transparent,
                            width: 1.5)),
                        child: Center(child: Text(icons[i],
                            style: const TextStyle(fontSize: 18))))))),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    ref.read(categoriesProvider.notifier).add(
                      AppCategory(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        icon: selectedIcon,
                        type: type));
                    Navigator.pop(ctx2);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: AppColors.teal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      content: Text('✅ "${nameCtrl.text.trim()}" যোগ হয়েছে!',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w600))));
                  },
                  child: Container(
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      gradient: type == TransactionType.income
                          ? AppColors.gradTeal : AppColors.gradRose,
                      borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: const Text('Category যোগ করো',
                      style: TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Syne')))),
                const SizedBox(height: 8),
              ]))));
  }

  // ── Edit Dialog ─────────────────────────────────────────
  void _showEditDialog(AppCategory cat) {
    final nameCtrl = TextEditingController(text: cat.name);
    String selectedIcon = cat.icon;
    final icons = [
      '💰','💳','🏦','📊','💎','🎯','🏪','🎪',
      '🏠','🛒','⚡','🚗','🍜','💊','📚','🎬',
      '✈️','👔','🎮','🏋️','🐾','🌿','🎵','📱',
      '🧴','👶','🎓','🏥','🔧','🍕','☕','🧹',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF141C2E),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24))),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(children: [
                  Text(selectedIcon,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  const Text('Category Edit করো',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 18, fontWeight: FontWeight.w800,
                        fontFamily: 'Syne')),
                ]),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl, autofocus: true,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'নতুন নাম লেখো',
                    hintStyle: const TextStyle(
                        color: AppColors.textDim, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.gold, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14))),
                const SizedBox(height: 16),
                const Text('Icon বদলাও:',
                  style: TextStyle(color: AppColors.textMuted,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 160,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 6, crossAxisSpacing: 6),
                    itemCount: icons.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setS(() => selectedIcon = icons[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selectedIcon == icons[i]
                              ? AppColors.gold.withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedIcon == icons[i]
                                ? AppColors.gold : Colors.transparent,
                            width: 1.5)),
                        child: Center(child: Text(icons[i],
                            style: const TextStyle(fontSize: 18))))))),
                const SizedBox(height: 20),
                Row(children: [
                  // Save
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        ref.read(categoriesProvider.notifier)
                            .edit(cat.id, nameCtrl.text.trim(),
                                selectedIcon);
                        Navigator.pop(ctx2);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.gold,
                            behavior: SnackBarBehavior.floating,
                            content: Text('✅ Category update হয়েছে!',
                              style: TextStyle(
                                  color: Color(0xFF0A0E1A),
                                  fontWeight: FontWeight.w700))));
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradGold,
                          borderRadius: BorderRadius.circular(14)),
                        alignment: Alignment.center,
                        child: const Text('সেভ করো',
                          style: TextStyle(color: Color(0xFF0A0E1A),
                              fontSize: 15, fontWeight: FontWeight.w800,
                              fontFamily: 'Syne')))),
                  ),
                  const SizedBox(width: 10),
                  // Delete
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx2);
                      _confirmDeleteCategory(cat);
                    },
                    child: Container(
                      height: 50, width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.rose.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.rose.withOpacity(0.4))),
                      child: const Icon(Icons.delete_rounded,
                          color: AppColors.rose, size: 22))),
                ]),
                const SizedBox(height: 8),
              ]))));
  }

  // ── Confirm Delete Category ──────────────────────────────
  void _confirmDeleteCategory(AppCategory cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141C2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Text(cat.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          const Text('Delete করবে?',
            style: TextStyle(color: AppColors.textPrimary,
                fontFamily: 'Syne', fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          '"${cat.name}" category মুছে যাবে। এর লেনদেনগুলো থাকবে কিন্তু category নাম পাবে না।',
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('না, রাখো',
                style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              ref.read(categoriesProvider.notifier).remove(cat.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: AppColors.rose,
                behavior: SnackBarBehavior.floating,
                content: Text('"${cat.name}" delete হয়েছে',
                  style: const TextStyle(color: Colors.white))));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            child: const Text('হ্যাঁ, Delete করো')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final allTxs = ref.watch(transactionsProvider).maybeWhen(
      data: (t) => t, orElse: () => <Transaction>[]);
    final incomeCategories =
        categories.where((c) => c.type == TransactionType.income).toList();
    final expenseCategories =
        categories.where((c) => c.type == TransactionType.expense).toList();
    final isIncome = _tab.index == 0;
    final typeColor = isIncome ? AppColors.teal : AppColors.rose;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Categories',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 24, fontWeight: FontWeight.w800,
                        fontFamily: 'Syne')),
                  Text('${categories.length} টি · ধরে রাখো = Edit/Delete',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
                ]),
                GestureDetector(
                  onTap: () => _showAddDialog(
                    isIncome ? TransactionType.income : TransactionType.expense),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isIncome
                          ? AppColors.gradTeal : AppColors.gradRose,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color: typeColor.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 4))]),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('নতুন',
                        style: TextStyle(color: Colors.white, fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    ]))),
              ])),

          const SizedBox(height: 16),

          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06))),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: isIncome
                      ? AppColors.gradTeal : AppColors.gradRose,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(
                    color: typeColor.withOpacity(0.3), blurRadius: 8)]),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [const Text('↑ আয়'), const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)),
                        child: Text('${incomeCategories.length}',
                          style: const TextStyle(fontSize: 11)))])),
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [const Text('↓ খরচ'), const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)),
                        child: Text('${expenseCategories.length}',
                          style: const TextStyle(fontSize: 11)))])),
                ]))),

          const SizedBox(height: 8),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _CategoryList(
                  categories: incomeCategories,
                  allTxs: allTxs,
                  color: AppColors.teal,
                  onAdd: () => _showAddDialog(TransactionType.income),
                  onEdit: _showEditDialog,
                  onDelete: _confirmDeleteCategory),
                _CategoryList(
                  categories: expenseCategories,
                  allTxs: allTxs,
                  color: AppColors.rose,
                  onAdd: () => _showAddDialog(TransactionType.expense),
                  onEdit: _showEditDialog,
                  onDelete: _confirmDeleteCategory),
              ]),
          ),
        ]),
      ),
    );
  }
}

// ── Category List ───────────────────────────────────────────
class _CategoryList extends StatelessWidget {
  final List<AppCategory> categories;
  final List<Transaction> allTxs;
  final Color color;
  final VoidCallback onAdd;
  final Function(AppCategory) onEdit;
  final Function(AppCategory) onDelete;

  const _CategoryList({
    required this.categories, required this.allTxs,
    required this.color, required this.onAdd,
    required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏷️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('কোনো Category নেই',
            style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3))),
              child: Text('+ নতুন Category যোগ করো',
                style: TextStyle(color: color, fontSize: 14,
                    fontWeight: FontWeight.w700)))),
        ]));
    }

    final totalAmount = categories.fold<double>(0, (sum, cat) {
      final catTxs = allTxs.where((t) => t.category == cat.name).toList();
      return sum + catTxs.fold<double>(0, (s, t) => s + t.amount);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('মোট ${color == AppColors.teal ? 'আয়' : 'খরচ'}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
                Text('৳${totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(color: color, fontSize: 20,
                      fontWeight: FontWeight.w800, fontFamily: 'Syne')),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${categories.length} টি category',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
                const Text('ধরে রাখো = Edit/Delete',
                  style: TextStyle(color: AppColors.textDim, fontSize: 10)),
              ]),
            ])),

        ...categories.map((cat) {
          final catTxs =
              allTxs.where((t) => t.category == cat.name).toList();
          final total =
              catTxs.fold<double>(0, (s, t) => s + t.amount);

          return GestureDetector(
            // ধরে রাখলে Edit/Delete
            onLongPress: () => onEdit(cat),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailScreen(
                  category: cat, transactions: catTxs, color: color))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141C2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withOpacity(0.06))),
              child: Row(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color.withOpacity(0.25))),
                  child: Center(child: Text(cat.icon,
                      style: const TextStyle(fontSize: 24)))),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14,
                      fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(catTxs.isEmpty
                        ? 'কোনো লেনদেন নেই'
                        : '${catTxs.length} টি লেনদেন',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                  ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('৳${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: catTxs.isEmpty ? AppColors.textDim : color,
                      fontSize: 15, fontWeight: FontWeight.w800,
                      fontFamily: 'Syne')),
                  const Text('মোট', style: TextStyle(
                      color: AppColors.textDim, fontSize: 11)),
                ]),
                const SizedBox(width: 6),
                // Edit icon hint
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textDim, size: 16)),
              ])));
        }),
      ]);
  }
}

// ── Category Detail Screen ──────────────────────────────────
class CategoryDetailScreen extends ConsumerWidget {
  final AppCategory category;
  final List<Transaction> transactions;
  final Color color;

  const CategoryDetailScreen({super.key,
    required this.category, required this.transactions,
    required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveTxs = ref.watch(transactionsProvider).maybeWhen(
      data: (txs) =>
          txs.where((t) => t.category == category.name).toList(),
      orElse: () => transactions);
    final total = liveTxs.fold<double>(0, (s, t) => s + t.amount);
    final isIncome = category.type == TransactionType.income;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(children: [
          Text(category.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(category.name, style: const TextStyle(
            color: AppColors.textPrimary, fontFamily: 'Syne',
            fontWeight: FontWeight.w700, fontSize: 18)),
        ]),
        backgroundColor: AppColors.bg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.25))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('মোট ${isIncome ? 'আয়' : 'খরচ'}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('৳${total.toStringAsFixed(0)}',
                    style: TextStyle(color: color, fontSize: 28,
                        fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                  Text('${liveTxs.length} টি লেনদেন',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                ]),
                Text(category.icon,
                    style: const TextStyle(fontSize: 48)),
              ])),
        ),
        Expanded(
          child: liveTxs.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(category.icon,
                        style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text('এই Category তে কোনো লেনদেন নেই',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('Add ➕ থেকে "${category.name}" বেছে যোগ করো',
                      style: TextStyle(color: color, fontSize: 12,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: liveTxs.length,
                  itemBuilder: (_, i) {
                    final tx = liveTxs[i];
                    return Dismissible(
                      key: Key(tx.id),
                      direction: DismissDirection.endToStart,
                      // ── Confirm before delete ──
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
                                fontWeight: FontWeight.w700)),
                            content: Text(
                              '"${tx.note}" — ৳${tx.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13)),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('না',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 15))),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.rose,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10))),
                                child: const Text('হ্যাঁ, Delete')),
                            ]));
                      },
                      onDismissed: (_) => ref
                          .read(transactionsProvider.notifier)
                          .remove(tx.id),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.rose,
                          borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141C2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.06))),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.note, style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(
                                '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11)),
                            ])),
                          Text(
                            '${isIncome ? '+' : '-'}৳${tx.amount.toStringAsFixed(0)}',
                            style: TextStyle(color: color, fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Syne')),
                        ]));
                  })),
      ]),
    );
  }
}
