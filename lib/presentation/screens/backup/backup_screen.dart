import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/transaction.dart';

// ── Backup Provider ─────────────────────────────────────────
enum BackupStatus { idle, loading, success, error }

class BackupState {
  final BackupStatus status;
  final String? message;
  final String? lastBackupDate;
  final int recordCount;

  const BackupState({
    this.status = BackupStatus.idle,
    this.message,
    this.lastBackupDate,
    this.recordCount = 0,
  });

  BackupState copyWith({
    BackupStatus? status,
    String? message,
    String? lastBackupDate,
    int? recordCount,
  }) =>
      BackupState(
        status: status ?? this.status,
        message: message ?? this.message,
        lastBackupDate: lastBackupDate ?? this.lastBackupDate,
        recordCount: recordCount ?? this.recordCount,
      );
}

class BackupNotifier extends StateNotifier<BackupState> {
  BackupNotifier() : super(const BackupState()) {
    _loadLastBackupInfo();
  }

  Future<void> _loadLastBackupInfo() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file =
          File('${dir.path}/financeflow_backup.json');
      if (await file.exists()) {
        final stat = await file.stat();
        final m = stat.modified;
        state = state.copyWith(
          lastBackupDate:
              '${m.day}/${m.month}/${m.year} · ${m.hour}:${m.minute.toString().padLeft(2, '0')}',
        );
      }
    } catch (_) {}
  }

  // ── Backup ──────────────────────────────────────────────
  Future<void> backup(List<Transaction> transactions) async {
    state = state.copyWith(
        status: BackupStatus.loading,
        message: 'Backup তৈরি হচ্ছে...');
    try {
      final data = {
        'version': 1,
        'backup_date': DateTime.now().toIso8601String(),
        'app': 'FinanceFlow',
        'transaction_count': transactions.length,
        'transactions':
            transactions.map((t) => t.toJson()).toList(),
      };
      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(data);

      // App documents folder এ save
      final dir = await getApplicationDocumentsDirectory();
      final appFile =
          File('${dir.path}/financeflow_backup.json');
      await appFile.writeAsString(jsonStr);

      // Downloads/FinanceFlow/ এ save
      String? savedPath;
      try {
        final downloads = Directory(
            '/storage/emulated/0/Download/FinanceFlow');
        if (!await downloads.exists()) {
          await downloads.create(recursive: true);
        }
        final now = DateTime.now();
        final fileName =
            'financeflow_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute.toString().padLeft(2, '0')}.json';
        final dlFile =
            File('${downloads.path}/$fileName');
        await dlFile.writeAsString(jsonStr);
        savedPath = dlFile.path;
      } catch (_) {}

      final now = DateTime.now();
      state = state.copyWith(
        status: BackupStatus.success,
        message: savedPath != null
            ? '${transactions.length} টি লেনদেন backup হয়েছে!\n📁 Download/FinanceFlow/ তে save হয়েছে'
            : '${transactions.length} টি লেনদেন backup হয়েছে!',
        lastBackupDate:
            '${now.day}/${now.month}/${now.year} · ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        recordCount: transactions.length,
      );
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        message: 'Backup ব্যর্থ: $e',
      );
    }
  }

  // ── Share ────────────────────────────────────────────────
  Future<void> shareBackup(
      List<Transaction> transactions) async {
    state = state.copyWith(
        status: BackupStatus.loading,
        message: 'Share এর জন্য তৈরি হচ্ছে...');
    try {
      final data = {
        'version': 1,
        'backup_date': DateTime.now().toIso8601String(),
        'app': 'FinanceFlow',
        'transaction_count': transactions.length,
        'transactions':
            transactions.map((t) => t.toJson()).toList(),
      };
      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName =
          'financeflow_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'FinanceFlow Backup — $fileName',
        text:
            'FinanceFlow এর ${transactions.length} টি লেনদেনের backup।',
      );

      state =
          state.copyWith(status: BackupStatus.idle);
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        message: 'Share ব্যর্থ: $e',
      );
    }
  }

  // ── Restore ──────────────────────────────────────────────
  Future<List<Transaction>?> pickAndRestore() async {
    state = state.copyWith(
        status: BackupStatus.loading,
        message: 'File খোঁজা হচ্ছে...');
    try {
      // সব ধরনের ফাইল দেখাবে — JSON filter সরিয়ে দিলাম
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // ফাইলের data directly পড়বে
      );

      if (result == null || result.files.isEmpty) {
        state =
            state.copyWith(status: BackupStatus.idle);
        return null;
      }

      final pickedFile = result.files.single;
      String jsonStr;

      // Data directly পাওয়া গেলে সেটা ব্যবহার করো
      if (pickedFile.bytes != null) {
        jsonStr = utf8.decode(pickedFile.bytes!);
      } else if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        jsonStr = await file.readAsString();
      } else {
        state = state.copyWith(
          status: BackupStatus.error,
          message: 'ফাইল পড়া যাচ্ছে না',
        );
        return null;
      }

      // JSON parse করো
      final data =
          jsonDecode(jsonStr) as Map<String, dynamic>;

      // FinanceFlow backup কিনা চেক করো
      if (data['app'] != 'FinanceFlow') {
        state = state.copyWith(
          status: BackupStatus.error,
          message: '❌ এটা FinanceFlow এর backup ফাইল না!',
        );
        return null;
      }

      final rawList =
          data['transactions'] as List<dynamic>;
      final transactions = rawList
          .map((e) => Transaction.fromJson(
              e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        status: BackupStatus.success,
        message:
            '✅ ${transactions.length} টি লেনদেন restore হয়েছে!',
        recordCount: transactions.length,
      );

      return transactions;
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        message: 'Restore ব্যর্থ: $e\n\nFile টি FinanceFlow backup কিনা নিশ্চিত করো',
      );
      return null;
    }
  }

  void reset() =>
      state = state.copyWith(status: BackupStatus.idle);
}

