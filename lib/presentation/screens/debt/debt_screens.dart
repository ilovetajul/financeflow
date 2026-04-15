// lib/presentation/screens/debt/debt_screens.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../app/theme.dart';
import '../../providers/debt_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/debt_model.dart';
import '../../../domain/models/transaction.dart';

// ══════════════════════════════════════════════════════════════════
// 1.  DEBT MANAGEMENT SCREEN  (person list)
// ══════════════════════════════════════════════════════════════════
class DebtManagementScreen extends ConsumerWidget {
  const DebtManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persons  = ref.watch(debtPersonsProvider);
    final totalNet = ref.watch(totalOwedToMeProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'দেনা-পাওনা',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Syne',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPersonDialog(context, ref),
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.person_add_rounded, color: Color(0xFF0A0E1A)),
      ),
      body: Column(
        children: [
          // ── Summary card ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF0D1B3E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'সার্বিক হিসাব',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalNet > 0
                              ? 'তোমার পাওনা আছে'
                              : totalNet < 0
                                  ? 'তোমার দেনা আছে'
                                  : 'হিসাব সমান',
                          style: TextStyle(
                            color: totalNet >= 0 ? AppColors.teal : AppColors.rose,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '৳${totalNet.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            color: totalNet >= 0 ? AppColors.teal : AppColors.rose,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Syne',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('🤝', style: TextStyle(fontSize: 28)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Person list ───────────────────────────────────────
          persons.isEmpty
              ? Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🤝', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        const Text(
                          'কোনো মানুষ নেই',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+ বাটন চাপো',
                          style: TextStyle(
                            color: AppColors.gold.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: persons.length,
                    itemBuilder: (context, i) {
                      final person = persons[i];
                      final net = ref.watch(personNetProvider(person.id));
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PersonLedgerScreen(person: person),
                          ),
                        ),
                        onLongPress: () => _deletePersonDialog(context, ref, person),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141C2E),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              person.imagePath != null
                                  ? CircleAvatar(
                                      radius: 26,
                                      backgroundImage: FileImage(File(person.imagePath!)),
                                    )
                                  : CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppColors.purple.withOpacity(0.2),
                                      child: Text(
                                        person.name.isNotEmpty
                                            ? person.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.purple,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (person.phone.isNotEmpty)
                                      Text(
                                        person.phone,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    net == 0
                                        ? 'সমান'
                                        : net > 0
                                            ? 'পাওনা'
                                            : 'দেনা',
                                    style: TextStyle(
                                      color: net >= 0 ? AppColors.teal : AppColors.rose,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '৳${net.abs().toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: net >= 0 ? AppColors.teal : AppColors.rose,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Syne',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textDim,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // ── Add person dialog ─────────────────────────────────────────
  void _addPersonDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl  = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? imagePath;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setS) {
            return AlertDialog(
              backgroundColor: const Color(0xFF141C2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'নতুন মানুষ যোগ করো',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo
                    GestureDetector(
                      onTap: () async {
                        final img = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 300,
                          maxHeight: 300,
                          imageQuality: 80,
                        );
                        if (img != null) setS(() => imagePath = img.path);
                      },
                      child: Center(
                        child: imagePath != null
                            ? CircleAvatar(
                                radius: 36,
                                backgroundImage: FileImage(File(imagePath!)),
                              )
                            : Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.purple.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_rounded,
                                      color: AppColors.purple,
                                      size: 22,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'ছবি',
                                      style: TextStyle(
                                        color: AppColors.purple,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _field(nameCtrl, 'নাম', Icons.person_outline_rounded, AppColors.gold),
                    const SizedBox(height: 12),
                    _field(
                      phoneCtrl,
                      'মোবাইল নম্বর',
                      Icons.phone_outlined,
                      AppColors.teal,
                      phone: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx2),
                  child: const Text(
                    'বাতিল',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    ref.read(debtPersonsProvider.notifier).addPerson(
                      DebtPerson(
                        id: const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        imagePath: imagePath,
                      ),
                    );
                    Navigator.pop(ctx2);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: const Color(0xFF0A0E1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'যোগ করো',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Delete person dialog ──────────────────────────────────────
  void _deletePersonDialog(BuildContext context, WidgetRef ref, DebtPerson person) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Delete করবে?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '"${person.name}" এবং তার সব লেনদেন মুছে যাবে।',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'বাতিল',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(debtPersonsProvider.notifier).deletePerson(person.id);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ── Input field helper ────────────────────────────────────────
  static Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    Color color, {
    bool phone = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: phone ? TextInputType.phone : TextInputType.name,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
        prefixIcon: Icon(icon, color: color, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 2.  PERSON LEDGER SCREEN
// ══════════════════════════════════════════════════════════════════
class PersonLedgerScreen extends ConsumerWidget {
  final DebtPerson person;
  const PersonLedgerScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(debtTransactionsProvider);
    final txs = ref.read(debtTransactionsProvider.notifier).forPerson(person.id);
    final net = ref.watch(personNetProvider(person.id));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            person.imagePath != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: FileImage(File(person.imagePath!)),
                  )
                : CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.purple.withOpacity(0.2),
                    child: Text(
                      person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
            const SizedBox(width: 10),
            Text(
              person.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Syne',
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEntrySheet(context, ref),
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF0A0E1A),
        icon: const Icon(Icons.add_rounded),
        label: const Text('লেনদেন যোগ', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // ── Net card ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: net >= 0
                    ? AppColors.teal.withOpacity(0.1)
                    : AppColors.rose.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: net >= 0
                      ? AppColors.teal.withOpacity(0.3)
                      : AppColors.rose.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          net > 0
                              ? '${person.name} এর কাছে পাওনা'
                              : net < 0
                                  ? '${person.name} কে দেনা'
                                  : 'হিসাব সমান',
                          style: TextStyle(
                            color: net >= 0 ? AppColors.teal : AppColors.rose,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '৳${net.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            color: net >= 0 ? AppColors.teal : AppColors.rose,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Syne',
                          ),
                        ),
                        if (person.phone.isNotEmpty)
                          Text(
                            person.phone,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(net >= 0 ? '💵' : '💸', style: const TextStyle(fontSize: 40)),
                ],
              ),
            ),
          ),

          // ── Transaction list ───────────────────────────────────
          txs.isEmpty
              ? const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('📋', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(
                          'কোনো লেনদেন নেই',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                        Text(
                          'নিচে + বাটন চাপো',
                          style: TextStyle(color: AppColors.textDim, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: txs.length,
                    itemBuilder: (context, i) {
                      final tx = txs[i];
                      final isGave = tx.type == DebtType.gave;
                      return Dismissible(
                        key: Key(tx.id),
                        direction: DismissDirection.endToStart,
                        // ── Confirm before delete ──────────────
                        confirmDismiss: (direction) async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (dCtx) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFF141C2E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text(
                                  'Delete করবে?',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Syne',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: Text(
                                  '"${tx.note}" — ৳${tx.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    child: const Text(
                                      'না',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.rose,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('হ্যাঁ, Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                          return result ?? false;
                        },
                        onDismissed: (direction) {
                          ref
                              .read(debtTransactionsProvider.notifier)
                              .delete(tx.id);
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.rose,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141C2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isGave
                                      ? AppColors.rose.withOpacity(0.15)
                                      : AppColors.teal.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: isGave
                                        ? AppColors.rose.withOpacity(0.3)
                                        : AppColors.teal.withOpacity(0.3),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    isGave ? '↑' : '↓',
                                    style: TextStyle(
                                      color: isGave ? AppColors.rose : AppColors.teal,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.note,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${isGave ? 'দিয়েছি' : 'পেয়েছি'} · '
                                      '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                      style: TextStyle(
                                        color: isGave
                                            ? AppColors.rose.withOpacity(0.8)
                                            : AppColors.teal.withOpacity(0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isGave ? '-' : '+'}৳${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: isGave ? AppColors.rose : AppColors.teal,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Syne',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // ── Add entry bottom sheet ────────────────────────────────────
  void _addEntrySheet(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    final noteCtrl   = TextEditingController();
    DebtType selectedType = DebtType.gave;
    bool affectMain = false;
    DateTime date   = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx2, setS) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx2).viewInsets.bottom,
              ),
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
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'লেনদেন যোগ করো',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Syne',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [DebtType.gave, DebtType.received].map((t) {
                          final isSel   = selectedType == t;
                          final isGave  = t == DebtType.gave;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setS(() => selectedType = t),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSel
                                      ? (isGave ? AppColors.gradRose : AppColors.gradTeal)
                                      : null,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  isGave ? '↑ আমি দিয়েছি' : '↓ আমি পেয়েছি',
                                  style: TextStyle(
                                    color: isSel ? Colors.white : AppColors.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Syne',
                      ),
                      decoration: InputDecoration(
                        hintText: '০.০০',
                        hintStyle: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 20,
                          fontFamily: 'Syne',
                        ),
                        prefixText: '৳ ',
                        prefixStyle: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.gold,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Note
                    TextField(
                      controller: noteCtrl,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'কারণ লেখো (ঐচ্ছিক)',
                        hintStyle: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.gold,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetCtx2,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (c, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.gold,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) setS(() => date = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.gold,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Affect main balance toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: affectMain
                            ? AppColors.gold.withOpacity(0.08)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: affectMain
                              ? AppColors.gold.withOpacity(0.3)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedType == DebtType.gave
                                      ? '💸 মূল ব্যালেন্স থেকে কাটবে?'
                                      : '💰 মূল ব্যালেন্সে যোগ হবে?',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  selectedType == DebtType.gave
                                      ? 'চালু করলে Expense যোগ হবে'
                                      : 'চালু করলে Income যোগ হবে',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: affectMain,
                            onChanged: (v) => setS(() => affectMain = v),
                            activeColor: AppColors.gold,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save button
                    GestureDetector(
                      onTap: () {
                        if (amountCtrl.text.trim().isEmpty) return;
                        final amount = double.tryParse(amountCtrl.text) ?? 0;
                        if (amount <= 0) return;
                        final note = noteCtrl.text.trim().isNotEmpty
                            ? noteCtrl.text.trim()
                            : (selectedType == DebtType.gave
                                ? '${person.name} কে দিয়েছি'
                                : '${person.name} থেকে পেয়েছি');

                        ref.read(debtTransactionsProvider.notifier).add(
                          DebtTransaction(
                            id: const Uuid().v4(),
                            personId: person.id,
                            amount: amount,
                            type: selectedType,
                            date: date,
                            note: note,
                          ),
                        );

                        if (affectMain) {
                          ref.read(transactionsProvider.notifier).add(
                            type: selectedType == DebtType.gave
                                ? TransactionType.expense
                                : TransactionType.income,
                            category: 'দেনা-পাওনা',
                            amount: amount,
                            note: note,
                            date: date,
                            icon: selectedType == DebtType.gave ? '💸' : '💰',
                          );
                        }

                        Navigator.pop(sheetCtx2);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.teal,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            content: Text(
                              '✅ লেনদেন যোগ হয়েছে'
                              '${affectMain ? " (মূল ব্যালেন্সেও)" : ""}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradGold,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'সেভ করো',
                          style: TextStyle(
                            color: Color(0xFF0A0E1A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Syne',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
