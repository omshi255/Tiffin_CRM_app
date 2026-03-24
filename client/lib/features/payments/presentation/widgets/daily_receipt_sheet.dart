import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../data/invoice_api.dart';

/// Per-day meal receipt preview (GET /invoices/daily).
class DailyReceiptSheet extends StatefulWidget {
  const DailyReceiptSheet({
    super.key,
    required this.customerId,
    required this.initialDate,
  });

  final String customerId;
  final DateTime initialDate;

  @override
  State<DailyReceiptSheet> createState() => _DailyReceiptSheetState();
}

class _DailyReceiptSheetState extends State<DailyReceiptSheet> {
  late DateTime _date;
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _failed = false;

  static final _df = DateFormat('dd/MM/yyyy');
  static final _dfApi = DateFormat('yyyy-MM-dd');
  static final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final m = await InvoiceApi.getDailyReceipt(
        customerId: widget.customerId,
        date: _date,
      );
      if (mounted) setState(() => _data = m);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevDay() {
    setState(() => _date = _date.subtract(const Duration(days: 1)));
    _fetch();
  }

  void _nextDay() {
    setState(() => _date = _date.add(const Duration(days: 1)));
    _fetch();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _date = d);
      _fetch();
    }
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: mq.viewInsets.bottom + mq.padding.bottom + 12,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Daily receipt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_failed)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Could not load receipt.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _fetch,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _dateNav(),
                      const SizedBox(height: 16),
                      _receiptBody(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => AppSnackbar.info(
                                context,
                                'Coming soon',
                              ),
                              child: const Text('Download PDF'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => AppSnackbar.info(
                                context,
                                'Coming soon',
                              ),
                              child: const Text('Share WhatsApp'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _dateNav() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _prevDay,
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Prev'),
        ),
        Expanded(
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _df.format(_date),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _nextDay,
          icon: const Icon(Icons.chevron_right_rounded),
          label: const Text('Next'),
        ),
      ],
    );
  }

  Widget _receiptBody() {
    final d = _data;
    if (d == null) return const SizedBox.shrink();

    final cust = d['customer'];
    String name = '—';
    String phone = '—';
    String addr = '—';
    if (cust is Map) {
      name = cust['name']?.toString() ?? name;
      phone = cust['phone']?.toString() ?? phone;
      addr = cust['address']?.toString() ?? addr;
    }

    final dateStr = d['date']?.toString() ?? _dfApi.format(_date);
    final deliveries = (d['deliveries'] is List) ? d['deliveries'] as List : [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Company',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text(
            dateStr,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(height: 24),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(phone, style: const TextStyle(fontSize: 12)),
          Text(addr, style: const TextStyle(fontSize: 12)),
          const Divider(height: 24),
          for (final slot in deliveries) ...[
            if (slot is Map) ...[
              Text(
                '${slot['slot'] ?? 'Meal'}'.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              _itemsTable(slot['items']),
              const SizedBox(height: 12),
            ],
          ],
          const Divider(),
          _line('Subtotal', _num(d['subtotal'])),
          _line('Tax', _num(d['tax'])),
          _line('Grand Total', _num(d['grandTotal']), bold: true),
          const Divider(),
          _line('Paid', _num(d['paidAmount'])),
          _line('Balance Due', _num(d['dueAmount'])),
          _line('Running balance', _num(d['runningBalance'])),
        ],
      ),
    );
  }

  Widget _itemsTable(dynamic raw) {
    if (raw is! List || raw.isEmpty) {
      return const Text('—', style: TextStyle(fontSize: 12));
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          children: [
            _cell('Item', h: true),
            _cell('Qty', h: true),
            _cell('Total', h: true),
          ],
        ),
        ...raw.map((e) {
          if (e is! Map) return TableRow(children: [const SizedBox(), const SizedBox(), const SizedBox()]);
          final name = e['name']?.toString() ?? '—';
          final q = e['quantity'] ?? '—';
          final t = _num(e['total']);
          return TableRow(
            children: [
              _cell(name),
              _cell('$q'),
              _cell(_money.format(t)),
            ],
          );
        }),
      ],
    );
  }

  Widget _cell(String t, {bool h = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        t,
        style: TextStyle(
          fontSize: h ? 11 : 12,
          fontWeight: h ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _line(String label, double v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            _money.format(v),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
