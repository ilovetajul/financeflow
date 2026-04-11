import 'package:flutter/material.dart';
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

class _PdfExportScreenState extends ConsumerState<PdfExportScreen> {
  DateTime _fromDate = DateTime(
      DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  bool _generating = false;
  String? _savedPath;

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.gold)),
        child: child!),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  List<Transaction> _getFilteredTxs(List<Transaction> all) {
    return all.where((tx) =>
        !tx.date.isBefore(_fromDate) &&
        !tx.date.isAfter(_toDate.add(const Duration(days: 1)))).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _generatePdf(List<Transaction> transactions) async {
    setState(() { _generating = true; _savedPath = null; });
    try {
      final filtered = _getFilteredTxs(transactions);
      final totalIncome = filtered
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final totalExpense = filtered
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      final balance = totalIncome - totalExpense;

      final pdf = pw.Document();

      // Group by date
      final grouped = <String, List<Transaction>>{};
      for (final tx in filtered) {
        final key = '${tx.date.day}/${tx.date.month}/${tx.date.year}';
        grouped.putIfAbsent(key, () => []).add(tx);
      }

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [

          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF0D1B3E),
              borderRadius: pw.BorderRadius.circular(12)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FinanceFlow',
                  style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFFF4C55A))),
                pw.SizedBox(height: 4),
                pw.Text('Financial Report',
                  style: pw.TextStyle(fontSize: 14,
                    color: const PdfColor.fromInt(0xFF8892A4))),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Period: ${_fromDate.day}/${_fromDate.month}/${_fromDate.year} — ${_toDate.day}/${_toDate.month}/${_toDate.year}',
                  style: pw.TextStyle(fontSize: 11,
                    color: const PdfColor.fromInt(0xFF8892A4))),
              ]),
          ),

          pw.SizedBox(height: 20),

          // Summary
          pw.Row(children: [
            _pdfSummaryBox('মোট জমা', '৳${totalIncome.toStringAsFixed(0)}',
              const PdfColor.fromInt(0xFF38D9C0)),
            pw.SizedBox(width: 12),
            _pdfSummaryBox('মোট খরচ', '৳${totalExpense.toStringAsFixed(0)}',
              const PdfColor.fromInt(0xFFF4617A)),
            pw.SizedBox(width: 12),
            _pdfSummaryBox('ব্যালেন্স',
              '${balance >= 0 ? '+' : '-'}৳${balance.abs().toStringAsFixed(0)}',
              balance >= 0
                  ? const PdfColor.fromInt(0xFFF4C55A)
                  : const PdfColor.fromInt(0xFFF4617A)),
          ]),

          pw.SizedBox(height: 20),

          // Transactions count
          pw.Text('মোট ${filtered.length} টি লেনদেন',
            style: pw.TextStyle(fontSize: 12,
              color: const PdfColor.fromInt(0xFF8892A4))),

          pw.SizedBox(height: 12),

          // Table Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            color: const PdfColor.fromInt(0xFF141C2E),
            child: pw.Row(children: [
              pw.Expanded(flex: 2, child: pw.Text('তারিখ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                  fontSize: 10, color: const PdfColor.fromInt(0xFF8892A4)))),
              pw.Expanded(flex: 3, child: pw.Text('বিবরণ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                  fontSize: 10, color: const PdfColor.fromInt(0xFF8892A4)))),
              pw.Expanded(flex: 2, child: pw.Text('Category',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                  fontSize: 10, color: const PdfColor.fromInt(0xFF8892A4)))),
              pw.Expanded(flex: 2, child: pw.Text('জমা',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                  fontSize: 10, color: const PdfColor.fromInt(0xFF38D9C0)),
                textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: pw.Text('খরচ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                  fontSize: 10, color: const PdfColor.fromInt(0xFFF4617A)),
                textAlign: pw.TextAlign.right)),
            ]),
          ),

          // Transactions by date
          ...grouped.entries.map((entry) => pw.Column(children: [
            // Date separator
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              color: const PdfColor.fromInt(0xFFF4C55A),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(entry.key,
                    style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF0A0E1A))),
                  pw.Text(
                    'ব্যালেন্স: ${_dayBalance(entry.value) >= 0 ? '+' : ''}৳${_dayBalance(entry.value).toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF0A0E1A))),
                ]),
            ),

            // Transactions for this date
            ...entry.value.asMap().entries.map((e) {
              final tx = e.value;
              final isIncome = tx.type == TransactionType.income;
              final bgColor = e.key.isEven
                  ? const PdfColor.fromInt(0xFFF8F9FF)
                  : PdfColors.white;
              return pw.Container(
                color: bgColor,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: pw.Row(children: [
                  pw.Expanded(flex: 2, child: pw.Text(
                    '${tx.date.day}/${tx.date.month}',
                    style: const pw.TextStyle(fontSize: 9,
                      color: PdfColor.fromInt(0xFF4A5568)))),
                  pw.Expanded(flex: 3, child: pw.Text(
                    tx.note,
                    style: const pw.TextStyle(fontSize: 9))),
                  pw.Expanded(flex: 2, child: pw.Text(
                    tx.category,
                    style: const pw.TextStyle(fontSize: 9,
                      color: PdfColor.fromInt(0xFF4A5568)))),
                  pw.Expanded(flex: 2, child: pw.Text(
                    isIncome ? '৳${tx.amount.toStringAsFixed(0)}' : '',
                    style: const pw.TextStyle(fontSize: 9,
                      color: PdfColor.fromInt(0xFF38D9C0)),
                    textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text(
                    !isIncome ? '৳${tx.amount.toStringAsFixed(0)}' : '',
                    style: const pw.TextStyle(fontSize: 9,
                      color: PdfColor.fromInt(0xFFF4617A)),
                    textAlign: pw.TextAlign.right)),
                ]),
              );
            }),
          ])),

          pw.SizedBox(height: 20),

          // Footer total
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: const PdfColor.fromInt(0xFF141C2E),
            child: pw.Row(children: [
              pw.Expanded(flex: 7,
                child: pw.Text('সর্বমোট',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                    fontSize: 11, color: const PdfColor.fromInt(0xFFF4C55A)))),
              pw.Expanded(flex: 2,
                child: pw.Text('৳${totalIncome.toStringAsFixed(0)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                    fontSize: 11, color: const PdfColor.fromInt(0xFF38D9C0)),
                  textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 2,
                child: pw.Text('৳${totalExpense.toStringAsFixed(0)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
                    fontSize: 11, color: const PdfColor.fromInt(0xFFF4617A)),
                  textAlign: pw.TextAlign.right)),
            ]),
          ),

          pw.SizedBox(height: 8),
          pw.Text(
            'Generated by FinanceFlow · ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: const pw.TextStyle(fontSize: 9,
              color: PdfColor.fromInt(0xFF8892A4))),
        ],
      ));

      // Save PDF
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'financeflow_${_fromDate.year}${_fromDate.month.toString().padLeft(2, '0')}${_fromDate.day.toString().padLeft(2, '0')}_to_${_toDate.year}${_toDate.month.toString().padLeft(2, '0')}${_toDate.day.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Save to Downloads too
      try {
        final dl = Directory('/storage/emulated/0/Download/FinanceFlow');
        if (!await dl.exists()) await dl.create(recursive: true);
        await File('${dl.path}/$fileName').writeAsBytes(await pdf.save());
      } catch (_) {}

      setState(() {
        _generating = false;
        _savedPath = file.path;
      });
    } catch (e) {
      setState(() => _generating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.rose,
          content: Text('PDF তৈরি ব্যর্থ: $e')));
      }
    }
  }

  double _dayBalance(List<Transaction> txs) {
    return txs.fold(0.0, (s, t) =>
        t.type == TransactionType.income ? s + t.amount : s - t.amount);
  }

  pw.Widget _pdfSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10,
            color: PdfColor.fromInt(0xFF8892A4))),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 14,
            fontWeight: pw.FontWeight.bold, color: color)),
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
    final filtered = _getFilteredTxs(allTxs);
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
        title: const Text('PDF Export',
          style: TextStyle(color: AppColors.textPrimary,
              fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 18)),
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

            // ── Date Range ──
            const Text('তারিখের পরিসর বেছে নাও',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Syne')),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: _DateButton(
                label: 'শুরু তারিখ',
                date: _fromDate,
                onTap: () => _pickDate(true))),
              const SizedBox(width: 10),
              const Text('—', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(width: 10),
              Expanded(child: _DateButton(
                label: 'শেষ তারিখ',
                date: _toDate,
                onTap: () => _pickDate(false))),
            ]),

            const SizedBox(height: 12),

            // Quick date shortcuts
            Row(children: [
              _QuickDate(label: 'এই মাস', onTap: () => setState(() {
                final now = DateTime.now();
                _fromDate = DateTime(now.year, now.month, 1);
                _toDate = now;
              })),
              const SizedBox(width: 8),
              _QuickDate(label: 'গত মাস', onTap: () => setState(() {
                final now = DateTime.now();
                final last = DateTime(now.year, now.month - 1);
                _fromDate = DateTime(last.year, last.month, 1);
                _toDate = DateTime(now.year, now.month, 0);
              })),
              const SizedBox(width: 8),
              _QuickDate(label: 'এই বছর', onTap: () => setState(() {
                final now = DateTime.now();
                _fromDate = DateTime(now.year, 1, 1);
                _toDate = now;
              })),
            ]),

            const SizedBox(height: 20),

            // ── Preview ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141C2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Preview',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w700,
                        fontFamily: 'Syne')),
                  Text('${filtered.length} টি লেনদেন',
                    style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                ]),
                const SizedBox(height: 12),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _PreviewItem(
                    label: 'মোট জমা', value: totalIncome, color: AppColors.teal)),
                  Expanded(child: _PreviewItem(
                    label: 'মোট খরচ', value: totalExpense, color: AppColors.rose)),
                  Expanded(child: _PreviewItem(
                    label: 'ব্যালেন্স',
                    value: totalIncome - totalExpense,
                    color: totalIncome >= totalExpense
                        ? AppColors.gold : AppColors.rose)),
                ]),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Generate Button ──
            if (!_generating)
              GestureDetector(
                onTap: filtered.isEmpty
                    ? null
                    : () => _generatePdf(allTxs),
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    gradient: filtered.isEmpty ? null : AppColors.gradGold,
                    color: filtered.isEmpty
                        ? Colors.white.withOpacity(0.07) : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: filtered.isEmpty ? null : [BoxShadow(
                      color: AppColors.gold.withOpacity(0.35),
                      blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filtered.isEmpty
                        ? 'এই সময়ে কোনো লেনদেন নেই'
                        : '📄 PDF তৈরি করো',
                    style: TextStyle(
                      color: filtered.isEmpty
                          ? AppColors.textMuted : const Color(0xFF0A0E1A),
                      fontSize: 16, fontWeight: FontWeight.w800,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.gold, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('PDF তৈরি হচ্ছে...',
                      style: TextStyle(color: AppColors.gold,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
              ),

            // ── Share/Download buttons after generation ──
            if (_savedPath != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Text('✅', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Expanded(child: Text(
                    'PDF তৈরি হয়েছে!\nDownload/FinanceFlow/ তে save হয়েছে।',
                    style: TextStyle(color: AppColors.teal,
                        fontSize: 13, fontWeight: FontWeight.w600, height: 1.5))),
                ]),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  if (_savedPath != null) {
                    await Share.shareXFiles(
                      [XFile(_savedPath!)],
                      subject: 'FinanceFlow Report',
                      text: 'FinanceFlow Financial Report');
                  }
                },
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradTeal,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Text('📤 Share PDF',
                    style: TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w800, fontFamily: 'Syne')),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141C2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded,
              color: AppColors.gold, size: 16),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(
                color: AppColors.textDim, fontSize: 10)),
            Text('${date.day}/${date.month}/${date.year}',
              style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

class _QuickDate extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickDate({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(label, style: const TextStyle(
            color: AppColors.textMuted, fontSize: 12)),
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _PreviewItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
      const SizedBox(height: 4),
      Text('৳${value.toStringAsFixed(0)}',
        style: TextStyle(color: color, fontSize: 14,
            fontWeight: FontWeight.w800, fontFamily: 'Syne')),
    ]);
  }
}
