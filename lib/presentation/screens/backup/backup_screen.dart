// lib/presentation/screens/backup/backup_screen.dart
//
// Google Drive backup strategy:
//   • Uses Google Sign-In + Drive REST API (upload/download)
//   • Auto-backup runs once per day on app start
//   • Manual backup available anytime
//   • Stores backup file in Drive's appDataFolder (hidden, app-specific)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../category/category_screen.dart';
import '../../../domain/models/transaction.dart';

// ── Google Drive helper ────────────────────────────────────────────
// Uses Drive REST API with an access token
// The token is obtained via google_sign_in package (add to pubspec)
class DriveHelper {
  static const _fileName = 'financeflow_backup.json';
  static const _mimeType = 'application/json';

  // Upload (create or update) file to appDataFolder
  static Future<bool> upload(String accessToken, String jsonContent) async {
    try {
      // Check if file already exists
      final existingId = await _findFileId(accessToken);

      if (existingId != null) {
        // Update existing file
        final res = await http.patch(
          Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$existingId?uploadType=media'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': _mimeType,
          },
          body: jsonContent,
        );
        return res.statusCode == 200;
      } else {
        // Create new file in appDataFolder
        final metadata = jsonEncode({
          'name': _fileName,
          'parents': ['appDataFolder'],
        });
        final boundary = 'boundary_financeflow';
        final body =
            '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
            '$metadata\r\n--$boundary\r\nContent-Type: $_mimeType\r\n\r\n'
            '$jsonContent\r\n--$boundary--';

        final res = await http.post(
          Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: body,
        );
        return res.statusCode == 200;
      }
    } catch (_) {
      return false;
    }
  }

  // Download latest backup from Drive
  static Future<String?> download(String accessToken) async {
    try {
      final fileId = await _findFileId(accessToken);
      if (fileId == null) return null;
      final res = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (res.statusCode == 200) return res.body;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _findFileId(String accessToken) async {
    try {
      final res = await http.get(
        Uri.parse(
            "https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=name='$_fileName'&fields=files(id)"),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final files = data['files'] as List<dynamic>;
        if (files.isNotEmpty) return (files.first as Map)['id'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

// ── Auto-backup provider ───────────────────────────────────────────
// Call this once from main.dart or HomeShell initState
Future<void> runAutoBackupIfNeeded(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final lastBackup = prefs.getString('last_auto_backup');
  final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
  if (lastBackup == today) return; // already backed up today

  final token = prefs.getString('drive_access_token');
  if (token == null || token.isEmpty) return; // not signed in

  final txs = ref.read(transactionsProvider).maybeWhen(
    data: (t) => t, orElse: () => <Transaction>[]);
  final cats = ref.read(categoriesProvider);

  final payload = jsonEncode({
    'version': 2,
    'exportedAt': DateTime.now().toIso8601String(),
    'autoBackup': true,
    'transactions': txs.map((t) => t.toJson()).toList(),
    'categories': cats.map((c) => c.toJson()).toList(),
  });

  final ok = await DriveHelper.upload(token, payload);
  if (ok) {
    await prefs.setString('last_auto_backup', today);
  }
}

// ═══════════════════════════════════════════════════════════════════
// BACKUP SCREEN
// ═══════════════════════════════════════════════════════════════════
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String? _msg;
  bool _driveSignedIn = false;
  String? _driveToken;
  String? _lastAutoBackup;
  String? _driveEmail;

  @override
  void initState() {
    super.initState();
    _loadDriveState();
  }

  Future<void> _loadDriveState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _driveToken    = prefs.getString('drive_access_token');
      _driveEmail    = prefs.getString('drive_email');
      _driveSignedIn = _driveToken != null && _driveToken!.isNotEmpty;
      _lastAutoBackup = prefs.getString('last_auto_backup');
    });
  }

  // ── Build JSON payload ──────────────────────────────────────────
  String _buildPayload() {
    final txs  = ref.read(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <Transaction>[]);
    final cats = ref.read(categoriesProvider);
    return jsonEncode({
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': txs.map((t) => t.toJson()).toList(),
      'categories': cats.map((c) => c.toJson()).toList(),
    });
  }

  // ── Local backup ────────────────────────────────────────────────
  Future<void> _localBackup() async {
    setState(() { _busy = true; _msg = null; });
    try {
      final payload = _buildPayload();
      final dir     = await getApplicationDocumentsDirectory();
      final ts      = DateTime.now();
      final fname   = 'financeflow_backup_${ts.year}${ts.month.toString().padLeft(2,'0')}${ts.day.toString().padLeft(2,'0')}.json';
      final file    = File('${dir.path}/$fname');
      await file.writeAsString(payload);
      try {
        final dl = Directory('/storage/emulated/0/Download/FinanceFlow');
        if (!await dl.exists()) await dl.create(recursive: true);
        await File('${dl.path}/$fname').writeAsString(payload);
      } catch (_) {}
      await Share.shareXFiles([XFile(file.path)], subject: 'FinanceFlow Backup');
      setState(() { _busy = false; _msg = '✅ Local backup সফল!'; });
    } catch (e) {
      setState(() { _busy = false; _msg = '❌ Error: $e'; });
    }
  }

  // ── Drive backup ────────────────────────────────────────────────
  Future<void> _driveBackup() async {
    if (!_driveSignedIn || _driveToken == null) {
      _showTokenDialog();
      return;
    }
    setState(() { _busy = true; _msg = null; });
    try {
      final payload = _buildPayload();
      final ok = await DriveHelper.upload(_driveToken!, payload);
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now().toIso8601String().substring(0, 10);
        await prefs.setString('last_auto_backup', today);
        setState(() { _busy = false; _lastAutoBackup = today; _msg = '✅ Google Drive backup সফল!'; });
      } else {
        setState(() { _busy = false; _msg = '❌ Drive upload failed. Token expired হয়ে থাকতে পারে।'; });
      }
    } catch (e) {
      setState(() { _busy = false; _msg = '❌ Error: $e'; });
    }
  }

  // ── Drive restore ───────────────────────────────────────────────
  Future<void> _driveRestore() async {
    if (!_driveSignedIn || _driveToken == null) {
      _showTokenDialog();
      return;
    }
    final confirmed = await _confirmRestoreDialog();
    if (confirmed != true) return;

    setState(() { _busy = true; _msg = null; });
    try {
      final content = await DriveHelper.download(_driveToken!);
      if (content == null) {
        setState(() { _busy = false; _msg = '❌ Drive এ কোনো backup পাওয়া যায়নি।'; });
        return;
      }
      await _applyRestore(content);
    } catch (e) {
      setState(() { _busy = false; _msg = '❌ Error: $e'; });
    }
  }

  // ── Local restore ───────────────────────────────────────────────
  Future<void> _localRestore() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.isEmpty) return;
    final confirmed = await _confirmRestoreDialog();
    if (confirmed != true) return;
    setState(() { _busy = true; _msg = null; });
    try {
      final content = await File(result.files.first.path!).readAsString();
      await _applyRestore(content);
    } catch (e) {
      setState(() { _busy = false; _msg = '❌ Error: $e'; });
    }
  }

  Future<void> _applyRestore(String content) async {
    final data    = jsonDecode(content) as Map<String, dynamic>;
    final version = data['version'] as int? ?? 1;
    final txList  = data['transactions'] as List<dynamic>;
    final txs     = txList.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    await ref.read(transactionsProvider.notifier).restoreAll(txs);

    int catCount = 0;
    if (version >= 2 && data.containsKey('categories')) {
      final catList = data['categories'] as List<dynamic>;
      final cats = catList.map((e) => AppCategory.fromJson(e as Map<String, dynamic>)).toList();
      await ref.read(categoriesProvider.notifier).restoreAll(cats);
      catCount = cats.length;
    }
    setState(() {
      _busy = false;
      _msg = '✅ Restore সফল! ${txs.length} লেনদেন${catCount > 0 ? " + $catCount category" : ""} ফিরে এসেছে।';
    });
  }

  // ── Token input dialog (one-time setup) ────────────────────────
  void _showTokenDialog() {
    final ctrl = TextEditingController(text: _driveToken ?? '');
    final emailCtrl = TextEditingController(text: _driveEmail ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Google Drive Setup',
            style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.gold.withOpacity(0.2))),
            child: const Text(
              '১. myaccount.google.com/u/0/security এ যাও\n'
              '২. "Apps with access to your account" এ যাও\n'
              '৩. অথবা OAuth Playground ব্যবহার করো:\n'
              '   developers.google.com/oauthplayground\n'
              '   Scope: drive.appdata\n'
              '   Access token copy করো',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.6))),
          const SizedBox(height: 16),
          TextField(controller: emailCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Gmail (শুধু দেখানোর জন্য)', hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.teal, size: 18),
              filled: true, fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
          const SizedBox(height: 10),
          TextField(controller: ctrl,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Google Drive Access Token paste করো', hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
              filled: true, fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
              contentPadding: const EdgeInsets.all(12))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল', style: TextStyle(color: AppColors.textMuted))),
          if (_driveSignedIn)
            TextButton(onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('drive_access_token');
              await prefs.remove('drive_email');
              setState(() { _driveSignedIn = false; _driveToken = null; _driveEmail = null; });
              if (mounted) Navigator.pop(context);
            }, child: const Text('Sign Out', style: TextStyle(color: AppColors.rose))),
          ElevatedButton(
            onPressed: () async {
              final token = ctrl.text.trim();
              if (token.isEmpty) return;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('drive_access_token', token);
              await prefs.setString('drive_email', emailCtrl.text.trim());
              setState(() { _driveToken = token; _driveEmail = emailCtrl.text.trim(); _driveSignedIn = true; });
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: const Color(0xFF0A0E1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Future<bool?> _confirmRestoreDialog() => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF141C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Restore করবে?',
          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700)),
      content: const Text('বর্তমান সব লেনদেন ও category মুছে যাবে এবং backup থেকে ফিরে আসবে।',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
          child: const Text('বাতিল', style: TextStyle(color: AppColors.textMuted))),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('হ্যাঁ, Restore করো')),
      ]));

  @override
  Widget build(BuildContext context) {
    final txs  = ref.watch(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <Transaction>[]);
    final cats = ref.watch(categoriesProvider);
    final totalIncome  = txs.where((t) => t.type == TransactionType.income).fold(0.0,  (s, t) => s + t.amount);
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
            const SizedBox(height: 20),

            // Data summary card
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF141C2E), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.06))),
              child: Column(children: [
                const Text('বর্তমান ডেটা', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
                const SizedBox(height: 12), const Divider(color: Colors.white12), const SizedBox(height: 12),
                Row(children: [
                  _Info(label: 'লেনদেন', value: '${txs.length} টি',       color: AppColors.gold),
                  _Info(label: 'Category', value: '${cats.length} টি',    color: AppColors.purple),
                  _Info(label: 'আয়',      value: '৳${totalIncome.toStringAsFixed(0)}',  color: AppColors.teal),
                  _Info(label: 'খরচ',     value: '৳${totalExpense.toStringAsFixed(0)}', color: AppColors.rose),
                ]),
              ])),
            const SizedBox(height: 20),

            // ── Google Drive section ────────────────────────────
            Row(children: [
              const Text('☁️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('Google Drive (অটো-Backup)',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
            ]),
            const SizedBox(height: 8),

            // Drive status
            GestureDetector(
              onTap: _showTokenDialog,
              child: Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _driveSignedIn ? AppColors.teal.withOpacity(0.08) : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _driveSignedIn ? AppColors.teal.withOpacity(0.3) : Colors.white.withOpacity(0.1))),
                child: Row(children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _driveSignedIn ? AppColors.teal.withOpacity(0.15) : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(_driveSignedIn ? '✅' : '🔗', style: const TextStyle(fontSize: 20)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_driveSignedIn ? 'Google Drive সংযুক্ত' : 'Google Drive সংযুক্ত নেই',
                        style: TextStyle(color: _driveSignedIn ? AppColors.teal : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(_driveSignedIn
                        ? (_driveEmail?.isNotEmpty == true ? _driveEmail! : 'Token সেট আছে')
                        : 'ট্যাপ করে token দাও',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    if (_lastAutoBackup != null && _driveSignedIn)
                      Text('শেষ auto-backup: $_lastAutoBackup',
                          style: const TextStyle(color: AppColors.teal, fontSize: 11)),
                  ])),
                  Icon(Icons.settings_rounded, color: AppColors.textDim.withOpacity(0.5), size: 18),
                ])),
            ),
            const SizedBox(height: 10),

            // Auto-backup info
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.purple.withOpacity(0.2))),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🔄', style: TextStyle(fontSize: 14)), SizedBox(width: 8),
                Expanded(child: Text(
                  'Auto-Backup: প্রতিদিন একবার অ্যাপ খুললে Google Drive এ নিজে থেকেই backup হবে। ফোন হারিয়ে গেলেও Drive থেকে restore করতে পারবে।',
                  style: TextStyle(color: AppColors.purple, fontSize: 11, height: 1.5))),
              ])),
            const SizedBox(height: 12),

            // Drive buttons
            Row(children: [
              Expanded(child: _ActionBtn(
                icon: '☁️', label: 'Drive Backup', sublabel: 'এখনই upload করো',
                gradient: AppColors.gradTeal, textColor: Colors.white,
                onTap: _busy ? null : _driveBackup)),
              const SizedBox(width: 10),
              Expanded(child: _ActionBtn(
                icon: '📥', label: 'Drive Restore', sublabel: 'Drive থেকে আনো',
                gradient: null, textColor: AppColors.textPrimary,
                border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                onTap: _busy ? null : _driveRestore)),
            ]),

            const SizedBox(height: 24),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),

            // ── Local backup section ────────────────────────────
            Row(children: [
              const Text('📁', style: TextStyle(fontSize: 20)), const SizedBox(width: 8),
              const Text('Local Backup',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
            ]),
            const SizedBox(height: 8),

            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.teal.withOpacity(0.15))),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ℹ️', style: TextStyle(fontSize: 14)), SizedBox(width: 8),
                Expanded(child: Text(
                  'লেনদেন + category সহ JSON file তৈরি করে। WhatsApp/Email এ share করতে পারবে।',
                  style: TextStyle(color: AppColors.teal, fontSize: 11, height: 1.5))),
              ])),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: _ActionBtn(
                icon: '📤', label: 'Local Backup', sublabel: 'JSON file share',
                gradient: AppColors.gradGold, textColor: const Color(0xFF0A0E1A),
                onTap: _busy ? null : _localBackup)),
              const SizedBox(width: 10),
              Expanded(child: _ActionBtn(
                icon: '📂', label: 'Local Restore', sublabel: 'JSON file থেকে',
                gradient: null, textColor: AppColors.textPrimary,
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                onTap: _busy ? null : _localRestore)),
            ]),

            // Loading
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)),
                SizedBox(width: 12),
                Text('কাজ চলছে...', style: TextStyle(color: AppColors.gold, fontSize: 13)),
              ])),
            ],

            // Status message
            if (_msg != null) ...[
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _msg!.startsWith('✅') ? AppColors.teal.withOpacity(0.1) : AppColors.rose.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _msg!.startsWith('✅') ? AppColors.teal.withOpacity(0.3) : AppColors.rose.withOpacity(0.3))),
                child: Text(_msg!,
                    style: TextStyle(color: _msg!.startsWith('✅') ? AppColors.teal : AppColors.rose, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4))),
            ],

            const SizedBox(height: 20),

            // Warning
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.rose.withOpacity(0.2))),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('⚠️', style: TextStyle(fontSize: 16)), SizedBox(width: 10),
                Expanded(child: Text('Restore করলে বর্তমান সব ডেটা মুছে যাবে। আগে Backup করে নাও।',
                    style: TextStyle(color: AppColors.rose, fontSize: 12, height: 1.5))),
              ])),

            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String icon, label, sublabel;
  final Gradient? gradient;
  final Color textColor;
  final Border? border;
  final VoidCallback? onTap;
  const _ActionBtn({required this.icon, required this.label, required this.sublabel, required this.gradient, required this.textColor, required this.onTap, this.border});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(height: 64,
      decoration: BoxDecoration(gradient: gradient, color: gradient == null ? const Color(0xFF141C2E) : null,
        borderRadius: BorderRadius.circular(14), border: border),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(width: 8),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
          Text(sublabel, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 10)),
        ]),
      ])));
}

class _Info extends StatelessWidget {
  final String label, value; final Color color;
  const _Info({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
    Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
  ]));
}
