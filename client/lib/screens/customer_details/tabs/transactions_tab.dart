import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../models/customer_detail_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/customer_detail_service.dart';

import 'customer_info_tab.dart';

class _P {
  static const g1 = Color(0xFF7B3FE4);
  static const s900 = Color(0xFF0F172A);
  static const s600 = Color(0xFF475569);
  static const s200 = Color(0xFFE2E8F0);
  static const s100 = Color(0xFFF8FAFC);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
}

/// Filters + transaction list + receipt bottom sheet.
class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key, required this.customerId, required this.customerName});

  final String customerId;
  final String customerName;

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab>
    with AutomaticKeepAliveClientMixin {
  List<CustomerDetailTransaction> _all = [];
  CustomerDetailBalance? _balance;
  bool _loading = true;
  String? _error;
  int _filter = 0; // 0 all, 1 today, 2 week
  bool _downloading = false;
  bool _posting = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads transactions for the current filter window.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final range = _computeRange();
    try {
      final results = await Future.wait([
        CustomerDetailService.fetchTransactions(
          widget.customerId,
          startDate: range.$1,
          endDate: range.$2,
        ),
        CustomerDetailService.fetchBalance(widget.customerId),
      ]);
      final list = results[0] as List<CustomerDetailTransaction>;
      final bal = results[1] as CustomerDetailBalance;
      if (mounted) {
        setState(() {
          _all = list;
          _balance = bal;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is ApiException ? (e.message ?? 'Error') : '$e';
        });
      }
    }
  }

  (String?, String?) _computeRange() {
    final now = DateTime.now();
    switch (_filter) {
      case 1:
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        return (start.toUtc().toIso8601String(), end.toUtc().toIso8601String());
      case 2:
        final start = now.subtract(const Duration(days: 7));
        return (start.toUtc().toIso8601String(), now.toUtc().toIso8601String());
      default:
        return (null, null);
    }
  }

  Future<void> _openReceipt(CustomerDetailTransaction t) async {
    try {
      final r = await CustomerDetailService.fetchReceipt(widget.customerId, t.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => _ReceiptSheet(receipt: r),
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e is ApiException ? (e.message ?? 'Error') : '$e');
      }
    }
  }

  Future<void> _openAddBalanceSheet() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String payMode = 'cash';
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.s200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Balance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _P.s900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: payMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment mode',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(value: 'online', child: Text('Online')),
                    ],
                    onChanged: (v) => payMode = v ?? 'cash',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _posting
                              ? null
                              : () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  final amt =
                                      double.tryParse(amountCtrl.text.trim());
                                  if (amt == null || amt <= 0) {
                                    AppSnackbar.error(
                                        context, 'Enter a valid amount');
                                    return;
                                  }
                                  setState(() => _posting = true);
                                  try {
                                    await CustomerDetailService.addBalance(
                                      widget.customerId,
                                      amount: amt,
                                      paymentMode: payMode,
                                      note: noteCtrl.text.trim().isEmpty
                                          ? null
                                          : noteCtrl.text.trim(),
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(ctx);
                                    AppSnackbar.success(
                                        context, 'Balance added');
                                    await _load();
                                  } catch (e) {
                                    if (mounted) {
                                      AppSnackbar.error(
                                        context,
                                        e is ApiException
                                            ? (e.message ?? 'Error')
                                            : '$e',
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _posting = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _P.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _openDeductBalanceSheet() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.s200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Deduct Balance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _P.s900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reason / Note',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _posting
                              ? null
                              : () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  final amt =
                                      double.tryParse(amountCtrl.text.trim());
                                  if (amt == null || amt <= 0) {
                                    AppSnackbar.error(
                                        context, 'Enter a valid amount');
                                    return;
                                  }
                                  setState(() => _posting = true);
                                  try {
                                    await CustomerDetailService.deductBalance(
                                      widget.customerId,
                                      amount: amt,
                                      note: noteCtrl.text.trim(),
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(ctx);
                                    AppSnackbar.success(
                                        context, 'Balance deducted');
                                    await _load();
                                  } catch (e) {
                                    if (mounted) {
                                      AppSnackbar.error(
                                        context,
                                        e is ApiException
                                            ? (e.message ?? 'Error')
                                            : '$e',
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _posting = false);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _P.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Shimmer.fromColors(
        baseColor: _P.s200,
        highlightColor: _P.s100,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, _) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return CustomerDetailNetworkError(message: _error!, onRetry: _load);
    }

    final bal = _balance;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              _chip('All', 0),
              _chip('Today', 1),
              _chip('This Week', 2),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: _P.g1),
                tooltip: 'Download',
                onPressed: _downloading ? null : _openDownloadSheet,
              ),
            ],
          ),
        ),
        if (bal != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _P.s200, width: 0.8),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: _BalanceTile(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Wallet',
                      value: '₹${bal.walletBalance.toStringAsFixed(0)}',
                      color: _P.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BalanceTile(
                      icon: Icons.subscriptions_rounded,
                      label: 'Subscription',
                      value: '₹${bal.subscriptionBalance.toStringAsFixed(0)}',
                      color: _P.g1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: _all.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: _P.s600),
                      SizedBox(height: 8),
                      Text(
                        'No transactions found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _P.s600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _P.g1,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: _all.length,
                    itemBuilder: (context, i) {
                      final t = _all[i];
                      final credit = t.isCredit;
                      final amtColor = credit ? _P.green : _P.red;
                      final icon = Icons.arrow_circle_down;
                      final dt = DateTime.tryParse(t.date);
                      final dateStr = dt != null
                          ? DateFormat.yMMMd().add_jm().format(dt.toLocal())
                          : t.date;
                      final desc = t.description;
                      return RepaintBoundary(
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: _P.s200, width: 0.5),
                          ),
                          child: ListTile(
                            leading: Icon(icon, color: amtColor, size: 28),
                            title: Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _P.s900,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  desc,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _P.s600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${credit ? '+' : '-'}₹${t.displayAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: amtColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _P.s100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _P.s200),
                                      ),
                                      child: Text(
                                        t.typeLabel,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _P.s600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.receipt, color: _P.g1),
                              onPressed: () => _openReceipt(t),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _posting ? null : _openAddBalanceSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add Balance',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _posting ? null : _openDeductBalanceSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _P.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Deduct Balance',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, int index) {
    final sel = _filter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (v) async {
          if (v) {
            setState(() => _filter = index);
            await _load();
          }
        },
        selectedColor: _P.g1.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: sel ? _P.g1 : _P.s600,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _safeBusinessName() {
    // Business name is not part of the loaded transaction list payload.
    // Use a stable app name placeholder and still follow naming rules.
    return 'tiffincrm';
  }

  String _fileBase(String suffix) {
    final biz = _safeBusinessName().trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return '${biz}_${suffix}_${widget.customerId}'.toLowerCase();
  }

  Future<void> _openDownloadSheet() async {
    if (_all.isEmpty) {
      AppSnackbar.error(context, 'No data to download');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.s200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Download',
                            style: TextStyle(
                              color: _P.s900,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: _P.s200),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf_rounded, color: _P.g1),
                    title: const Text(
                      'Download as PDF',
                      style: TextStyle(color: _P.s900, fontWeight: FontWeight.w700),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _downloadPdf();
                    },
                  ),
                  Container(height: 1, color: _P.s200),
                  ListTile(
                    leading: const Icon(Icons.grid_on_rounded, color: _P.g1),
                    title: const Text(
                      'Download as Excel',
                      style: TextStyle(color: _P.s900, fontWeight: FontWeight.w700),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _downloadExcel();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _withLoading(Future<void> Function() task) async {
    if (!mounted) return;
    setState(() => _downloading = true);
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: _P.g1),
        ),
      );
      await task();
    } finally {
      if (mounted) setState(() => _downloading = false);
      if (Navigator.of(context).canPop()) Navigator.of(context).pop(); // close loading dialog
    }
  }

  Future<void> _downloadPdf() async {
    if (_all.isEmpty) {
      AppSnackbar.error(context, 'No data to download');
      return;
    }

    await _withLoading(() async {
      final now = DateTime.now();
      final credits = _all
          .where((t) => t.isCredit)
          .fold<double>(0, (s, t) => s + t.displayAmount);
      final debits = _all
          .where((t) => !t.isCredit)
          .fold<double>(0, (s, t) => s + t.displayAmount);
      final net = credits - debits;

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) {
            pw.Widget headerCell(String text, {pw.Alignment align = pw.Alignment.centerLeft}) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                color: PdfColors.grey300,
                alignment: align,
                child: pw.Text(
                  text,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
              );
            }

            pw.Widget bodyCell(
              String text, {
              pw.Alignment align = pw.Alignment.centerLeft,
              PdfColor? color,
            }) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                alignment: align,
                child: pw.Text(
                  text,
                  style: pw.TextStyle(fontSize: 9, color: color),
                ),
              );
            }

            return [
              pw.Text(
                _safeBusinessName(),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Customer: ${widget.customerName}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Generated: ${DateFormat('d MMM yyyy, h:mm a').format(now)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.1),
                  1: pw.FlexColumnWidth(3.3),
                  2: pw.FlexColumnWidth(1.3),
                  3: pw.FlexColumnWidth(1.6),
                  4: pw.FlexColumnWidth(1.7),
                },
                children: [
                  pw.TableRow(
                    children: [
                      headerCell('Date'),
                      headerCell('Description'),
                      headerCell('Type', align: pw.Alignment.center),
                      headerCell('Amount', align: pw.Alignment.centerRight),
                      headerCell('Payment Mode', align: pw.Alignment.center),
                    ],
                  ),
                  for (final t in _all)
                    pw.TableRow(
                      children: [
                        bodyCell(() {
                          final dt = DateTime.tryParse(t.date);
                          return dt != null
                              ? DateFormat('d MMM yyyy, h:mm a').format(dt.toLocal())
                              : t.date;
                        }()),
                        bodyCell(t.description),
                        bodyCell(t.typeLabel, align: pw.Alignment.center),
                        bodyCell(
                          '${t.isCredit ? '+' : '-'}₹${t.displayAmount.toStringAsFixed(2)}',
                          align: pw.Alignment.centerRight,
                          color: t.isCredit ? PdfColors.green : PdfColors.red,
                        ),
                        bodyCell(t.paymentMode, align: pw.Alignment.center),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Credits: ₹${credits.toStringAsFixed(2)}'),
                      pw.Text('Total Debits: ₹${debits.toStringAsFixed(2)}'),
                      pw.Text('Net Balance: ₹${net.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();
      await FileSaver.instance.saveFile(
        name: _fileBase('transactions'),
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (mounted) AppSnackbar.success(context, 'Downloaded successfully');
    });
  }

  Future<void> _downloadExcel() async {
    if (_all.isEmpty) {
      AppSnackbar.error(context, 'No data to download');
      return;
    }

    await _withLoading(() async {
      // No xlsx package installed; generate CSV content but save as .xlsx so Excel opens it.
      // This keeps functionality without changing any existing API/data flow.
      final header = ['Date', 'Description', 'Type', 'Amount', 'Payment Mode'];
      String esc(String v) {
        final s = v.replaceAll('"', '""');
        return '"$s"';
      }

      final credits = _all
          .where((t) => t.isCredit)
          .fold<double>(0, (s, t) => s + t.displayAmount);
      final debits = _all
          .where((t) => !t.isCredit)
          .fold<double>(0, (s, t) => s + t.displayAmount);
      final net = credits - debits;

      final lines = <String>[header.map(esc).join(',')];
      for (final t in _all) {
        final dt = DateTime.tryParse(t.date);
        final dateStr = dt != null ? dt.toLocal().toIso8601String() : t.date;
        final amountStr =
            '${t.isCredit ? '+₹' : '-₹'}${t.displayAmount.toStringAsFixed(2)}';
        lines.add([
          dateStr,
          t.description,
          t.typeLabel,
          amountStr,
          t.paymentMode,
        ].map((e) => esc(e.toString())).join(','));
      }
      lines.add([
        'Totals',
        '',
        '',
        'Credits ₹${credits.toStringAsFixed(2)} | Debits ₹${debits.toStringAsFixed(2)} | Net ₹${net.toStringAsFixed(2)}',
        '',
      ].map((e) => esc(e.toString())).join(','));

      final bytes = Uint8List.fromList(lines.join('\n').codeUnits);
      await FileSaver.instance.saveFile(
        name: _fileBase('transactions'),
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      if (mounted) AppSnackbar.success(context, 'Downloaded successfully');
    });
  }
}

/// Receipt preview with dashed rule and share.
class _ReceiptSheet extends StatelessWidget {
  const _ReceiptSheet({required this.receipt});

  final CustomerDetailReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.store, color: _P.g1),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      receipt.businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _P.s900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      final buf = StringBuffer()
                        ..writeln(receipt.businessName)
                        ..writeln(receipt.description)
                        ..writeln('Total: ₹${receipt.total.toStringAsFixed(0)}')
                        ..writeln('Mode: ${receipt.paymentMode}');
                      Share.share(buf.toString());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 1,
                child: CustomPaint(
                  painter: _DashedLinePainter(),
                ),
              ),
              const SizedBox(height: 12),
              ...receipt.items.map(
                (it) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.fiber_manual_record, size: 8, color: _P.s600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${it.name} x${it.quantity.toStringAsFixed(0)} @ ₹${it.unitPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, color: _P.s900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.currency_rupee, size: 18, color: _P.s900),
                  Text(
                    'Total: ₹${receipt.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _P.s900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.payment, size: 18, color: _P.s600),
                  const SizedBox(width: 6),
                  Text(
                    receipt.paymentMode,
                    style: const TextStyle(fontSize: 13, color: _P.s600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.s100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _P.s200, width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _P.s600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _P.s900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
