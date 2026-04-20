// lib/presentation/screens/backup/backup_screen.dart
// Backup now includes categories — restore brings back all transactions + categories

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../category/category_screen.dart';
import '../../../domain/models/transaction.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String? _lastMsg;

  // ── Backup ───────────────────────────────────────────────────
  Future<void> _backup() async {
    setState(() { _busy = true; _lastMsg = null; });
    try {
      final txs = ref.read(transactionsProvider).maybeWhen(
        data: (t) => t, orElse: () => <Transaction>[]);
      final cats = ref.read(categoriesProvider);

      final payload = jsonEncode({
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'transactions': txs.map((t) => t.toJson()).toList(),
        'categories': cats.map((c) => c.toJson()).toList(),
      });

      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now();
      final fname =
          'financeflow_backup_${ts.year}${ts.month.toString().padLeft(2,'0')}${ts.day.toString().padLeft(2,'0')}.json';
      final file = File('${dir.path}/$fname');
      await file.writeAsString(payload);

      // Also save to Downloads
      try {
        final dl = Directory('/storage/emulated/0/Download/FinanceFlow');
        if (!await dl.exists()) await dl.create(recursive: true);
        await File('${dl.path}/$fname').writeAsString(payload);
      } catch (_) {}

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'FinanceFlow Backup',
        text: 'FinanceFlow backup file — transactions + categories',
      );

      setState(() { _busy = false; _lastMsg = '✅ Backup সফল! Download/FinanceFlow/ তেও save হয়েছে।'; });
    } catch (e) {
      setState(() { _busy = false; _lastMsg = '❌ Error: $e'; });
    }
  }

  // ── Restore ──────────────────────────────────────────────────
  Future<void> _restore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restore করবে?',
          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700)),
        content: const Text(
          'বর্তমান সব লেনদেন ও category মুছে যাবে এবং backup থেকে ফিরে আসবে।',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('হ্যাঁ, Restore করো')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() { _busy = true; _lastMsg = null; });
    try {
      final path = result.files.first.path!;
      final content = await File(path).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final version = data['version'] as int? ?? 1;

      // Restore transactions
      final txList = data['transactions'] as List<dynamic>;
      final txs = txList.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
      await ref.read(transactionsProvider.notifier).restoreAll(txs);

      // Restore categories (version 2+)
      if (version >= 2 && data.containsKey('categories')) {
        final catList = data['categories'] as List<dynamic>;
        final cats = catList.map((e) => AppCategory.fromJson(e as Map<String, dynamic>)).toList();
        await ref.read(categoriesProvider.notifier).restoreAll(cats);
        setState(() { _busy = false; _lastMsg = '✅ Restore সফল! ${txs.length} টি লেনদেন ও ${cats.length} টি category ফিরে এসেছে।'; });
      } else {
        setState(() { _busy = false; _lastMsg = '✅ Restore সফল! ${txs.length} টি লেনদেন ফিরে এসেছে। (পুরনো backup — category নেই)'; });
      }
    } catch (e) {
      setState(() { _busy = false; _lastMsg = '❌ Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(transactionsProvider).maybeWhen(
      data: (t) => t, orElse: () => <Transaction>[]);
    final cats = ref.watch(categoriesProvider);
    final totalIncome = txs.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
    final totalExpense = txs.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            const Text('Backup & Restore',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
            const Text('তোমার ডেটা সুরক্ষিত রাখো',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 24),

            // Data summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141C2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(children: [
                const Text('বর্তমান ডেটা',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
                const SizedBox(height: 12),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Row(children: [
                  _InfoItem(label: 'লেনদেন', value: '${txs.length} টি', color: AppColors.gold),
                  _InfoItem(label: 'Category', value: '${cats.length} টি', color: AppColors.purple),
                  _InfoItem(label: 'আয়', value: '৳${totalIncome.toStringAsFixed(0)}', color: AppColors.teal),
                  _InfoItem(label: 'খরচ', value: '৳${totalExpense.toStringAsFixed(0)}', color: AppColors.rose),
                ]),
              ]),
            ),

            const SizedBox(height: 16),

            // What's included info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.teal.withOpacity(0.2)),
              ),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ℹ️', style: TextStyle(fontSize: 16)),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Backup এ সব লেনদেন + সব category (default ও নতুন) একসাথে সংরক্ষিত হয়। Restore করলে সবকিছু ফিরে আসবে।',
                  style: TextStyle(color: AppColors.teal, fontSize: 12, height: 1.5))),
              ]),
            ),

            const SizedBox(height: 24),

            // Backup button
            GestureDetector(
              onTap: _busy ? null : _backup,
              child: Container(
                width: double.infinity, height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.gradGold,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                alignment: Alignment.center,
                child: _busy
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('📤', style: TextStyle(fontSize: 22)),
                        SizedBox(width: 12),
                        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Backup করো', style: TextStyle(color: Color(0xFF0A0E1A), fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                          Text('লেনদেন + category সহ JSON file', style: TextStyle(color: Color(0xFF4A3000), fontSize: 11)),
                        ]),
                      ]),
              ),
            ),

            const SizedBox(height: 12),

            // Restore button
            GestureDetector(
              onTap: _busy ? null : _restore,
              child: Container(
                width: double.infinity, height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF141C2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.purple.withOpacity(0.4)),
                ),
                alignment: Alignment.center,
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('📥', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 12),
                  Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Restore করো', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                    Text('JSON file থেকে ডেটা ফিরিয়ে আনো', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ]),
                ]),
              ),
            ),

            // Status message
            if (_lastMsg != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _lastMsg!.startsWith('✅')
                      ? AppColors.teal.withOpacity(0.1)
                      : AppColors.rose.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _lastMsg!.startsWith('✅')
                        ? AppColors.teal.withOpacity(0.3)
                        : AppColors.rose.withOpacity(0.3)),
                ),
                child: Text(_lastMsg!,
                  style: TextStyle(
                    color: _lastMsg!.startsWith('✅') ? AppColors.teal : AppColors.rose,
                    fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
              ),
            ],

            const SizedBox(height: 24),

            // Warning
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.rose.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.rose.withOpacity(0.2)),
              ),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('⚠️', style: TextStyle(fontSize: 16)),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Restore করলে বর্তমান সব ডেটা মুছে যাবে। আগে Backup করে নাও।',
                  style: TextStyle(color: AppColors.rose, fontSize: 12, height: 1.5))),
              ]),
            ),

            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
      Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
    ]));
  }
}
