import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/network/api_exception.dart';
import '../../../models/customer_detail_subscription_model.dart';
import '../../../services/customer_detail_service.dart';

import 'customer_info_tab.dart';

class _P {
  static const g1 = Color(0xFF7B3FE4);
  static const s900 = Color(0xFF0F172A);
  static const s600 = Color(0xFF475569);
  static const s200 = Color(0xFFE2E8F0);
  static const s100 = Color(0xFFF8FAFC);
  static const green = Color(0xFF22C55E);
}

/// Active plan summary and past subscriptions list.
class MealPlanTab extends StatefulWidget {
  const MealPlanTab({super.key, required this.customerId});

  final String customerId;

  @override
  State<MealPlanTab> createState() => _MealPlanTabState();
}

class _MealPlanTabState extends State<MealPlanTab> {
  CustomerDetailSubscriptionsBundle? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads subscriptions bundle from the API.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await CustomerDetailService.fetchSubscriptions(widget.customerId);
      if (mounted) {
        setState(() {
          _data = d;
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

  String _fmt(String iso) {
    if (iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat.yMMMd().format(d.toLocal());
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
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return CustomerDetailNetworkError(message: _error!, onRetry: _load);
    }

    final bundle = _data!;
    final active = bundle.activePlan;

    return RefreshIndicator(
      color: _P.g1,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (active != null)
            Card(
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
                    const Text(
                      'Active Plan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _P.s900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _row(Icons.star, 'Plan', active.planName),
                    _row(Icons.fastfood, 'Items / day', '${active.itemsPerDay}'),
                    _row(
                      Icons.currency_rupee,
                      'Price / month',
                      '₹${active.pricePerMonth.toStringAsFixed(0)}',
                    ),
                    _row(
                      Icons.date_range,
                      'Period',
                      '${_fmt(active.startDate)} — ${_fmt(active.endDate)}',
                    ),
                    _row(
                      Icons.hourglass_bottom,
                      'Remaining days',
                      '${active.remainingDays}',
                    ),
                  ],
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'No active plan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _P.s600,
                ),
              ),
            ),
          const Divider(height: 24),
          const Text(
            'Subscription History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _P.s900,
            ),
          ),
          const SizedBox(height: 8),
          if (bundle.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: const [
                  Icon(Icons.inbox, size: 48, color: _P.s600),
                  SizedBox(height: 8),
                  Text(
                    'No past subscriptions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _P.s600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...bundle.history.map(
              (h) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: _P.s200, width: 0.5),
                ),
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.history, color: _P.g1),
                  title: Text(
                    h.planName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _P.s900,
                    ),
                  ),
                  subtitle: Text(
                    '${_fmt(h.startDate)} — ${_fmt(h.endDate)}\n₹${h.amountPaid.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: _P.s600),
                  ),
                  isThreeLine: true,
                  trailing: h.completed
                      ? const Icon(Icons.check_circle, color: _P.green)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _P.g1),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _P.s600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
