// lib/presentation/screens/home_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'category/category_screen.dart';
import 'add_transaction/add_transaction_screen.dart';
import 'reports/reports_screen.dart';
import 'backup/backup_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Auto-backup once per day silently
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runAutoBackupIfNeeded(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const CategoryScreen(),
      const AddTransactionScreen(),
      const ReportsScreen(),
      const BackupScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1020),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(children: [
              _NavItem(icon: Icons.home_rounded,       label: 'Home',     index: 0, cur: _tab, onTap: () => setState(() => _tab = 0)),
              _NavItem(icon: Icons.category_rounded,   label: 'Category', index: 1, cur: _tab, onTap: () => setState(() => _tab = 1)),
              _AddBtn(onTap: () => setState(() => _tab = 2)),
              _NavItem(icon: Icons.bar_chart_rounded,  label: 'Reports',  index: 3, cur: _tab, onTap: () => setState(() => _tab = 3)),
              _NavItem(icon: Icons.cloud_done_rounded, label: 'Backup',   index: 4, cur: _tab, onTap: () => setState(() => _tab = 4)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final int index, cur; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.cur, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final active = index == cur;
    return Expanded(child: GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: active ? AppColors.gold : AppColors.textDim, size: 24),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: active ? AppColors.gold : AppColors.textDim, fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ])));
  }
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Center(child: Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.gradGold, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 3))]),
      child: const Icon(Icons.add_rounded, color: Color(0xFF0A0E1A), size: 28)))));
}
