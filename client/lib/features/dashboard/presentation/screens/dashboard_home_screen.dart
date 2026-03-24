// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/network/api_endpoints.dart';
// import '../../../../core/network/dio_client.dart';
// import '../../../../core/router/app_routes.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/widgets/section_header.dart';
// import '../../../customers/data/customer_api.dart';
// import '../../../delivery/data/delivery_api.dart';
// import '../../../orders/data/order_api.dart';
// import '../../../payments/data/payment_api.dart';

// class DashboardHomeScreen extends StatefulWidget {
//   const DashboardHomeScreen({super.key, this.adminName = 'Vendor'});

//   final String adminName;

//   @override
//   State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
// }

// class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
//   bool _loading = true;
//   int _customersCount = 0;
//   int _ordersCount = 0;
//   int _deliveryStaffCount = 0;
//   double _revenue = 0;

//   static String _greeting() {
//     final hour = DateTime.now().hour;
//     if (hour < 12) return 'Good Morning';
//     if (hour < 17) return 'Good Afternoon';
//     return 'Good Evening';
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadStats();
//   }

//   Future<void> _loadStats() async {
//     setState(() => _loading = true);
//     int customersCount = 0;
//     int ordersCount = 0;
//     int deliveryCount = 0;
//     double revenue = 0;

//     try {
//       final res = await CustomerApi.list(page: 1, limit: 1);
//       final total = res['total'];
//       if (total is num) {
//         customersCount = total.toInt();
//       } else {
//         customersCount = res['data'] is List ? (res['data'] as List).length : 0;
//       }
//     } catch (_) {
//       customersCount = 0;
//     }
//     if (mounted) setState(() => _customersCount = customersCount);

//     try {
//       final orders = await OrderApi.getToday();
//       ordersCount = orders.length;
//     } catch (_) {
//       ordersCount = 0;
//     }
//     if (mounted) setState(() => _ordersCount = ordersCount);

//     try {
//       final response = await DioClient.instance.get(
//         ApiEndpoints.deliveryStaff,
//         queryParameters: {'page': 1, 'limit': 1},
//       );
//       final data = parseData(response);
//       if (data is Map<String, dynamic> && data['total'] is num) {
//         deliveryCount = (data['total'] as num).toInt();
//       } else {
//         final staff = await DeliveryApi.listStaff(page: 1, limit: 500);
//         deliveryCount = staff.length;
//       }
//     } catch (_) {
//       try {
//         final staff = await DeliveryApi.listStaff(page: 1, limit: 500);
//         deliveryCount = staff.length;
//       } catch (_) {
//         deliveryCount = 0;
//       }
//     }
//     if (mounted) setState(() => _deliveryStaffCount = deliveryCount);

