import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  const TransactionsTab({super.key, required this.customerId});

  final String customerId;

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  List<CustomerDetailTransaction> _all = [];
  bool _loading = true;
  String? _error;
  int _filter = 0; // 0 all, 1 today, 2 week, 3 custom
  DateTimeRange? _customRange;

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
      final list = await CustomerDetailService.fetchTransactions(
        widget.customerId,
        startDate: range.$1,
        endDate: range.$2,
      );
      if (mounted) {
        setState(() {
          _all = list;
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
      case 3:
        if (_customRange != null) {
          final a = _customRange!.start;
          final b = DateTime(
            _customRange!.end.year,
            _customRange!.end.month,
            _customRange!.end.day,
            23,
            59,
            59,
            999,
          );
          return (a.toUtc().toIso8601String(), b.toUtc().toIso8601String());
        }
        return (null, null);
      default:
        return (null, null);
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
    );
    if (range != null) {
      setState(() {
        _filter = 3;
        _customRange = range;
      });
      await _load();
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

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(Icons.date_range, color: _P.g1),
                tooltip: 'Custom range',
                onPressed: _pickRange,
              ),
            ],
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
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: _all.length,
                    itemBuilder: (context, i) {
                      final t = _all[i];
                      final credit = t.type == 'credit';
                      final amtColor = credit ? _P.green : _P.red;
                      final icon = credit
                          ? Icons.arrow_circle_down
                          : Icons.arrow_circle_up;
                      final dt = DateTime.tryParse(t.date);
                      final dateStr = dt != null
                          ? DateFormat.yMMMd().add_jm().format(dt.toLocal())
                          : t.date;
                      return Card(
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
                                t.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _P.s600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${credit ? '+' : '-'}₹${t.amount.toStringAsFixed(0)}',
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
                                      credit ? 'Credit' : 'Debit',
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
                      );
                    },
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
