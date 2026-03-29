import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'add_transaction/add_transaction_screen.dart';
import 'reports/reports_screen.dart';
import 'backup/backup_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ReportsScreen(),
    AddTransactionScreen(),
    BackupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E1A),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: '🏠',
                  label: 'Home',
                  active: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: '📊',
                  label: 'Reports',
                  active: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: '➕',
                  label: 'Add',
                  active: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: '☁️',
                  label: 'Backup',
                  active: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 24,
              color: active ? null : const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppColors.gold : const Color(0xFF4A5568),
            ),
          ),
          if (active) ...[
            const SizedBox(height: 3),
            Container(
              width: 4, height: 4,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
