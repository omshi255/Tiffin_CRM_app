import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../models/customer_detail_delivery_model.dart';
import '../../../services/customer_detail_service.dart';

import 'customer_info_tab.dart';

class _P {
  static const g1 = Color(0xFF7B3FE4);
  static const s900 = Color(0xFF0F172A);
  static const s600 = Color(0xFF475569);
  static const s200 = Color(0xFFE2E8F0);
  static const s100 = Color(0xFFF8FAFC);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFF59E0B);
  static const grey = Color(0xFF94A3B8);
  static const red = Color(0xFFEF4444);
}

/// Month-scoped delivery list with cancel for upcoming days.
class DeliveriesTab extends StatefulWidget {
  const DeliveriesTab({super.key, required this.customerId});

  final String customerId;

  @override
  State<DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends State<DeliveriesTab> {
  late DateTime _month;
  List<CustomerDetailDeliveryRow> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _load();
  }

  /// Fetches deliveries for the visible month.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await CustomerDetailService.fetchDeliveries(
        widget.customerId,
        month: _month.month,
        year: _month.year,
      );
      if (mounted) {
        setState(() {
          _rows = list;
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

  void _prevMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1);
    });
    _load();
  }

  void _nextMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month + 1);
    });
    _load();
  }

  bool _isTodayOrFuture(String ymd) {
    final d = DateTime.tryParse(ymd.length >= 10 ? ymd.substring(0, 10) : ymd);
    if (d == null) return false;
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final rowDay = DateTime(d.year, d.month, d.day);
    return !rowDay.isBefore(today);
  }

  Future<void> _confirmCancel(CustomerDetailDeliveryRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber, color: _P.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cancel delivery',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Cancel tiffin for ${row.date}? This cannot be undone.',
          style: const TextStyle(fontSize: 13, color: _P.s600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _P.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final ymd = row.date.length >= 10 ? row.date.substring(0, 10) : row.date;
    try {
      await CustomerDetailService.cancelDelivery(widget.customerId, ymd);
      if (!mounted) return;
      AppSnackbar.success(context, 'Delivery cancelled');
      setState(() {
        _rows = _rows
            .map(
              (r) => r.date == row.date
                  ? CustomerDetailDeliveryRow(
                      date: r.date,
                      items: r.items,
                      status: 'cancelled',
                    )
                  : r,
            )
            .toList();
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e is ApiException ? (e.message ?? 'Error') : '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat.yMMMM().format(_month);

    if (_loading) {
      return Shimmer.fromColors(
        baseColor: _P.s200,
        highlightColor: _P.s100,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 64,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _prevMonth,
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _P.s900,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),
        Expanded(
          child: _rows.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delivery_dining, size: 48, color: _P.s600),
                      SizedBox(height: 8),
                      Text(
                        'No deliveries this month',
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
                    itemCount: _rows.length,
                    itemBuilder: (context, i) {
                      final r = _rows[i];
                      final cancelled = r.status == 'cancelled';
                      final delivered = r.status == 'delivered';
                      final pending = r.status == 'pending';

                      IconData stIcon;
                      Color stColor;
                      String stLabel;
                      if (delivered) {
                        stIcon = Icons.check_circle;
                        stColor = _P.green;
                        stLabel = 'Delivered';
                      } else if (cancelled) {
                        stIcon = Icons.cancel;
                        stColor = _P.grey;
                        stLabel = 'Cancelled';
                      } else {
                        stIcon = Icons.schedule;
                        stColor = _P.orange;
                        stLabel = 'Pending';
                      }

                      final ymd = r.date.length >= 10
                          ? r.date.substring(0, 10)
                          : r.date;
                      final d = DateTime.tryParse(ymd);
                      final dayLabel = d != null
                          ? '${DateFormat.E().format(d)}\n${d.day}'
                          : r.date;

                      final canCancel = pending &&
                          _isTodayOrFuture(ymd) &&
                          !cancelled;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: cancelled
                            ? Colors.grey.shade200
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _P.s200, width: 0.5),
                        ),
                        child: Opacity(
                          opacity: cancelled ? 0.5 : 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    dayLabel,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _P.s900,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    r.items,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _P.s900,
                                      decoration: cancelled
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(stIcon, size: 16, color: stColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          stLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: stColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (canCancel) ...[
                                      const SizedBox(height: 6),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _P.red,
                                          side: const BorderSide(color: _P.red),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'Cancel',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        onPressed: () => _confirmCancel(r),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
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
}
