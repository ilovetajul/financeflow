// lib/presentation/screens/category/category_screen.dart
// Categories are saved to SharedPreferences — they NEVER disappear on restart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/transaction.dart';

// ── Model ─────────────────────────────────────────────────────────
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'type': type.name,
  };

  factory AppCategory.fromJson(Map<String, dynamic> j) => AppCategory(
    id: j['id'] as String,
    name: j['name'] as String,
    icon: j['icon'] as String,
    type: TransactionType.values.byName(j['type'] as String),
  );
}

// ── Default categories ─────────────────────────────────────────────
List<AppCategory> _defaults() => [
  AppCategory(id: 'i1', name: 'বেতন',        icon: '💼', type: TransactionType.income),
  AppCategory(id: 'i2', name: 'ফ্রিল্যান্স', icon: '💻', type: TransactionType.income),
  AppCategory(id: 'i3', name: 'বিনিয়োগ',    icon: '📈', type: TransactionType.income),
  AppCategory(id: 'i4', name: 'বোনাস',       icon: '🎁', type: TransactionType.income),
  AppCategory(id: 'i5', name: 'ব্যক্তিগত আয়', icon: '💰', type: TransactionType.income),
  AppCategory(id: 'e1', name: 'বাড়িভাড়া',  icon: '🏠', type: TransactionType.expense),
  AppCategory(id: 'e2', name: 'বাজার',       icon: '🛒', type: TransactionType.expense),
  AppCategory(id: 'e3', name: 'বিল',         icon: '⚡', type: TransactionType.expense),
  AppCategory(id: 'e4', name: 'যাতায়াত',   icon: '🚗', type: TransactionType.expense),
  AppCategory(id: 'e5', name: 'খাবার',       icon: '🍜', type: TransactionType.expense),
  AppCategory(id: 'e6', name: 'স্বাস্থ্য',  icon: '💊', type: TransactionType.expense),
  AppCategory(id: 'e7', name: 'শিক্ষা',      icon: '📚', type: TransactionType.expense),
  AppCategory(id: 'e8', name: 'বিনোদন',     icon: '🎬', type: TransactionType.expense),
  AppCategory(id: 'e9', name: 'ব্যক্তিগত খরচ', icon: '💳', type: TransactionType.expense),
];

// ── Provider ──────────────────────────────────────────────────────
class CategoryNotifier extends StateNotifier<List<AppCategory>> {
  CategoryNotifier() : super([]) {
    _load();
  }

  static const _key = 'app_categories';

