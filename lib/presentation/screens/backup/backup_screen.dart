// lib/presentation/screens/backup/backup_screen.dart
//
// Google Sign-In → permanent token refresh হয় নিজে থেকে
// Auto-backup: প্রতিদিন একবার app খুললে Drive এ upload

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../category/category_screen.dart';
import '../../../domain/models/transaction.dart';

// ── Google Sign-In instance ──────────────────────────────────────
final _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/drive.appdata',
  ],
);

// ── Drive REST helper ────────────────────────────────────────────
class _Drive {
  static const _file = 'financeflow_backup.json';
  static const _mime = 'application/json';

  static Future<String?> _token() async {
    try {
      final account = _googleSignIn.currentUser
          ?? await _googleSignIn.signInSilently();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.accessToken;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _findId(String token) async {
    try {
      final res = await http.get(
        Uri.parse(
          "https://www.googleapis.com/drive/v3/files"
          "?spaces=appDataFolder&q=name='$_file'&fields=files(id)",
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final files = (jsonDecode(res.body)['files'] as List);
        if (files.isNotEmpty) return files.first['id'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Upload (create or update)
  static Future<bool> upload(String content) async {
    final token = await _token();
    if (token == null) return false;
    try {
      final existing = await _findId(token);
      if (existing != null) {
        final res = await http.patch(
          Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files/$existing'
            '?uploadType=media',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': _mime,
          },
          body: content,
        );
        return res.statusCode == 200;
      } else {
        final boundary = 'ff_boundary';
        final meta = jsonEncode({
          'name': _file,
          'parents': ['appDataFolder'],
        });
        final body =
            '--$boundary\r\n'
            'Content-Type: application/json; charset=UTF-8\r\n\r\n'
            '$meta\r\n'
            '--$boundary\r\n'
            'Content-Type: $_mime\r\n\r\n'
            '$content\r\n'
            '--$boundary--';
        final res = await http.post(
          Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files'
            '?uploadType=multipart',
          ),
          headers: {
            'Authorization': 'Bearer $token',
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

  // Download latest backup
  static Future<String?> download() async {
    final token = await _token();
    if (token == null) return null;
    try {
      final id = await _findId(token);
      if (id == null) return null;
      final res = await http.get(
        Uri.parse(
          'https://www.googleapis.com/drive/v3/files/$id?alt=media',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      return res.statusCode == 200 ? res.body : null;
    } catch (_) {
      return null;
    }
  }
}

// ── Auto-backup (call from HomeShell.initState) ──────────────────
Future<void> runAutoBackupIfNeeded(WidgetRef ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString('last_auto_backup') == today) return;

    // Only if already signed in silently
    final account = await _googleSignIn.signInSilently();
    if (account == null) return;

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

    final ok = await _Drive.upload(payload);
    if (ok) await prefs.setString('last_auto_backup', today);
  } catch (_) {}
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
  GoogleSignInAccount? _account;
  String? _lastAutoBackup;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final account = await _googleSignIn.signInSilently();
    setState(() {
      _account = account;
      _lastAutoBackup = prefs.getString('last_auto_backup');
    });
  }

  // ── Sign in ──────────────────────────────────────────────────
  Future<void> _signIn() async {
    setState(() { _busy = true; _msg = null; });
    try {
      final account = await _googleSignIn.signIn();
      setState(() { _account = account; _busy = false; });
      if (account != null) {
        setState(() => _msg = '✅ ${account.email} দিয়ে সংযুক্ত হয়েছে!');
      }
    } catch (e) {
      setState(() { _busy = false; _msg = '❌ Login failed: $e'; });
    }
  }

  // ── Sign out ─────────────────────────────────────────────────
  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    setState(() { _account = null; _msg = 'Google Drive disconnected।'; });
  }

  // ── Build JSON payload ────────────────────────────────────────
  String _payload() {
    final txs  = ref.read(transactionsProvider)
        .maybeWhen(data: (t) => t, orElse: () => <Transaction>[]);
    final cats = ref.read(categoriesProvider);
    return jsonEncode({
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': txs.map((t) => t.toJson()).toList(),
      'categories': cats.map((c) => c.toJson()).toList(),
    });
  }

  // ── Drive backup ──────────────────────────────────────────────
  Future<void> _driveBackup() async {
    if (_account == null) { await _signIn(); return; }
    setState(() { _busy = true; _msg = null; });
    try {
      final ok = await _Drive.upload(_payload());
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now().toIso8601String().substring(0, 10);
        await prefs.setString('last_auto_backup', today);
        setState(() { _lastAutoBackup = today; _busy = false;
          _msg = '✅ Google Drive backup সফল!\nফোন হারালেও ডেটা নিরাপদ।'; });
      } else {
        setState(() { _busy = false;
          _msg = '❌ Upload failed। Internet আছে কিনা দেখো।'; });
      }
    } catch (e) {
      setState(() { _busy = false; _msg = '❌ Error: $e'; });
    }
  }

  // ── Drive restore ─────────────────────────────────────────────
  Future<void> _driveRestore() async {
    if (_account == null) { await _signIn(); return; }
    final ok = await _confirmDialog();
    if (ok != true) return;
    setState(() { _busy = true; _msg = null; });
    try {
      final content = await _Drive.download();
      if (content == null) {
        setState(() { _busy = false;
          _msg = '❌ Drive এ কোনো backup নেই। আগে backup করো।'; });
        return;
      }
      await _applyRestore(content);
    } catch (e) {
      setState(() { _busy = false; _msg = '❌ Error: $e'; });
    }
  }

  // ── Local backup ──────────────────────────────────────────────
  Future<void> _localBackup() async {
    setState(() { _busy = true; _msg = null; });
    try {
      final payload = _payload();
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fname =
          'financeflow_backup_'
          '${now.year}${now.month.toString().padLeft(2,'0')}'
          '${now.day.toString().padLeft(2,'0')}.json';
      final file = File('${dir.path}/$fname');
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

  // ── Local restore ─────────────────────────────────────────────
  Future<void> _localRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.isEmpty) return;
    final ok = await _confirmDialog();
    if (ok != true) return;
    setState(() { _busy = true; _msg = null; });
    try {
      final content = await File(result.files.first.path!).readAsString();
      await _applyRestore(content);
    } catch (e) {
      setState(() { _busy = false; _msg = '❌ Error: $e'; });
    }
  }

  // ── Apply restore ─────────────────────────────────────────────
  Future<void> _applyRestore(String content) async {
    final data    = jsonDecode(content) as Map<String, dynamic>;
    final version = (data['version'] as int?) ?? 1;
    final txs     = (data['transactions'] as List)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
    await ref.read(transactionsProvider.notifier).restoreAll(txs);

    int catCount = 0;
    if (version >= 2 && data.containsKey('categories')) {
      final cats = (data['categories'] as List)
          .map((e) => AppCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      await ref.read(categoriesProvider.notifier).restoreAll(cats);
      catCount = cats.length;
    }
    setState(() {
      _busy = false;
      _msg = '✅ Restore সফল! ${txs.length} লেনদেন'
          '${catCount > 0 ? " + $catCount category" : ""} ফিরে এসেছে।';
    });
  }

  Future<bool?> _confirmDialog() => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF141C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Restore করবে?',
        style: TextStyle(color: AppColors.textPrimary,
            fontFamily: 'Syne', fontWeight: FontWeight.w700)),
      content: const Text(
        'বর্তমান সব লেনদেন ও category মুছে যাবে এবং '
        'backup থেকে ফিরে আসবে।',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
          child: const Text('বাতিল',
              style: TextStyle(color: AppColors.textMuted))),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.rose, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('হ্যাঁ, Restore করো')),
      ]));

  // ── UI ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final txs  = ref.watch(transactionsProvider)
        .maybeWhen(data: (t) => t, orElse: () => <Transaction>[]);
    final cats = ref.watch(categoriesProvider);
    final totalIncome  = txs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = txs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text('Backup & Restore',
                style: TextStyle(color: AppColors.textPrimary,
                    fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
              const Text('তোমার ডেটা সুরক্ষিত রাখো',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 20),

              // ── Data summary ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141C2E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.06))),
                child: Column(children: [
                  const Text('বর্তমান ডেটা',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  Row(children: [
                    _Info(label: 'লেনদেন', value: '${txs.length} টি',   color: AppColors.gold),
                    _Info(label: 'Category', value: '${cats.length} টি', color: AppColors.purple),
                    _Info(label: 'আয়',  value: '৳${totalIncome.toStringAsFixed(0)}',  color: AppColors.teal),
                    _Info(label: 'খরচ', value: '৳${totalExpense.toStringAsFixed(0)}', color: AppColors.rose),
                  ]),
                ])),
              const SizedBox(height: 20),

              // ── Google Drive section ─────────────────────────
              const Row(children: [
                Text('☁️', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Google Drive Backup',
                  style: TextStyle(color: AppColors.textPrimary,
                      fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
              ]),
              const SizedBox(height: 10),

              // Account card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _account != null
                      ? AppColors.teal.withOpacity(0.08)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _account != null
                        ? AppColors.teal.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1))),
                child: Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: _account != null
                          ? AppColors.teal.withOpacity(0.15)
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(
                      _account != null ? '✅' : '👤',
                      style: const TextStyle(fontSize: 22)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _account != null
                            ? 'সংযুক্ত আছে'
                            : 'Google Account সংযুক্ত নেই',
                        style: TextStyle(
                          color: _account != null
                              ? AppColors.teal : AppColors.textPrimary,
                          fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(
                        _account != null
                            ? _account!.email
                            : 'নিচের বাটন চাপো',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                      if (_account != null && _lastAutoBackup != null)
                        Text('শেষ auto-backup: $_lastAutoBackup',
                          style: const TextStyle(
                              color: AppColors.teal, fontSize: 11)),
                    ])),
                  if (_account != null)
                    GestureDetector(
                      onTap: _signOut,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.rose.withOpacity(0.3))),
                        child: const Text('Sign Out',
                          style: TextStyle(color: AppColors.rose,
                              fontSize: 11, fontWeight: FontWeight.w700)))),
                ])),
              const SizedBox(height: 10),

              // Auto-backup info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.purple.withOpacity(0.2))),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔄', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'Auto-Backup চালু — একবার Google login করলেই '
                      'প্রতিদিন অ্যাপ খুললে নিজে থেকে Drive এ backup হবে। '
                      'ফোন হারালেও ডেটা নিরাপদ।',
                      style: TextStyle(color: AppColors.purple,
                          fontSize: 11, height: 1.6))),
                  ])),
              const SizedBox(height: 12),

              // Drive buttons
              if (_account == null)
                GestureDetector(
                  onTap: _busy ? null : _signIn,
                  child: Container(
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradGold,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color: AppColors.gold.withOpacity(0.35),
                        blurRadius: 16, offset: const Offset(0, 4))]),
                    alignment: Alignment.center,
                    child: _busy
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('🔑', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 10),
                            Text('Google দিয়ে Sign In করো',
                              style: TextStyle(color: Color(0xFF0A0E1A),
                                  fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                          ])))
              else
                Row(children: [
                  Expanded(child: _Btn(
                    icon: '☁️', label: 'Drive Backup',
                    sub: 'এখনই upload',
                    grad: AppColors.gradTeal, fg: Colors.white,
                    onTap: _busy ? null : _driveBackup)),
                  const SizedBox(width: 10),
                  Expanded(child: _Btn(
                    icon: '📥', label: 'Drive Restore',
                    sub: 'Drive থেকে আনো',
                    grad: null, fg: AppColors.textPrimary,
                    border: Border.all(color: AppColors.teal.withOpacity(0.35)),
                    onTap: _busy ? null : _driveRestore)),
                ]),

              const SizedBox(height: 24),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),

              // ── Local backup section ─────────────────────────
              const Row(children: [
                Text('📁', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('Local Backup',
                  style: TextStyle(color: AppColors.textPrimary,
                      fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teal.withOpacity(0.15))),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ℹ️', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'লেনদেন + category সহ JSON file তৈরি করে। '
                      'WhatsApp/Email এ share বা ফোনে save করতে পারবে।',
                      style: TextStyle(color: AppColors.teal,
                          fontSize: 11, height: 1.5))),
                  ])),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: _Btn(
                  icon: '📤', label: 'Local Backup', sub: 'JSON share',
                  grad: AppColors.gradGold, fg: const Color(0xFF0A0E1A),
                  onTap: _busy ? null : _localBackup)),
                const SizedBox(width: 10),
                Expanded(child: _Btn(
                  icon: '📂', label: 'Local Restore', sub: 'JSON file',
                  grad: null, fg: AppColors.textPrimary,
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  onTap: _busy ? null : _localRestore)),
              ]),

              // Loading
              if (_busy) ...[
                const SizedBox(height: 16),
                const Center(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.gold, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('কাজ চলছে...',
                      style: TextStyle(color: AppColors.gold, fontSize: 13)),
                  ])),
              ],

              // Status message
              if (_msg != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _msg!.startsWith('✅')
                        ? AppColors.teal.withOpacity(0.1)
                        : AppColors.rose.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _msg!.startsWith('✅')
                          ? AppColors.teal.withOpacity(0.3)
                          : AppColors.rose.withOpacity(0.3))),
                  child: Text(_msg!,
                    style: TextStyle(
                      color: _msg!.startsWith('✅')
                          ? AppColors.teal : AppColors.rose,
                      fontSize: 13, fontWeight: FontWeight.w600, height: 1.4))),
              ],

              const SizedBox(height: 20),

              // Warning
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.rose.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.rose.withOpacity(0.2))),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'Restore করলে বর্তমান সব ডেটা মুছে যাবে। '
                      'আগে Backup করে নাও।',
                      style: TextStyle(color: AppColors.rose,
                          fontSize: 12, height: 1.5))),
                  ])),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String icon, label, sub;
  final Gradient? grad;
  final Color fg;
  final Border? border;
  final VoidCallback? onTap;
  const _Btn({required this.icon, required this.label, required this.sub,
    required this.grad, required this.fg, required this.onTap, this.border});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: grad,
        color: grad == null ? const Color(0xFF141C2E) : null,
        borderRadius: BorderRadius.circular(14),
        border: border),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Column(mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: fg, fontSize: 13,
                fontWeight: FontWeight.w800, fontFamily: 'Syne')),
            Text(sub, style: TextStyle(
                color: fg.withOpacity(0.6), fontSize: 10)),
          ]),
      ])));
}

class _Info extends StatelessWidget {
  final String label, value; final Color color;
  const _Info({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 13,
        fontWeight: FontWeight.w800, fontFamily: 'Syne')),
    Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
  ]));
}
