// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:shimmer/shimmer.dart';

// import '../../../core/network/api_exception.dart';
// import '../../../models/customer_detail_subscription_model.dart';
// import '../../../services/customer_detail_service.dart';

// import 'customer_info_tab.dart';

// class _P {
//   static const g1 = Color(0xFF7B3FE4);
//   static const s900 = Color(0xFF0F172A);
//   static const s600 = Color(0xFF475569);
//   static const s200 = Color(0xFFE2E8F0);
//   static const s100 = Color(0xFFF8FAFC);
//   static const green = Color(0xFF22C55E);
// }

// /// Active plan summary and past subscriptions list.
// class MealPlanTab extends StatefulWidget {
//   const MealPlanTab({super.key, required this.customerId});

//   final String customerId;

//   @override
//   State<MealPlanTab> createState() => _MealPlanTabState();
// }

// class _MealPlanTabState extends State<MealPlanTab> {
//   CustomerDetailSubscriptionsBundle? _data;
//   bool _loading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   /// Loads subscriptions bundle from the API.
//   Future<void> _load() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       final d = await CustomerDetailService.fetchSubscriptions(widget.customerId);
//       if (mounted) {
//         setState(() {
//           _data = d;
//           _loading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _loading = false;
//           _error = e is ApiException ? (e.message ?? 'Error') : '$e';
//         });
//       }
//     }
//   }

//   String _fmt(String iso) {
//     if (iso.isEmpty) return '—';
//     final d = DateTime.tryParse(iso);
//     if (d == null) return iso;
//     return DateFormat.yMMMd().format(d.toLocal());
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return Shimmer.fromColors(
//         baseColor: _P.s200,
//         highlightColor: _P.s100,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             Container(
//               height: 180,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//     if (_error != null) {
//       return CustomerDetailNetworkError(message: _error!, onRetry: _load);
//     }

//     final bundle = _data!;
//     final active = bundle.activePlan;

//     return RefreshIndicator(
//       color: _P.g1,
//       onRefresh: _load,
//       child: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           if (active != null)
//             Card(
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 side: const BorderSide(color: _P.s200, width: 0.5),
//               ),
//               color: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.all(14),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Active Plan',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                         color: _P.s900,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     _row(Icons.star, 'Plan', active.planName),
//                     _row(Icons.fastfood, 'Items / day', '${active.itemsPerDay}'),
//                     _row(
//                       Icons.currency_rupee,
//                       'Price / month',
//                       '₹${active.pricePerMonth.toStringAsFixed(0)}',
//                     ),
//                     _row(
//                       Icons.date_range,
//                       'Period',
//                       '${_fmt(active.startDate)} — ${_fmt(active.endDate)}',
//                     ),
//                     _row(
//                       Icons.hourglass_bottom,
//                       'Remaining days',
//                       '${active.remainingDays}',
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           else
//             const Padding(
//               padding: EdgeInsets.only(bottom: 12),
//               child: Text(
//                 'No active plan',
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: _P.s600,
//                 ),
//               ),
//             ),
//           const Divider(height: 24),
//           const Text(
//             'Subscription History',
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w700,
//               color: _P.s900,
//             ),
//           ),
//           const SizedBox(height: 8),
//           if (bundle.history.isEmpty)
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 32),
//               child: Column(
//                 children: const [
//                   Icon(Icons.inbox, size: 48, color: _P.s600),
//                   SizedBox(height: 8),
//                   Text(
//                     'No past subscriptions',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: _P.s600,
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           else
//             ...bundle.history.map(
//               (h) => Card(
//                 margin: const EdgeInsets.only(bottom: 8),
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   side: const BorderSide(color: _P.s200, width: 0.5),
//                 ),
//                 color: Colors.white,
//                 child: ListTile(
//                   leading: const Icon(Icons.history, color: _P.g1),
//                   title: Text(
//                     h.planName,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w700,
//                       fontSize: 13,
//                       color: _P.s900,
//                     ),
//                   ),
//                   subtitle: Text(
//                     '${_fmt(h.startDate)} — ${_fmt(h.endDate)}\n₹${h.amountPaid.toStringAsFixed(0)}',
//                     style: const TextStyle(fontSize: 11, color: _P.s600),
//                   ),
//                   isThreeLine: true,
//                   trailing: h.completed
//                       ? const Icon(Icons.check_circle, color: _P.green)
//                       : null,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _row(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 18, color: _P.g1),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                     color: _P.s600,
//                   ),
//                 ),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: _P.s900,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/subscription_calendar_days.dart';
import '../../../models/customer_detail_subscription_model.dart';
import '../../../services/customer_detail_service.dart';
import 'customer_info_tab.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
class _C {
  static const primary   = Color(0xFF7B3FE4);
  static const primaryBg = Color(0xFFF3EDFD);
  static const s900      = Color(0xFF0F172A);
  static const s600      = Color(0xFF475569);
  static const s200      = Color(0xFFE2E8F0);
  static const s100      = Color(0xFFF1F5F9);
  static const s50       = Color(0xFFF8FAFC);
  static const green     = Color(0xFF16A34A);
  static const greenBg   = Color(0xFFDCFCE7);
}

