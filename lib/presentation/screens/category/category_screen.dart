import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/transaction.dart';

class AppCategory {
  final String id;
  final String name;
  final String icon;
  final TransactionType type;
  AppCategory({required this.id, required this.name, required this.icon, required this.type});
}

final categoriesProvider = StateNotifierProvider<CategoryNotifier, List<AppCategory>>((ref) => CategoryNotifier());

class CategoryNotifier extends StateNotifier<List<AppCategory>> {
  CategoryNotifier() : super([
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
  void remove(String id) => state = state.where((c) => c.id != id).toList();
}

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});
  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _tab.addListener(() => setState(() {})); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _showAddDialog(TransactionType type) {
    final nameCtrl = TextEditingController();
    String selectedIcon = '💰';
    final icons = ['💰','💳','🏦','📊','💎','🎯','🏪','🎪','🏠','🛒','⚡','🚗','🍜','💊','📚','🎬','✈️','👔','🎮','🏋️','🐾','🌿','🎵','📱','🧴','👶','🎓','🏥','🔧','🍕','☕','🧹'];
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(color: Color(0xFF141C2E), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(type == TransactionType.income ? '↑ নতুন আয়ের Category' : '↓ নতুন খরচের Category',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
          const SizedBox(height: 20),
          TextField(controller: nameCtrl, autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Category নাম লেখো (বাংলায়)',
              hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
              filled: true, fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: type == TransactionType.income ? AppColors.teal : AppColors.rose, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            )),
          const SizedBox(height: 16),
          const Text('Icon বেছে নাও:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SizedBox(height: 160, child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 6, crossAxisSpacing: 6),
            itemCount: icons.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setS(() => selectedIcon = icons[i]),
              child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selectedIcon == icons[i] ? (type == TransactionType.income ? AppColors.teal.withOpacity(0.2) : AppColors.rose.withOpacity(0.2)) : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selectedIcon == icons[i] ? (type == TransactionType.income ? AppColors.teal : AppColors.rose) : Colors.transparent, width: 1.5)),
                child: Center(child: Text(icons[i], style: const TextStyle(fontSize: 18))))))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              if (nameCtrl.text.trim().isEmpty) return;
              ref.read(categoriesProvider.notifier).add(AppCategory(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text.trim(), icon: selectedIcon, type: type));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.teal, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                content: Text('✅ "${nameCtrl.text.trim()}" Category যোগ হয়েছে!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))));
            },
            child: Container(width: double.infinity, height: 52,
              decoration: BoxDecoration(
                gradient: type == TransactionType.income ? AppColors.gradTeal : AppColors.gradRose,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: (type == TransactionType.income ? AppColors.teal : AppColors.rose).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))]),
              alignment: Alignment.center,
              child: const Text('Category যোগ করো', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')))),
          const SizedBox(height: 8),
        ])))));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final allTxs = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <Transaction>[]);
    final incomeCategories = categories.where((c) => c.type == TransactionType.income).toList();
    final expenseCategories = categories.where((c) => c.type == TransactionType.expense).toList();
    final isIncome = _tab.index == 0;
    final typeColor = isIncome ? AppColors.teal : AppColors.rose;

    return Scaffold(backgroundColor: AppColors.bg, body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Categories', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
          Text('${categories.length} টি category', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
        GestureDetector(
          onTap: () => _showAddDialog(isIncome ? TransactionType.income : TransactionType.expense),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(gradient: isIncome ? AppColors.gradTeal : AppColors.gradRose, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: typeColor.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('নতুন Category', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ]))),
      ])),
      const SizedBox(height: 16),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: TabBar(controller: _tab,
          indicator: BoxDecoration(gradient: isIncome ? AppColors.gradTeal : AppColors.gradRose, borderRadius: BorderRadius.circular(11),
            boxShadow: [BoxShadow(color: typeColor.withOpacity(0.3), blurRadius: 8)]),
          labelColor: Colors.white, unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('↑ আয়'), const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('${incomeCategories.length}', style: const TextStyle(fontSize: 11)))])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('↓ খরচ'), const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('${expenseCategories.length}', style: const TextStyle(fontSize: 11)))])),
          ]))),
      const SizedBox(height: 8),
      Expanded(child: TabBarView(controller: _tab, children: [
        _CategoryList(categories: incomeCategories, allTxs: allTxs, color: AppColors.teal, onAdd: () => _showAddDialog(TransactionType.income), onDelete: (id) => ref.read(categoriesProvider.notifier).remove(id)),
        _CategoryList(categories: expenseCategories, allTxs: allTxs, color: AppColors.rose, onAdd: () => _showAddDialog(TransactionType.expense), onDelete: (id) => ref.read(categoriesProvider.notifier).remove(id)),
      ])),
    ])));
  }
}

