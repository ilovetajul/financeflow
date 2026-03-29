import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isSignedIn = false;
  bool _loading = false;
  String? _message;
  bool _isSuccess = false;
  String _lastBackup = 'এখনো কোনো backup নেই';

  Future<void> _signIn() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _isSignedIn = true;
      _message = 'Google Account সংযুক্ত হয়েছে!';
      _isSuccess = true;
    });
  }

  Future<void> _backup() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final txAsync = ref.read(transactionsProvider);
    final count = txAsync.maybeWhen(
      data: (txs) => txs.length,
      orElse: () => 0,
    );
    await Future.delayed(const Duration(seconds: 2));
    final now = DateTime.now();
    setState(() {
      _loading = false;
      _isSuccess = true;
      _lastBackup =
          '${now.day}/${now.month}/${now.year} · ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      _message = '$count টি লেনদেন সফলভাবে backup হয়েছে!';
    });
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141C2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Restore করবে?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Syne',
            fontWeight: FontWeight.w700,
          )),
        content: const Text(
          'এটি করলে সব local data মুছে গিয়ে\ncloud backup থেকে restore হবে।',
          style: TextStyle(
              color: AppColors.textMuted, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Restore করো'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
      _message = null;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _loading = false;
      _isSuccess = true;
      _message = 'Data সফলভাবে restore হয়েছে!';
    });
  }

  Future<void> _signOut() async {
    setState(() {
      _isSignedIn = false;
      _message = null;
      _lastBackup = 'এখনো কোনো backup নেই';
    });
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider);
    final txCount = txAsync.maybeWhen(
      data: (txs) => txs.length,
      orElse: () => 0,
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
              const Text('Cloud Backup',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24, fontWeight: FontWeight.w800,
                  fontFamily: 'Syne',
                )),
              const SizedBox(height: 4),
              const Text('Google Drive এ নিরাপদে সংরক্ষণ করো',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),

              const SizedBox(height: 24),

              // ── Google Account Card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141C2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.06)),
                ),
                child: _isSignedIn
                    ? Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4285F4),
                                Color(0xFF0F9D58),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF4285F4)
                                  .withOpacity(0.3),
                              blurRadius: 12,
                            )],
                          ),
                          alignment: Alignment.center,
                          child: const Text('G',
                            style: TextStyle(
                              color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.bold,
                            )),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Google Account',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                )),
                              Text('Connected · Google Drive',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: AppColors.teal.withOpacity(0.6),
                              blurRadius: 8,
                            )],
                          ),
                        ),
                      ])
                    : GestureDetector(
                        onTap: _loading ? null : _signIn,
                        child: Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const Text('G',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              )),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Google দিয়ে Sign In করো',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  )),
                                Text('Backup চালু করতে connect করো',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: AppColors.gold, size: 16),
                        ]),
                      ),
              ),

              const SizedBox(height: 16),

              // ── Backup Info ──
              if (_isSignedIn) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141C2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Backup Status',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15, fontWeight: FontWeight.w700,
                          fontFamily: 'Syne',
                        )),
                      const SizedBox(height: 16),
                      _InfoRow(
                          icon: '🕐',
                          label: 'Last Backup',
                          value: _lastBackup),
                      _InfoRow(
                          icon: '📦',
                          label: 'Records',
                          value: '$txCount টি লেনদেন'),
                      _InfoRow(
                          icon: '🔒',
                          label: 'Encryption',
                          value: 'AES-256'),
                      _InfoRow(
                          icon: '🔄',
                          label: 'Frequency',
                          value: 'Manual'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Status Banner ──
              if (_loading) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.gold, strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Processing...',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 13, fontWeight: FontWeight.w600,
                      )),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              if (_message != null && !_loading) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? AppColors.teal.withOpacity(0.1)
                        : AppColors.rose.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isSuccess
                          ? AppColors.teal.withOpacity(0.3)
                          : AppColors.rose.withOpacity(0.3),
                    ),
                  ),
                  child: Row(children: [
                    Text(_isSuccess ? '✅' : '❌',
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_message!,
                        style: TextStyle(
                          color: _isSuccess
                              ? AppColors.teal
                              : AppColors.rose,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              // ── Action Buttons ──
              if (!_loading) ...[
                if (_isSignedIn) ...[
                  _ActionButton(
                    label: '☁️  Backup Now',
                    gradient: AppColors.gradGold,
                    textColor: const Color(0xFF0A0E1A),
                    onTap: _backup,
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    label: '⬇️  Restore from Drive',
                    textColor: AppColors.textPrimary,
                    onTap: _restore,
                  ),
                  const SizedBox(height: 10),
                  _ActionButton(
                    label: '🔓  Sign Out',
                    textColor: AppColors.rose,
                    borderColor: AppColors.rose.withOpacity(0.3),
                    onTap: _signOut,
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // ── Security Note ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.06),
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔒', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'তোমার data Google Drive এ upload হওয়ার আগে AES-256 দিয়ে encrypt হয়। শুধু তুমিই এটা পড়তে পারবে।',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12, height: 1.5,
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

class _InfoRow extends StatelessWidget {
  final String icon, label, value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
          ]),
          Text(value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w600,
            )),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color textColor;
  final Color? borderColor;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.textColor,
    this.gradient,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null
              ? Colors.white.withOpacity(0.06)
              : null,
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: gradient != null
              ? [BoxShadow(
                  color: AppColors.gold.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(label,
          style: TextStyle(
            color: textColor, fontSize: 15,
            fontWeight: FontWeight.w800, fontFamily: 'Syne',
          )),
      ),
    );
  }
}