// ── Tab root ──────────────────────────────────────────────────────────────────
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await CustomerDetailService.fetchSubscriptions(widget.customerId);
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e is ApiException ? (e.message ?? 'Error') : '$e';
      });
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
    if (_loading) return const _Skeleton();
    if (_error != null) {
      return CustomerDetailNetworkError(message: _error!, onRetry: _load);
    }

    final bundle = _data!;
    final active = bundle.activePlan;

    return RefreshIndicator(
      color: _C.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Active plan ──────────────────────────────────────────────────
          if (active != null) ...[
            _ActivePlanHeader(plan: active, fmt: _fmt),
            const SizedBox(height: 8),
            _ActivePlanFields(plan: active, fmt: _fmt),
          ] else
            _EmptyActivePlan(),

          const SizedBox(height: 20),

          // ── History heading ──────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'Subscription history',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.s900,
                ),
              ),
              const SizedBox(width: 8),
              if (bundle.history.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _C.primaryBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${bundle.history.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _C.primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (bundle.history.isEmpty)
            const _EmptyHistory()
          else
            _HistoryList(items: bundle.history, fmt: _fmt),
        ],
      ),
    );
  }
}

// ── Active plan header card ───────────────────────────────────────────────────
class _ActivePlanHeader extends StatelessWidget {
  const _ActivePlanHeader({required this.plan, required this.fmt});

  final CustomerDetailActivePlan plan;
  final String Function(String) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.s200, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.primaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: _C.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.planName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _C.s900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${plan.pricePerMonth.toStringAsFixed(0)} / month',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.greenBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _C.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _C.green,
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

// ── Active plan field rows ────────────────────────────────────────────────────
class _ActivePlanFields extends StatelessWidget {
  const _ActivePlanFields({required this.plan, required this.fmt});

  final CustomerDetailActivePlan plan;
  final String Function(String) fmt;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(plan.startDate);
    final end = DateTime.tryParse(plan.endDate);
    final int displayRemaining = (start != null && end != null)
        ? remainingDaysInclusiveIST(start, end)
        : plan.remainingDays;
    final bool lowDays = displayRemaining <= 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.s200, width: 0.5),
      ),
      child: Column(
        children: [
          _FieldRow(
            icon: Icons.fastfood_rounded,
            label: 'Items per day',
            value: '${plan.itemsPerDay}',
          ),
          const Divider(height: 1, thickness: 0.5, indent: 44, color: _C.s100),
          _FieldRow(
            icon: Icons.date_range_rounded,
            label: 'Period',
            value: '${fmt(plan.startDate)} – ${fmt(plan.endDate)}',
          ),
          const Divider(height: 1, thickness: 0.5, indent: 44, color: _C.s100),
          _FieldRow(
            icon: Icons.hourglass_bottom_rounded,
            label: 'Days remaining',
            value: '$displayRemaining',
            valueColor: lowDays ? Colors.orange.shade700 : _C.primary,
          ),
        ],
      ),
    );
  }
}

// ── Generic label → value row ─────────────────────────────────────────────────
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = _C.s900,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _C.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: _C.s600)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── History list ──────────────────────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.items, required this.fmt});

  final List<CustomerDetailSubscriptionHistoryItem> items;
  final String Function(String) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.s200, width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _HistoryRow(item: items[i], fmt: fmt),
            if (i < items.length - 1)
              const Divider(
                height: 1,
                thickness: 0.5,
                indent: 44,
                color: _C.s100,
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.fmt});

  final CustomerDetailSubscriptionHistoryItem item;
  final String Function(String) fmt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 16, color: _C.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.planName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.s900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fmt(item.startDate)} – ${fmt(item.endDate)}',
                  style: const TextStyle(fontSize: 11, color: _C.s600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.amountPaid.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.s900,
                ),
              ),
              if (item.completed) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_rounded,
                        size: 12, color: _C.green),
                    SizedBox(width: 3),
                    Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _C.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────
class _EmptyActivePlan extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.s50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.s200, width: 0.5),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline_rounded, size: 16, color: _C.s600),
          SizedBox(width: 10),
          Text(
            'No active plan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.s600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: const [
          Icon(Icons.history_rounded, size: 40, color: _C.s200),
          SizedBox(height: 10),
          Text(
            'No past subscriptions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.s600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer skeleton ──────────────────────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _C.s200,
      highlightColor: _C.s50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _box(h: 64),
          const SizedBox(height: 8),
          _box(h: 130),
          const SizedBox(height: 20),
          _box(h: 16, w: 140),
          const SizedBox(height: 10),
          _box(h: 170),
        ],
      ),
    );
  }

  Widget _box({required double h, double? w}) => Container(
        width: w,
        height: h,
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      );
}