//     try {
//       var page = 1;
//       while (page <= 40) {
//         final list = await PaymentApi.list(page: page, limit: 100);
//         for (final p in list) {
//           revenue += p.amount;
//         }
//         if (list.length < 100) break;
//         page++;
//       }
//     } catch (_) {
//       revenue = 0;
//     }
//     if (mounted) {
//       setState(() {
//         _revenue = revenue;
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return RefreshIndicator(
//       color: AppColors.primary,
//       onRefresh: _loadStats,
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               '${_greeting()}, ${widget.adminName} 👋',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.w700,
//                 color: AppColors.textPrimary,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 20),

//             const SectionHeader(title: 'Overview'),
//             const SizedBox(height: 8),

//             if (_loading) _buildShimmer() else _buildStatsGrid(),

//             const SizedBox(height: 24),
//             const SectionHeader(title: 'Quick actions'),
//             const SizedBox(height: 12),

//             Row(
//               children: [
//                 Expanded(
//                   child: _QuickActionTile(
//                     icon: Icons.person_add,
//                     label: 'Add Customer',
//                     onTap: () => context.push(AppRoutes.addCustomer),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _QuickActionTile(
//                     icon: Icons.assignment_outlined,
//                     label: 'Assign Plan',
//                     onTap: () => context.push(AppRoutes.planAssignments),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 12),

//             Row(
//               children: [
//                 Expanded(
//                   child: _QuickActionTile(
//                     icon: Icons.delivery_dining,
//                     label: 'Delivery',
//                     onTap: () => context.push(AppRoutes.delivery),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _QuickActionTile(
//                     icon: Icons.payment,
//                     label: 'Payments',
//                     onTap: () => context.push(AppRoutes.payments),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildShimmer() {
//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       mainAxisSpacing: 12,
//       crossAxisSpacing: 12,
//       childAspectRatio: 1.35,
//       children: List.generate(4, (_) => const _ShimmerCard()),
//     );
//   }

//   Widget _buildStatsGrid() {
//     return GridView.count(
//       crossAxisCount: 2,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       mainAxisSpacing: 12,
//       crossAxisSpacing: 12,
//       childAspectRatio: 1.35,
//       children: [
//         _DashboardStatCard(
//           label: 'Total customers',
//           value: _customersCount,
//           isRevenue: false,
//         ),
//         _DashboardStatCard(
//           label: "Today's orders",
//           value: _ordersCount,
//           isRevenue: false,
//         ),
//         _DashboardStatCard(
//           label: 'Delivery staff',
//           value: _deliveryStaffCount,
//           isRevenue: false,
//         ),
//         _DashboardStatCard(
//           label: 'Revenue (₹)',
//           value: _revenue.toInt(),
//           isRevenue: true,
//         ),
//       ],
//     );
//   }
// }

// class _ShimmerCard extends StatelessWidget {
//   const _ShimmerCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.border),
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 36,
//             height: 28,
//             decoration: BoxDecoration(
//               color: AppColors.shimmerBase,
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             width: 72,
//             height: 20,
//             decoration: BoxDecoration(
//               color: AppColors.shimmerBase,
//               borderRadius: BorderRadius.circular(6),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             width: 100,
//             height: 14,
//             decoration: BoxDecoration(
//               color: AppColors.shimmerHighlight,
//               borderRadius: BorderRadius.circular(4),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DashboardStatCard extends StatelessWidget {
//   const _DashboardStatCard({
//     required this.label,
//     required this.value,
//     required this.isRevenue,
//   });

//   final String label;
//   final int value;
//   final bool isRevenue;

//   @override
//   Widget build(BuildContext context) {
//     final positive = value > 0;
//     final IconData icon;
//     final Color iconColor;
//     if (isRevenue) {
//       icon = positive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
//       iconColor = positive ? AppColors.trendUp : AppColors.trendDown;
//     } else {
//       icon = positive ? Icons.trending_up_rounded : Icons.trending_flat_rounded;
//       iconColor = positive ? AppColors.trendUp : AppColors.textHint;
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.cardBackground,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.border),
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Text(
//                   _formatValue(),
//                   style: const TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.primary,
//                     height: 1.1,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Icon(icon, size: 22, color: iconColor),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 13,
//               color: AppColors.textSecondary,
//               fontWeight: FontWeight.w500,
//             ),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatValue() {
//     if (!isRevenue) return value.toString();
//     if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
//     if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
//     if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}k';
//     return '₹$value';
//   }
// }

// class _QuickActionTile extends StatelessWidget {
//   const _QuickActionTile({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });

//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(14),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, size: 32, color: AppColors.primary),
//               const SizedBox(height: 8),
//               Text(
//                 label,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.textPrimary,
//                     ),
//                 textAlign: TextAlign.center,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customers/data/customer_api.dart';
import '../../../delivery/data/delivery_api.dart';
import '../../../orders/data/order_api.dart';
import '../../../payments/data/payment_api.dart';
import '../../../payments/models/payment_model.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key, this.adminName = 'Vendor'});
  final String adminName;

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  bool _loading = true;
  int _customersCount = 0;
  int _ordersCount = 0;
  int _deliveryStaffCount = 0;
  double _revenue = 0;
  List<PaymentModel> _recentPayments = [];

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String _todayDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    int customersCount = 0;
    int ordersCount = 0;
    int deliveryCount = 0;
    double revenue = 0;

    try {
      final res = await CustomerApi.list(page: 1, limit: 1);
      final total = res['total'];
      if (total is num) {
        customersCount = total.toInt();
      } else {
        customersCount = res['data'] is List ? (res['data'] as List).length : 0;
      }
    } catch (_) {}
    if (mounted) setState(() => _customersCount = customersCount);

    try {
      final orders = await OrderApi.getToday();
      ordersCount = orders.length;
    } catch (_) {}
    if (mounted) setState(() => _ordersCount = ordersCount);

    try {
      final response = await DioClient.instance.get(
        ApiEndpoints.deliveryStaff,
        queryParameters: {'page': 1, 'limit': 1},
      );
      final data = parseData(response);
      if (data is Map<String, dynamic> && data['total'] is num) {
        deliveryCount = (data['total'] as num).toInt();
      } else {
        final staff = await DeliveryApi.listStaff(page: 1, limit: 500);
        deliveryCount = staff.length;
      }
    } catch (_) {
      try {
        final staff = await DeliveryApi.listStaff(page: 1, limit: 500);
        deliveryCount = staff.length;
      } catch (_) {}
    }
    if (mounted) setState(() => _deliveryStaffCount = deliveryCount);

    try {
      var page = 1;
      while (page <= 40) {
        final result = await PaymentApi.list(page: page, limit: 100);
        for (final p in result.items) {
          revenue += p.amount;
        }
        if (page >= result.totalPages || result.items.isEmpty) break;
        page++;
      }
    } catch (_) {}
    if (mounted) setState(() { _revenue = revenue; _loading = false; });

    try {
      final payments = await PaymentApi.list(page: 1, limit: 5);
      if (mounted) setState(() => _recentPayments = payments.items);
    } catch (_) {}
  }

  String _formatRevenue(int value) {
    if (value >= 10000000) return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000)   return '₹${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000)     return '₹${(value / 1000).toStringAsFixed(1)}k';
    return '₹$value';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Greeting + Date pill ─────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()},',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.adminName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _todayDate(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Date pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Text('TODAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1)),
                      Text(DateTime.now().day.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary, height: 1.1)),
                      Text(
                        const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][DateTime.now().month - 1],
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Revenue Hero Card ────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B2D8E), Color(0xFF3B1578)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50, right: -50,
                    child: Container(width: 150, height: 150,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 2)),
                    ),
                  ),
                  Positioned(
                    top: -20, right: -20,
                    child: Container(width: 90, height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 2)),
                    ),
                  ),
                  Positioned(
                    bottom: -30, left: 20,
                    child: Container(width: 90, height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 2)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('TOTAL REVENUE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.55), letterSpacing: 0.8)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34D399).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.arrow_upward_rounded, color: Color(0xFF6EE7B7), size: 10),
                                SizedBox(width: 3),
                                Text('+12%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6EE7B7))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_loading)
                        Container(width: 140, height: 48,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)))
                      else
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(_formatRevenue(_revenue.toInt()),
                            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                        ),
                      const SizedBox(height: 8),
                      Text('Updated just now',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Overview 3 stat cards ─────────────────────────
            const _SectionLabel(label: 'Overview'),
            const SizedBox(height: 10),

            if (_loading)
              Row(
                children: List.generate(3, (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
                    child: const _ShimmerCard(),
                  ),
                )),
              )
            else
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Customers', value: _customersCount.toString(), icon: Icons.people_outline_rounded, iconBg: AppColors.primary.withValues(alpha: 0.08), iconColor: AppColors.primary, valueColor: AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Orders', value: _ordersCount.toString(), icon: Icons.receipt_long_outlined, iconBg: const Color(0xFF1D9E75).withValues(alpha: 0.08), iconColor: const Color(0xFF1D9E75), valueColor: const Color(0xFF1D9E75))),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Delivery', value: _deliveryStaffCount.toString(), icon: Icons.delivery_dining_outlined, iconBg: const Color(0xFFBA7517).withValues(alpha: 0.08), iconColor: const Color(0xFFBA7517), valueColor: const Color(0xFFBA7517))),
                ],
              ),

            const SizedBox(height: 20),

            // ── Quick Actions 2x2 ────────────────────────────
            const _SectionLabel(label: 'Quick Actions'),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: _QuickActionTile(icon: Icons.person_add_outlined, label: 'Add Customer', subtitle: 'Register new', iconBg: AppColors.primary.withValues(alpha: 0.08), iconColor: AppColors.primary, onTap: () => context.push(AppRoutes.addCustomer))),
                const SizedBox(width: 10),
                Expanded(child: _QuickActionTile(icon: Icons.assignment_outlined, label: 'Assign Plan', subtitle: 'Set meal plan', iconBg: const Color(0xFF1D9E75).withValues(alpha: 0.08), iconColor: const Color(0xFF1D9E75), onTap: () => context.push(AppRoutes.planAssignments))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _QuickActionTile(icon: Icons.delivery_dining_outlined, label: 'Delivery', subtitle: 'Track orders', iconBg: const Color(0xFFBA7517).withValues(alpha: 0.08), iconColor: const Color(0xFFBA7517), onTap: () => context.push(AppRoutes.delivery))),
                const SizedBox(width: 10),
                Expanded(child: _QuickActionTile(icon: Icons.payment_outlined, label: 'Payments', subtitle: 'Collect & track', iconBg: const Color(0xFFA32D2D).withValues(alpha: 0.08), iconColor: const Color(0xFFA32D2D), onTap: () => context.push(AppRoutes.payments))),
              ],
            ),

            const SizedBox(height: 20),

            // ── Recent Activity ──────────────────────────────
            Row(
              children: [
                const Expanded(child: _SectionLabel(label: 'Recent Activity')),
                TextButton(
                  onPressed: () => context.push(AppRoutes.payments),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('See all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_loading)
              Container(height: 120,
                decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: const Center(child: CircularProgressIndicator()))
            else if (_recentPayments.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Column(children: [
                  Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textHint),
                  const SizedBox(height: 8),
                  Text('No recent activity', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ]),
              )
            else
              Container(
                decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentPayments.length,
                  // ignore: unnecessary_underscores
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final p = _recentPayments[index];
                    final name = p.customerName ?? p.customerId;
                    final initials = name.isNotEmpty
                        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
                        : '?';
                    final date = p.paymentDate != null
                        ? '${p.paymentDate!.day}/${p.paymentDate!.month}/${p.paymentDate!.year}'
                        : '—';
                    final method = p.paymentMethod.replaceAll('_', ' ').split(' ')
                        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Container(width: 40, height: 40,
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(initials, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('$method · $date', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('+₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1D9E75))),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF1D9E75).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: const Text('Paid', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0F6E56))),
                          ),
                        ]),
                      ]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.8));
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.iconBg, required this.iconColor, required this.valueColor});
  final String label, value;
  final IconData icon;
  final Color iconBg, iconColor, valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: iconColor)),
        const SizedBox(height: 10),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: valueColor, height: 1))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ── Shimmer Card ──────────────────────────────────────────────────────────────
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.shimmerBase, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 10),
        Container(width: 40, height: 22, decoration: BoxDecoration(color: AppColors.shimmerBase, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 6),
        Container(width: 60, height: 12, decoration: BoxDecoration(color: AppColors.shimmerHighlight, borderRadius: BorderRadius.circular(4))),
      ]),
    );
  }
}

// ── Quick Action Tile ─────────────────────────────────────────────────────────
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.label, required this.subtitle, required this.iconBg, required this.iconColor, required this.onTap});
  final IconData icon;
  final String label, subtitle;
  final Color iconBg, iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)), child: Icon(icon, size: 22, color: iconColor)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }
}