  // Load from SharedPreferences; fall back to defaults on first run
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        state = list
            .map((e) => AppCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        return;
      } catch (_) {}
    }
    // First run → save defaults
    state = _defaults();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> add(AppCategory cat) async {
    state = [...state, cat];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _persist();
  }

  Future<void> edit(String id, String newName, String newIcon) async {
    state = state
        .map((c) => c.id == id
            ? AppCategory(id: c.id, name: newName, icon: newIcon, type: c.type)
            : c)
        .toList();
    await _persist();
  }

  // Used by backup restore
  Future<void> restoreAll(List<AppCategory> cats) async {
    state = cats;
    await _persist();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoryNotifier, List<AppCategory>>(
        (ref) => CategoryNotifier());

// ── Emoji list ────────────────────────────────────────────────────
const _icons = [
  '💰','💳','🏦','📊','💎','🎯','🏪','🎪',
  '🏠','🛒','⚡','🚗','🍜','💊','📚','🎬',
  '✈️','👔','🎮','🏋️','🐾','🌿','🎵','📱',
  '🧴','👶','🎓','🏥','🔧','🍕','☕','🧹',
];

// ══════════════════════════════════════════════════════════════════
// CATEGORY SCREEN
// ══════════════════════════════════════════════════════════════════
class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});
  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
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

  // ── Add ───────────────────────────────────────────────────────
  void _showAdd(TransactionType type) {
    final ctrl = TextEditingController();
    String selIcon = '💰';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF141C2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(
                  type == TransactionType.income ? '↑ নতুন আয়ের Category' : '↓ নতুন খরচের Category',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Syne'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Category নাম লেখো',
                    hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: type == TransactionType.income ? AppColors.teal : AppColors.rose, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Icon বেছে নাও:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 160,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 6, crossAxisSpacing: 6),
                    itemCount: _icons.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setS(() => selIcon = _icons[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selIcon == _icons[i]
                              ? (type == TransactionType.income ? AppColors.teal.withOpacity(0.2) : AppColors.rose.withOpacity(0.2))
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selIcon == _icons[i]
                                ? (type == TransactionType.income ? AppColors.teal : AppColors.rose)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(child: Text(_icons[i], style: const TextStyle(fontSize: 18))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    if (ctrl.text.trim().isEmpty) return;
                    ref.read(categoriesProvider.notifier).add(AppCategory(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: ctrl.text.trim(),
                      icon: selIcon,
                      type: type,
                    ));
                    Navigator.pop(ctx2);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: AppColors.teal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: Text('✅ "${ctrl.text.trim()}" যোগ হয়েছে!',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ));
                  },
                  child: Container(
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      gradient: type == TransactionType.income ? AppColors.gradTeal : AppColors.gradRose,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Category যোগ করো',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit ──────────────────────────────────────────────────────
  void _showEdit(AppCategory cat) {
    final ctrl = TextEditingController(text: cat.name);
    String selIcon = cat.icon;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF141C2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(children: [
                  Text(selIcon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  const Text('Category Edit করো',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                ]),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'নতুন নাম লেখো',
                    hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Icon বদলাও:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 160,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 6, crossAxisSpacing: 6),
                    itemCount: _icons.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setS(() => selIcon = _icons[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selIcon == _icons[i] ? AppColors.gold.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selIcon == _icons[i] ? AppColors.gold : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(child: Text(_icons[i], style: const TextStyle(fontSize: 18))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (ctrl.text.trim().isEmpty) return;
                        ref.read(categoriesProvider.notifier).edit(cat.id, ctrl.text.trim(), selIcon);
                        Navigator.pop(ctx2);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          backgroundColor: AppColors.gold,
                          behavior: SnackBarBehavior.floating,
                          content: Text('✅ Category update হয়েছে!',
                            style: TextStyle(color: Color(0xFF0A0E1A), fontWeight: FontWeight.w700)),
                        ));
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(gradient: AppColors.gradGold, borderRadius: BorderRadius.circular(14)),
                        alignment: Alignment.center,
                        child: const Text('সেভ করো',
                          style: TextStyle(color: Color(0xFF0A0E1A), fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx2);
                      _confirmDelete(cat);
                    },
                    child: Container(
                      height: 50, width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.rose.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.rose.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.delete_rounded, color: AppColors.rose, size: 22),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(AppCategory cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Text(cat.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          const Text('Delete করবে?', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700)),
        ]),
        content: Text('"${cat.name}" category মুছে যাবে।',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('না, রাখো', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(categoriesProvider.notifier).remove(cat.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: AppColors.rose,
                behavior: SnackBarBehavior.floating,
                content: Text('"${cat.name}" delete হয়েছে',
                  style: const TextStyle(color: Colors.white)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('হ্যাঁ, Delete করো'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final allTxs = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <Transaction>[]);
    final incCats = categories.where((c) => c.type == TransactionType.income).toList();
    final expCats = categories.where((c) => c.type == TransactionType.expense).toList();
    final isIncome = _tab.index == 0;
    final typeColor = isIncome ? AppColors.teal : AppColors.rose;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Categories', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                Text('${categories.length} টি · ধরে রাখো = Edit', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
              GestureDetector(
                onTap: () => _showAdd(isIncome ? TransactionType.income : TransactionType.expense),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isIncome ? AppColors.gradTeal : AppColors.gradRose,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: typeColor.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('নতুন', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: isIncome ? AppColors.gradTeal : AppColors.gradRose,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(color: typeColor.withOpacity(0.3), blurRadius: 8)],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('↑ আয়'), const SizedBox(width: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('${incCats.length}', style: const TextStyle(fontSize: 11))),
                  ])),
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('↓ খরচ'), const SizedBox(width: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('${expCats.length}', style: const TextStyle(fontSize: 11))),
                  ])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _CatList(cats: incCats, allTxs: allTxs, color: AppColors.teal,
                  onAdd: () => _showAdd(TransactionType.income), onEdit: _showEdit),
                _CatList(cats: expCats, allTxs: allTxs, color: AppColors.rose,
                  onAdd: () => _showAdd(TransactionType.expense), onEdit: _showEdit),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CatList extends StatelessWidget {
  final List<AppCategory> cats;
  final List<Transaction> allTxs;
  final Color color;
  final VoidCallback onAdd;
  final Function(AppCategory) onEdit;
  const _CatList({required this.cats, required this.allTxs, required this.color, required this.onAdd, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    if (cats.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🏷️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text('কোনো Category নেই', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
            child: Text('+ নতুন Category যোগ করো', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ]));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.info_outline_rounded, color: AppColors.textDim, size: 13),
            SizedBox(width: 6),
            Text('ধরে রাখো = Edit / Delete', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
          ]),
        ),
        ...cats.map((cat) {
          final catTxs = allTxs.where((t) => t.category == cat.name).toList();
          final total = catTxs.fold<double>(0, (s, t) => s + t.amount);
          return GestureDetector(
            onLongPress: () => onEdit(cat),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141C2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cat.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(catTxs.isEmpty ? 'কোনো লেনদেন নেই' : '${catTxs.length} টি লেনদেন',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('৳${total.toStringAsFixed(0)}',
                    style: TextStyle(color: catTxs.isEmpty ? AppColors.textDim : color, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                  const Text('মোট', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                ]),
                const SizedBox(width: 6),
                Icon(Icons.more_vert_rounded, color: color.withOpacity(0.4), size: 18),
              ]),
            ),
          );
        }),
      ],
    );
  }
}