class _CategoryList extends StatelessWidget {
  final List<AppCategory> categories;
  final List<Transaction> allTxs;
  final Color color;
  final VoidCallback onAdd;
  final Function(String) onDelete;
  const _CategoryList({required this.categories, required this.allTxs, required this.color, required this.onAdd, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🏷️', style: TextStyle(fontSize: 48)), const SizedBox(height: 16),
      const Text('কোনো Category নেই', style: TextStyle(color: AppColors.textMuted, fontSize: 15)), const SizedBox(height: 12),
      GestureDetector(onTap: onAdd, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Text('+ নতুন Category যোগ করো', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700))))]));

    final totalAmount = categories.fold<double>(0, (sum, cat) { final catTxs = allTxs.where((t) => t.category == cat.name).toList(); return sum + catTxs.fold<double>(0, (s, t) => s + t.amount); });

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
      Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('মোট ${color == AppColors.teal ? 'আয়' : 'খরচ'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            Text('৳${totalAmount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Syne'))]),
          Text('${categories.length} টি category', style: const TextStyle(color: AppColors.textMuted, fontSize: 12))])),
      ...categories.map((cat) {
        final catTxs = allTxs.where((t) => t.category == cat.name).toList();
        final total = catTxs.fold<double>(0, (s, t) => s + t.amount);
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(category: cat, transactions: catTxs, color: color))),
          child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF141C2E), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.06))),
            child: Row(children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.25))),
                child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 24)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(catTxs.isEmpty ? 'কোনো লেনদেন নেই' : '${catTxs.length} টি লেনদেন', style: const TextStyle(color: AppColors.textMuted, fontSize: 12))])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('৳${total.toStringAsFixed(0)}', style: TextStyle(color: catTxs.isEmpty ? AppColors.textDim : color, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                const Text('মোট', style: TextStyle(color: AppColors.textDim, fontSize: 11))]),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 20)])));
      })]);
  }
}

class CategoryDetailScreen extends ConsumerWidget {
  final AppCategory category;
  final List<Transaction> transactions;
  final Color color;
  const CategoryDetailScreen({super.key, required this.category, required this.transactions, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveTxs = ref.watch(transactionsProvider).maybeWhen(data: (txs) => txs.where((t) => t.category == category.name).toList(), orElse: () => transactions);
    final total = liveTxs.fold<double>(0, (s, t) => s + t.amount);
    final isIncome = category.type == TransactionType.income;

    return Scaffold(backgroundColor: AppColors.bg,
      appBar: AppBar(title: Row(children: [Text(category.icon, style: const TextStyle(fontSize: 22)), const SizedBox(width: 8),
        Text(category.name, style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 18))]),
        backgroundColor: AppColors.bg,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary))),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(20), child: Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.25))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('মোট ${isIncome ? 'আয়' : 'খরচ'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text('৳${total.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
              Text('${liveTxs.length} টি লেনদেন', style: const TextStyle(color: AppColors.textMuted, fontSize: 12))]),
            Text(category.icon, style: const TextStyle(fontSize: 48))]))),
        Expanded(child: liveTxs.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(category.icon, style: const TextStyle(fontSize: 48)), const SizedBox(height: 12),
              const Text('এই Category তে কোনো লেনদেন নেই', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Add ➕ থেকে "${category.name}" বেছে যোগ করো', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)]))
          : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: liveTxs.length, itemBuilder: (_, i) {
              final tx = liveTxs[i];
              return Dismissible(key: Key(tx.id), direction: DismissDirection.endToStart,
                background: Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: AppColors.rose, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_rounded, color: Colors.white)),
                onDismissed: (_) => ref.read(transactionsProvider.notifier).remove(tx.id),
                child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF141C2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tx.note, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${tx.date.day}/${tx.date.month}/${tx.date.year}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11))])),
                    Text('${isIncome ? '+' : '-'}৳${tx.amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Syne'))])));
            }))]);
  }
}