final backupProvider =
    StateNotifierProvider<BackupNotifier, BackupState>(
        (ref) => BackupNotifier());

// ═══════════════════════════════════════════════════════════
// BACKUP SCREEN
// ═══════════════════════════════════════════════════════════
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupProvider);
    final notifier = ref.read(backupProvider.notifier);
    final transactions = ref.watch(transactionsProvider).maybeWhen(
      data: (t) => t,
      orElse: () => <Transaction>[],
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ──
              const Text('Backup & Restore',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Syne',
                )),
              const SizedBox(height: 4),
              const Text('তোমার হিসাব নিরাপদে সংরক্ষণ করো',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),

              const SizedBox(height: 24),

              // ── Info Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF0D1B3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.2)),
                ),
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.gold.withOpacity(0.3)),
                      ),
                      child: const Center(
                          child: Text('📦',
                              style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Local Backup',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Syne',
                          )),
                        Text('${transactions.length} টি লেনদেন ready',
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.teal.withOpacity(0.3)),
                      ),
                      child: const Text('Active',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        )),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),
                  _StatRow(icon: '🕐', label: 'Last Backup',
                    value: backupState.lastBackupDate ?? 'কোনো backup নেই'),
                  const SizedBox(height: 8),
                  _StatRow(icon: '📊', label: 'Records',
                    value: '${transactions.length} টি লেনদেন'),
                  const SizedBox(height: 8),
                  const _StatRow(icon: '📁', label: 'Save Location',
                    value: 'Download/FinanceFlow/'),
                ]),
              ),

              const SizedBox(height: 16),

              // ── How to Restore Guide ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.purple.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Text('🔄', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('Restore কীভাবে করবে?',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                    ]),
                    const SizedBox(height: 10),
                    ...[
                      '১. আগে "Backup Now" দিয়ে backup নাও',
                      '২. অথবা "Share" দিয়ে WhatsApp এ নিজেকে পাঠাও',
                      '৩. Uninstall → Reinstall করার পর',
                      '৪. "Restore from File" চাপো',
                      '৫. WhatsApp থেকে file save করে সেটা বেছে দাও',
                      '৬. সব পুরানো হিসাব ফিরে আসবে ✅',
                    ].map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(s,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              height: 1.4,
                            )),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Status Banner ──
              if (backupState.status == BackupStatus.loading) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.gold, strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text(backupState.message ?? 'Processing...',
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              if (backupState.status == BackupStatus.success &&
                  backupState.message != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.teal.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Text('✅', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(backupState.message!,
                      style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              if (backupState.status == BackupStatus.error &&
                  backupState.message != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.rose.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const Text('❌', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(backupState.message!,
                      style: const TextStyle(
                          color: AppColors.rose,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              // ── Buttons ──
              if (backupState.status != BackupStatus.loading) ...[

                // Backup Now
                _ActionButton(
                  icon: '📥',
                  label: 'Backup Now',
                  subtitle: 'Download/FinanceFlow/ তে save করো',
                  gradient: AppColors.gradGold,
                  textColor: const Color(0xFF0A0E1A),
                  onTap: () => notifier.backup(transactions),
                ),

                const SizedBox(height: 10),

                // Share
                _ActionButton(
                  icon: '📤',
                  label: 'Share Backup',
                  subtitle: 'WhatsApp / Gmail এ পাঠাও',
                  gradient: AppColors.gradTeal,
                  textColor: Colors.white,
                  onTap: () =>
                      notifier.shareBackup(transactions),
                ),

                const SizedBox(height: 10),

                // Restore
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF141C2E),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20)),
                        title: const Text('⚠️ Restore করবে?',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                          )),
                        content: const Text(
                          'বর্তমান সব data মুছে যাবে এবং backup ফাইলের পুরানো data ফিরে আসবে।\n\nনিশ্চিত?',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              height: 1.5)),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('বাতিল',
                              style: TextStyle(
                                  color: AppColors.textMuted)),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.rose,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                            child: const Text('Restore করো'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    final txs =
                        await notifier.pickAndRestore();
                    if (txs != null) {
                      await ref
                          .read(transactionsProvider.notifier)
                          .restoreAll(txs);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              AppColors.purple.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color:
                              AppColors.purple.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                        child: const Center(
                            child: Text('🔄',
                                style:
                                    TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('Restore from File',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Syne',
                              )),
                            Text('যেকোনো ফোল্ডার থেকে JSON ফাইল বেছে নাও',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              )),
                          ],
                        ),
                      ),
                      Icon(Icons.folder_open_rounded,
                        color: AppColors.purple.withOpacity(0.7),
                        size: 20),
                    ]),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Security Note ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.06),
                  border: Border.all(
                      color: AppColors.teal.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ফোন Format বা App Uninstall করার আগে "Share Backup" দিয়ে WhatsApp এ নিজেকে পাঠাও। পরে reinstall করে WhatsApp থেকে ফাইলটা ডাউনলোড করে Restore দিলেই সব হিসাব ফিরে আসবে।',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
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

// ── Helper Widgets ──────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String icon, label, value;
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Text(label,
        style: const TextStyle(
            color: AppColors.textMuted, fontSize: 12)),
      const Spacer(),
      Text(value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        )),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final String icon, label, subtitle;
  final Gradient gradient;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
                child: Text(icon,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Syne',
                )),
              Text(subtitle,
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 12,
                )),
            ],
          )),
          Icon(Icons.arrow_forward_ios_rounded,
            color: textColor.withOpacity(0.6), size: 16),
        ]),
      ),
    );
  }
}
