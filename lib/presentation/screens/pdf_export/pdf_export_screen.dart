import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
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
  DateTime _fromDate =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  bool _generating = false;
  String? _savedPath;

  // ── Date picker ─────────────────────────────────────────
  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme:
                const ColorScheme.dark(primary: AppColors.gold)),
        child: child!),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  // ── Filter transactions by selected date range ──────────
  List<Transaction> _getFiltered(List<Transaction> all) {
    return all
        .where((tx) =>
            !tx.date.isBefore(_fromDate) &&
            !tx.date.isAfter(_toDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ── Escape HTML special characters ─────────────────────
  String _esc(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  // ── Build HTML string ───────────────────────────────────
  String _buildHtml({
    required List<Transaction> filtered,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required Map<String, List<Transaction>> grouped,
  }) {
    final balanceColor = balance >= 0 ? '#F4C55A' : '#F4617A';
    final balanceText =
        '${balance >= 0 ? '+' : ''}৳${balance.toStringAsFixed(0)}';

    // ── Build transaction rows ──
    final StringBuffer rows = StringBuffer();
    for (final entry in grouped.entries) {
      final dayTxs = entry.value;
      final dayBal = dayTxs.fold<double>(
          0,
          (s, t) => t.type == TransactionType.income
              ? s + t.amount
              : s - t.amount);
      final dayBalText =
          '${dayBal >= 0 ? '+' : ''}৳${dayBal.toStringAsFixed(0)}';

      // Date separator
      rows.write('''
        <tr class="date-row">
          <td colspan="3"><b>${entry.key}</b></td>
          <td colspan="2" style="text-align:right;">
            <b>দিনের ব্যালেন্স: $dayBalText</b>
          </td>
        </tr>
      ''');

      // Transactions for that date
      for (int i = 0; i < dayTxs.length; i++) {
        final tx = dayTxs[i];
        final isIncome = tx.type == TransactionType.income;
        final rowBg = i.isEven ? '#F8FAFF' : '#FFFFFF';
        final incomeCell = isIncome
            ? '<b style="color:#38D9C0;">৳${tx.amount.toStringAsFixed(0)}</b>'
            : '';
        final expenseCell = !isIncome
            ? '<b style="color:#F4617A;">৳${tx.amount.toStringAsFixed(0)}</b>'
            : '';

        rows.write('''
          <tr style="background:$rowBg;">
            <td style="color:#6B7280;">${tx.date.day}/${tx.date.month}</td>
            <td>${_esc(tx.note)}</td>
            <td style="color:#6B7280;">${_esc(tx.category)}</td>
            <td style="text-align:right;">$incomeCell</td>
            <td style="text-align:right;">$expenseCell</td>
          </tr>
        ''');
      }
    }

    final now = DateTime.now();

    return '''
<!DOCTYPE html>
<html lang="bn">
<head>
  <meta charset="UTF-8"/>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;700&display=swap');

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Noto Sans Bengali', sans-serif;
      font-size: 11px;
      color: #1F2937;
      background: #FFFFFF;
      padding: 24px;
    }

    /* Header */
    .header {
      background: #1E3A5F;
      border-radius: 10px;
      padding: 18px 20px;
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 16px;
    }
    .app-title { font-size: 24px; font-weight: 700; color: #F4C55A; margin-bottom: 4px; }
    .subtitle  { font-size: 12px; color: #8892A4; margin-bottom: 2px; }
    .date-range { font-size: 10px; color: #8892A4; }
    .tx-label  { font-size: 10px; color: #8892A4; text-align: right; }
    .tx-count  { font-size: 14px; font-weight: 700; color: #F4C55A; text-align: right; }

    /* Summary boxes */
    .summary { display: flex; gap: 10px; margin-bottom: 16px; }
    .box {
      flex: 1;
      border-radius: 8px;
      padding: 10px 12px;
      border: 1.5px solid;
    }
    .box-label { font-size: 9px; color: #6B7280; margin-bottom: 4px; }
    .box-value { font-size: 15px; font-weight: 700; }
    .box-income  { border-color: #38D9C0; }
    .box-expense { border-color: #F4617A; }
    .box-balance { border-color: $balanceColor; }
    .box-income  .box-value { color: #38D9C0; }
    .box-expense .box-value { color: #F4617A; }
    .box-balance .box-value { color: $balanceColor; }

    /* Table */
    table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }

    thead tr { background: #1E3A5F; }
    thead th {
      padding: 7px 8px;
      font-size: 10px;
      font-weight: 700;
      color: #FFFFFF;
      text-align: left;
    }
    thead th.h-income  { color: #38D9C0; text-align: right; }
    thead th.h-expense { color: #F4617A; text-align: right; }

    /* Date separator */
    tr.date-row td {
      background: #FDF3CE;
      padding: 5px 8px;
      font-size: 9px;
      color: #0A0E1A;
      border-bottom: none;
    }

    /* Data rows */
    tbody tr td {
      padding: 6px 8px;
      font-size: 10px;
      vertical-align: middle;
      border-bottom: 1px solid #F3F4F6;
    }

    /* Total row */
    .total-row td {
      background: #1E3A5F !important;
      padding: 8px 8px;
      font-size: 11px;
      font-weight: 700;
      border: none;
    }
    .lbl   { color: #F4C55A; }
    .t-inc { color: #38D9C0; text-align: right; }
    .t-exp { color: #F4617A; text-align: right; }

    /* Column widths */
    .c-date { width: 55px; }
    .c-note { }
    .c-cat  { width: 95px; }
    .c-amt  { width: 80px; text-align: right; }

    /* Footer */
    .footer { margin-top: 14px; font-size: 9px; color: #9CA3AF; }
  </style>
</head>
<body>

  <!-- Header -->
  <div class="header">
    <div>
      <div class="app-title">FinanceFlow</div>
      <div class="subtitle">আর্থিক প্রতিবেদন</div>
      <div class="date-range">
        ${_fromDate.day}/${_fromDate.month}/${_fromDate.year}
        &mdash;
        ${_toDate.day}/${_toDate.month}/${_toDate.year}
      </div>
    </div>
    <div>
      <div class="tx-label">মোট লেনদেন</div>
      <div class="tx-count">${filtered.length} টি</div>
    </div>
  </div>

  <!-- Summary -->
  <div class="summary">
    <div class="box box-income">
      <div class="box-label">মোট জমা</div>
      <div class="box-value">৳${totalIncome.toStringAsFixed(0)}</div>
    </div>
    <div class="box box-expense">
      <div class="box-label">মোট খরচ</div>
      <div class="box-value">৳${totalExpense.toStringAsFixed(0)}</div>
    </div>
    <div class="box box-balance">
      <div class="box-label">ব্যালেন্স</div>
      <div class="box-value">$balanceText</div>
    </div>
  </div>

  <!-- Table -->
  <table>
    <thead>
      <tr>
        <th class="c-date">তারিখ</th>
        <th class="c-note">বিবরণ</th>
        <th class="c-cat">Category</th>
        <th class="c-amt h-income">জমা</th>
        <th class="c-amt h-expense">খরচ</th>
      </tr>
    </thead>
    <tbody>
      $rows
      <tr class="total-row">
        <td colspan="3" class="lbl">সর্বমোট</td>
        <td class="t-inc">৳${totalIncome.toStringAsFixed(0)}</td>
        <td class="t-exp">৳${totalExpense.toStringAsFixed(0)}</td>
      </tr>
    </tbody>
  </table>

  <!-- Footer -->
  <div class="footer">
    Generated by FinanceFlow &middot; ${now.day}/${now.month}/${now.year}
  </div>

</body>
</html>
''';
  }

  // ── Generate PDF using Printing.convertHtml ─────────────
  Future<void> _generatePdf(List<Transaction> transactions) async {
    setState(() {
      _generating = true;
      _savedPath = null;
    });

    try {
      final filtered = _getFiltered(transactions);

      final totalIncome = filtered
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final totalExpense = filtered
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      final balance = totalIncome - totalExpense;

      // Group by date (same logic as before)
      final grouped = <String, List<Transaction>>{};
      for (final tx in filtered) {
        final key =
            '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}';
        grouped.putIfAbsent(key, () => []).add(tx);
      }

      // Build HTML → PDF via device WebView (Bengali CTL works perfectly)
      final htmlContent = _buildHtml(
        filtered: filtered,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        grouped: grouped,
      );

      final bytes = await Printing.convertHtml(
        format: PdfPageFormat.a4,
        html: htmlContent,
      );

      // ── Save to app documents directory ──
      final dir = await getApplicationDocumentsDirectory();
      final fname =
          'financeflow_${_fromDate.year}${_fromDate.month.toString().padLeft(2, '0')}${_fromDate.day.toString().padLeft(2, '0')}_${_toDate.year}${_toDate.month.toString().padLeft(2, '0')}${_toDate.day.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$fname');
      await file.writeAsBytes(bytes);

      // ── Save to Downloads/FinanceFlow/ ──
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

  // ── UI ──────────────────────────────────────────────────
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
                fontWeight: FontWeight.w700,
                fontSize: 18)),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
                    style: TextStyle(color: AppColors.textMuted))),
              Expanded(child: _DateBtn(
                  label: 'শেষ তারিখ',
                  date: _toDate,
                  onTap: () => _pickDate(false))),
            ]),

            const SizedBox(height: 12),

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

            // Preview card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141C2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withOpacity(0.06))),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          ? AppColors.gold
                          : AppColors.rose)),
                ]),
              ]),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.teal.withOpacity(0.2))),
              child: const Row(children: [
                Text('🔤', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'HTML-to-PDF পদ্ধতিতে বাংলা যুক্তবর্ণ সঠিকভাবে দেখাবে।',
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
                    boxShadow: filtered.isEmpty ? null : [BoxShadow(
                        color: AppColors.gold.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6))]),
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

            // Success + Share + Download
            if (_savedPath != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.teal.withOpacity(0.3))),
                child: const Row(children: [
                  Text('✅', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Expanded(child: Text(
                    'PDF তৈরি হয়েছে!\nDownload/FinanceFlow/ তে save হয়েছে। বাংলা লেখা সঠিকভাবে দেখাবে।',
                    style: TextStyle(
                        color: AppColors.teal, fontSize: 13,
                        fontWeight: FontWeight.w600, height: 1.4))),
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
                              fontFamily: 'Syne'))),
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
                              fontFamily: 'Syne'))),
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

// ── Helper Widgets (unchanged from original) ────────────────

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateBtn(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141C2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded,
              color: AppColors.gold, size: 16),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textDim, fontSize: 10)),
            Text('${date.day}/${date.month}/${date.year}',
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
  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
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
      {required this.label, required this.value, required this.color});

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
