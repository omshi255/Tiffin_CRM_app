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
  static const v100 = Color(0xFFEDE9FE);
  static const s900 = Color(0xFF0F172A);
  static const s600 = Color(0xFF475569);
  static const s200 = Color(0xFFE2E8F0);
  static const s100 = Color(0xFFF8FAFC);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFF59E0B);
  static const grey = Color(0xFF94A3B8);
  static const red = Color(0xFFEF4444);
}

/// Full subscription window: info card + past / today / upcoming sections.
class DeliveriesTab extends StatefulWidget {
  const DeliveriesTab({super.key, required this.customerId});

  final String customerId;

  @override
  State<DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends State<DeliveriesTab> {
  CustomerDetailDeliveriesBundle? _bundle;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads subscription + all delivery days from the API.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final b = await CustomerDetailService.fetchDeliveries(widget.customerId);
      if (mounted) {
        setState(() {
          _bundle = b;
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

  static String _todayYmd() {
    final t = DateTime.now();
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
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
        final sub = _bundle?.subscription;
        final list = _bundle?.deliveries ?? [];
        final next = list.map((r) {
          final ry = r.date.length >= 10 ? r.date.substring(0, 10) : r.date;
          return ry == ymd
              ? CustomerDetailDeliveryRow(
                  date: r.date,
                  items: r.items,
                  status: 'cancelled',
                )
              : r;
        }).toList();
        _bundle = CustomerDetailDeliveriesBundle(
          subscription: sub,
          deliveries: next,
        );
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          e is ApiException ? (e.message ?? 'Error') : '$e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Shimmer.fromColors(
        baseColor: _P.s200,
        highlightColor: _P.s100,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              4,
              (_) => Padding(
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
          ],
        ),
      );
    }
    if (_error != null) {
      return CustomerDetailNetworkError(message: _error!, onRetry: _load);
    }

    final bundle = _bundle!;
    final sub = bundle.subscription;

    if (sub == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.subscriptions, size: 48, color: _P.s600),
              SizedBox(height: 12),
              Text(
                'No active subscription found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _P.s900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please assign a meal plan first',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _P.s600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final today = _todayYmd();
    final rows = bundle.deliveries;
    final past = <CustomerDetailDeliveryRow>[];
    CustomerDetailDeliveryRow? todayRow;
    final upcoming = <CustomerDetailDeliveryRow>[];

    for (final r in rows) {
      final y = r.date.length >= 10 ? r.date.substring(0, 10) : r.date;
      if (y.compareTo(today) < 0) {
        past.add(r);
      } else if (y == today) {
        todayRow = r;
      } else {
        upcoming.add(r);
      }
    }

    return RefreshIndicator(
      color: _P.g1,
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _SubscriptionCard(sub: sub)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _sectionTitle('Past Deliveries'),
            ),
          ),
          if (past.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No past days in this period.',
                  style: TextStyle(fontSize: 12, color: _P.s600),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _DeliveryRowCard(
                  row: past[i],
                  todayYmd: today,
                  isTodayHighlight: false,
                  onCancel: _confirmCancel,
                ),
                childCount: past.length,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: _sectionTitle('Today'),
            ),
          ),
          if (todayRow != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _DeliveryRowCard(
                  row: todayRow,
                  todayYmd: today,
                  isTodayHighlight: true,
                  onCancel: _confirmCancel,
                ),
              ),
            )
          else
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No row for today in this subscription window.',
                  style: TextStyle(fontSize: 12, color: _P.s600),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: _sectionTitle('Upcoming Deliveries'),
            ),
          ),
          if (upcoming.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No upcoming days.',
                  style: TextStyle(fontSize: 12, color: _P.s600),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _DeliveryRowCard(
                  row: upcoming[i],
                  todayYmd: today,
                  isTodayHighlight: false,
                  onCancel: _confirmCancel,
                ),
                childCount: upcoming.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

Widget _sectionTitle(String t) => Text(
      t,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: _P.s900,
      ),
    );

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.sub});

  final CustomerDetailDeliveriesSubscriptionInfo sub;

  String _fmt(String iso) {
    if (iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat.yMMMd().format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _P.s200, width: 0.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sub.planName.isEmpty ? 'Plan' : sub.planName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _P.s900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.date_range, size: 18, color: _P.g1),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_fmt(sub.startDate)} → ${_fmt(sub.endDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _P.s600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: _P.g1),
                const SizedBox(width: 8),
                Text(
                  'Total Days: ${sub.totalDays}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _P.s900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.hourglass_bottom, size: 18, color: _P.g1),
                const SizedBox(width: 8),
                Text(
                  'Remaining Days: ${sub.remainingDays}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _P.s900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryRowCard extends StatelessWidget {
  const _DeliveryRowCard({
    required this.row,
    required this.todayYmd,
    required this.isTodayHighlight,
    required this.onCancel,
  });

  final CustomerDetailDeliveryRow row;
  final String todayYmd;
  final bool isTodayHighlight;
  final Future<void> Function(CustomerDetailDeliveryRow) onCancel;

  @override
  Widget build(BuildContext context) {
    final cancelled = row.status == 'cancelled';
    final delivered = row.status == 'delivered';
    final pending = row.status == 'pending';

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

    final ymd = row.date.length >= 10 ? row.date.substring(0, 10) : row.date;
    final d = DateTime.tryParse(ymd);
    final dayLabel = d != null
        ? '${DateFormat.E().format(d)}\n${d.day}'
        : row.date;

    final isPast = ymd.compareTo(todayYmd) < 0;
    final canCancel = pending && !cancelled && !isPast;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isTodayHighlight ? _P.v100 : (cancelled ? Colors.grey.shade200 : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isTodayHighlight ? _P.g1 : _P.s200,
          width: isTodayHighlight ? 1.2 : 0.5,
        ),
      ),
      child: Opacity(
        opacity: cancelled ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  dayLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isTodayHighlight ? FontWeight.w900 : FontWeight.w700,
                    color: _P.s900,
                    height: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  row.items,
                  style: TextStyle(
                    fontSize: 12,
                    color: _P.s900,
                    fontWeight: isTodayHighlight ? FontWeight.w600 : FontWeight.w500,
                    decoration:
                        cancelled ? TextDecoration.lineThrough : TextDecoration.none,
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
                      icon: const Icon(Icons.cancel_outlined, size: 14),
                      label: const Text(
                        'Cancel Tiffin',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () => onCancel(row),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
