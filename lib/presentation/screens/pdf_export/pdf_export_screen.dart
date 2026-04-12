import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../app/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/models/transaction.dart';

class PdfExportScreen extends ConsumerStatefulWidget {
  const PdfExportScreen({super.key});

  @override
  ConsumerState<PdfExportScreen> createState() =>
      _PdfExportScreenState();
}

class _PdfExportScreenState
    extends ConsumerState<PdfExportScreen> {
  DateTime _fromDate =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  bool _generating = false;
  String? _savedPath;

  // ── Load Bengali font ──────────────────────────────────
  Future<pw.Font> _loadBengaliFont({bool bold = false}) async {
    final fontName = bold
        ? 'assets/fonts/NotoSansBengali-Bold.ttf'
        : 'assets/fonts/NotoSansBengali-Regular.ttf';
    try {
      final data = await rootBundle.load(fontName);
      return pw.Font.ttf(data);
    } catch (_) {
      // Fallback to default if font not found
      return pw.Font.helvetica();
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: AppColors.gold)),
        child: child!),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  List<Transaction> _getFiltered(List<Transaction> all) {
    return all
        .where((tx) =>
            !tx.date.isBefore(_fromDate) &&
            !tx.date.isAfter(
                _toDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _generatePdf(
      List<Transaction> transactions) async {
    setState(() {
      _generating = true;
      _savedPath = null;
    });

    try {
      // Load Bengali fonts
      final regularFont = await _loadBengaliFont();
      final boldFont = await _loadBengaliFont(bold: true);

      final filtered = _getFiltered(transactions);
      final totalIncome = filtered
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final totalExpense = filtered
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      final balance = totalIncome - totalExpense;

      // Text styles with Bengali font
      final bodyStyle = pw.TextStyle(font: regularFont, fontSize: 9);
      final boldStyle = pw.TextStyle(
          font: boldFont, fontSize: 10,
          fontWeight: pw.FontWeight.bold);
      final headerStyle = pw.TextStyle(
          font: boldFont, fontSize: 14,
          fontWeight: pw.FontWeight.bold);
      final titleStyle = pw.TextStyle(
          font: boldFont, fontSize: 22,
          fontWeight: pw.FontWeight.bold);

      // Group by date
      final grouped = <String, List<Transaction>>{};
      for (final tx in filtered) {
        final key =
            '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}';
        grouped.putIfAbsent(key, () => []).add(tx);
      }

      final pdf = pw.Document();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        build: (context) => [

          // ── Header ──
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF1E3A5F),
              borderRadius: pw.BorderRadius.circular(10)),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FinanceFlow',
                      style: titleStyle.copyWith(
                        color: const PdfColor.fromInt(
                            0xFFF4C55A))),
                    pw.SizedBox(height: 4),
                    pw.Text('আর্থিক প্রতিবেদন',
                      style: boldStyle.copyWith(
                        color: const PdfColor.fromInt(
                            0xFF8892A4))),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${_fromDate.day}/${_fromDate.month}/${_fromDate.year} — ${_toDate.day}/${_toDate.month}/${_toDate.year}',
                      style: bodyStyle.copyWith(
                        color: const PdfColor.fromInt(
                            0xFF8892A4))),
                  ]),
                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('মোট লেনদেন',
                      style: bodyStyle.copyWith(
                        color: const PdfColor.fromInt(
                            0xFF8892A4))),
                    pw.Text('${filtered.length} টি',
                      style: boldStyle.copyWith(
                        color: const PdfColor.fromInt(
                            0xFFF4C55A))),
                  ]),
              ]),
          ),

          pw.SizedBox(height: 16),

          // ── Summary ──
          pw.Row(children: [
            _pdfBox('মোট জমা',
              '৳${totalIncome.toStringAsFixed(0)}',
              const PdfColor.fromInt(0xFF38D9C0),
              regularFont, boldFont),
            pw.SizedBox(width: 8),
            _pdfBox('মোট খরচ',
              '৳${totalExpense.toStringAsFixed(0)}',
              const PdfColor.fromInt(0xFFF4617A),
              regularFont, boldFont),
            pw.SizedBox(width: 8),
            _pdfBox(
              'ব্যালেন্স',
              '${balance >= 0 ? '+' : ''}৳${balance.toStringAsFixed(0)}',
              balance >= 0
                  ? const PdfColor.fromInt(0xFFF4C55A)
                  : const PdfColor.fromInt(0xFFF4617A),
              regularFont, boldFont),
          ]),

          pw.SizedBox(height: 16),

          // ── Table Header ──
          pw.Container(
            color: const PdfColor.fromInt(0xFF1E3A5F),
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            child: pw.Row(children: [
              pw.SizedBox(width: 50,
                child: pw.Text('তারিখ', style: boldStyle.copyWith(
                  color: PdfColors.white))),
              pw.Expanded(child: pw.Text('বিবরণ',
                style: boldStyle.copyWith(
                    color: PdfColors.white))),
              pw.SizedBox(width: 80,
                child: pw.Text('Category', style: boldStyle.copyWith(
                  color: PdfColors.white))),
              pw.SizedBox(width: 70,
                child: pw.Text('জমা', style: boldStyle.copyWith(
                  color: const PdfColor.fromInt(0xFF38D9C0)),
                  textAlign: pw.TextAlign.right)),
              pw.SizedBox(width: 70,
                child: pw.Text('খরচ', style: boldStyle.copyWith(
                  color: const PdfColor.fromInt(0xFFF4617A)),
                  textAlign: pw.TextAlign.right)),
            ]),
          ),

          // ── Transactions ──
          ...grouped.entries.expand((entry) {
            final dayTxs = entry.value;
            final dayBal = dayTxs.fold<double>(0, (s, t) =>
                t.type == TransactionType.income
                    ? s + t.amount : s - t.amount);
            return [
              // Date row
              pw.Container(
                color: const PdfColor.fromInt(0xFFF4C55A)
                    .shade(0.85),
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key,
                      style: boldStyle.copyWith(fontSize: 9,
                        color: const PdfColor.fromInt(
                            0xFF0A0E1A))),
                    pw.Text(
                      'দিনের ব্যালেন্স: ${dayBal >= 0 ? '+' : ''}৳${dayBal.toStringAsFixed(0)}',
                      style: boldStyle.copyWith(fontSize: 9,
                        color: const PdfColor.fromInt(
                            0xFF0A0E1A))),
                  ]),
              ),
              // TX rows
              ...dayTxs.asMap().entries.map((e) {
                final tx = e.value;
                final isIncome =
                    tx.type == TransactionType.income;
                final bg = e.key.isEven
                    ? const PdfColor.fromInt(0xFFF8FAFF)
                    : PdfColors.white;
                return pw.Container(
                  color: bg,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  child: pw.Row(children: [
                    pw.SizedBox(width: 50,
                      child: pw.Text(
                        '${tx.date.day}/${tx.date.month}',
                        style: bodyStyle.copyWith(
                          color: const PdfColor.fromInt(
                              0xFF6B7280)))),
                    pw.Expanded(child: pw.Text(
                      tx.note,
                      style: bodyStyle)),
                    pw.SizedBox(width: 80,
                      child: pw.Text(
                        tx.category,
                        style: bodyStyle.copyWith(
                          color: const PdfColor.fromInt(
                              0xFF6B7280)))),
                    pw.SizedBox(width: 70,
                      child: pw.Text(
                        isIncome
                            ? '৳${tx.amount.toStringAsFixed(0)}'
                            : '',
                        style: bodyStyle.copyWith(
                          color: const PdfColor.fromInt(
                              0xFF38D9C0),
                          fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right)),
                    pw.SizedBox(width: 70,
                      child: pw.Text(
                        !isIncome
                            ? '৳${tx.amount.toStringAsFixed(0)}'
                            : '',
                        style: bodyStyle.copyWith(
                          color: const PdfColor.fromInt(
                              0xFFF4617A),
                          fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right)),
                  ]),
                );
              }),
            ];
          }),

          pw.SizedBox(height: 8),

          // ── Total row ──
          pw.Container(
            color: const PdfColor.fromInt(0xFF1E3A5F),
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 8, vertical: 8),
            child: pw.Row(children: [
              pw.Expanded(child: pw.Text('সর্বমোট',
                style: boldStyle.copyWith(
                    color: const PdfColor.fromInt(
                        0xFFF4C55A)))),
              pw.SizedBox(width: 70,
                child: pw.Text(
                  '৳${totalIncome.toStringAsFixed(0)}',
                  style: boldStyle.copyWith(
                      color: const PdfColor.fromInt(
                          0xFF38D9C0)),
                  textAlign: pw.TextAlign.right)),
              pw.SizedBox(width: 70,
                child: pw.Text(
                  '৳${totalExpense.toStringAsFixed(0)}',
                  style: boldStyle.copyWith(
                      color: const PdfColor.fromInt(
                          0xFFF4617A)),
                  textAlign: pw.TextAlign.right)),
            ]),
          ),

          pw.SizedBox(height: 16),

          pw.Text(
            'Generated by FinanceFlow · ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: bodyStyle.copyWith(
                color: const PdfColor.fromInt(0xFF9CA3AF))),
        ],
      ));

      // ── Save ──
      final dir =
          await getApplicationDocumentsDirectory();
      final fname =
          'financeflow_${_fromDate.year}${_fromDate.month.toString().padLeft(2, '0')}${_fromDate.day.toString().padLeft(2, '0')}_${_toDate.year}${_toDate.month.toString().padLeft(2, '0')}${_toDate.day.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$fname');
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      // Save to Downloads too
      try {
        final dl = Directory(
            '/storage/emulated/0/Download/FinanceFlow');
        if (!await dl.exists()) {
          await dl.create(recursive: true);
        }
        await File('${dl.path}/$fname').writeAsBytes(bytes);
      } catch (_) {}

      setState(() {
        _generating = false;
        _savedPath = file.path;
      });
    } catch (e) {
      setState(() => _generating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.rose,
            content: Text('Error: $e')));
      }
    }
  }

  pw.Widget _pdfBox(String label, String value,
      PdfColor color, pw.Font regular, pw.Font bold) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
              style: pw.TextStyle(
                  font: regular, fontSize: 9,
                  color: const PdfColor.fromInt(0xFF6B7280))),
            pw.SizedBox(height: 4),
            pw.Text(value,
              style: pw.TextStyle(
                  font: bold, fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
          ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTxs = ref.watch(transactionsProvider).maybeWhen(
      data: (t) => t,
      orElse: () => <Transaction>[],
    );
    final filtered = _getFiltered(allTxs);
    final totalIncome = filtered
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = filtered
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('PDF রিপোর্ট',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Syne',
            fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text('তারিখের পরিসর বেছে নাও',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15, fontWeight: FontWeight.w700,
                fontFamily: 'Syne')),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: _DateBtn(
                label: 'শুরু তারিখ',
                date: _fromDate,
                onTap: () => _pickDate(true))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('—',
                    style: TextStyle(
                        color: AppColors.textMuted))),
              Expanded(child: _DateBtn(
                label: 'শেষ তারিখ',
                date: _toDate,
                onTap: () => _pickDate(false))),
            ]),

            const SizedBox(height: 12),

            // Quick shortcuts
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _QuickBtn(label: 'এই মাস', onTap: () {
                  final n = DateTime.now();
                  setState(() {
                    _fromDate = DateTime(n.year, n.month, 1);
                    _toDate = n;
                  });
                }),
                const SizedBox(width: 8),
                _QuickBtn(label: 'গত মাস', onTap: () {
                  final n = DateTime.now();
                  final l = DateTime(n.year, n.month - 1);
                  setState(() {
                    _fromDate = DateTime(l.year, l.month, 1);
                    _toDate = DateTime(n.year, n.month, 0);
                  });
                }),
                const SizedBox(width: 8),
                _QuickBtn(label: 'এই বছর', onTap: () {
                  final n = DateTime.now();
                  setState(() {
                    _fromDate = DateTime(n.year, 1, 1);
                    _toDate = n;
                  });
                }),
                const SizedBox(width: 8),
                _QuickBtn(label: 'সব', onTap: () {
                  setState(() {
                    _fromDate = DateTime(2020, 1, 1);
                    _toDate = DateTime.now();
                  });
                }),
              ]),
            ),

            const SizedBox(height: 20),

            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141C2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                  const Text('Preview',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Syne')),
                  Text('${filtered.length} টি লেনদেন',
                    style: const TextStyle(
                        color: AppColors.gold, fontSize: 12)),
                ]),
                const SizedBox(height: 12),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _PreviewItem(
                    label: 'মোট জমা',
                    value: totalIncome,
                    color: AppColors.teal)),
                  Expanded(child: _PreviewItem(
                    label: 'মোট খরচ',
                    value: totalExpense,
                    color: AppColors.rose)),
                  Expanded(child: _PreviewItem(
                    label: 'ব্যালেন্স',
                    value: totalIncome - totalExpense,
                    color: totalIncome >= totalExpense
                        ? AppColors.gold : AppColors.rose)),
                ]),
              ]),
            ),

            const SizedBox(height: 16),

            // Bengali font note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.teal.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Text('🔤', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'বাংলা লেখা সঠিকভাবে দেখাবে — NotoSansBengali font ব্যবহার করা হয়েছে।',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 12, height: 1.4))),
              ]),
            ),

            const SizedBox(height: 20),

            // Generate button
            if (!_generating)
              GestureDetector(
                onTap: filtered.isEmpty
                    ? null : () => _generatePdf(allTxs),
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    gradient: filtered.isEmpty
                        ? null : AppColors.gradGold,
                    color: filtered.isEmpty
                        ? Colors.white.withOpacity(0.07) : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: filtered.isEmpty
                        ? null : [BoxShadow(
                            color: AppColors.gold.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6))],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filtered.isEmpty
                        ? 'এই সময়ে কোনো লেনদেন নেই'
                        : '📄  PDF তৈরি করো',
                    style: TextStyle(
                      color: filtered.isEmpty
                          ? AppColors.textMuted
                          : const Color(0xFF0A0E1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Syne')),
                ),
              ),

            if (_generating)
              Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.gold,
                          strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('PDF তৈরি হচ্ছে...',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                  ]),
              ),

            // Success + Share + Download
            if (_savedPath != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.teal.withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Text('✅', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Expanded(child: Text(
                    'PDF তৈরি হয়েছে!\nDownload/FinanceFlow/ তে save হয়েছে। বাংলা লেখা সঠিকভাবে দেখাবে।',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4))),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (_savedPath != null) {
                        await Share.shareXFiles(
                          [XFile(_savedPath!)],
                          subject: 'FinanceFlow Report',
                          text: 'FinanceFlow Financial Report');
                      }
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradTeal,
                        borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: const Text('📤 Share',
                        style: TextStyle(
                          color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Syne')),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        backgroundColor: AppColors.gold,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          '📁 Download/FinanceFlow/ ফোল্ডারে save হয়েছে!',
                          style: TextStyle(
                              color: Color(0xFF0A0E1A),
                              fontWeight: FontWeight.w600)),
                      ));
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradGold,
                        borderRadius: BorderRadius.circular(14)),
                      alignment: Alignment.center,
                      child: const Text('📥 Download',
                        style: TextStyle(
                          color: Color(0xFF0A0E1A), fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Syne')),
                    ),
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateBtn(
      {required this.label,
      required this.date,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141C2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded,
              color: AppColors.gold, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: const TextStyle(
                    color: AppColors.textDim, fontSize: 10)),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
            ]),
        ]),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn(
      {required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(label,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 12)),
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _PreviewItem(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
        style: const TextStyle(
            color: AppColors.textDim, fontSize: 11)),
      const SizedBox(height: 4),
      Text('৳${value.toStringAsFixed(0)}',
        style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'Syne')),
    ]);
  }
}
