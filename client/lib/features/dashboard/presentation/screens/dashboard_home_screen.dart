import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../customers/data/customer_api.dart';
import '../../../delivery/data/delivery_api.dart';
import '../../../orders/data/order_api.dart';
import '../../../payments/data/payment_api.dart';

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

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
    } catch (_) {
      customersCount = 0;
    }
    if (mounted) setState(() => _customersCount = customersCount);

    try {
      final orders = await OrderApi.getToday();
      ordersCount = orders.length;
    } catch (_) {
      ordersCount = 0;
    }
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
      } catch (_) {
        deliveryCount = 0;
      }
    }
    if (mounted) setState(() => _deliveryStaffCount = deliveryCount);

    try {
      var page = 1;
      while (page <= 40) {
        final list = await PaymentApi.list(page: page, limit: 100);
        for (final p in list) {
          revenue += p.amount;
        }
        if (list.length < 100) break;
        page++;
      }
    } catch (_) {
      revenue = 0;
    }
    if (mounted) {
      setState(() {
        _revenue = revenue;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_greeting()}, ${widget.adminName} 👋',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            const SectionHeader(title: 'Overview'),
            const SizedBox(height: 8),

            if (_loading) _buildShimmer() else _buildStatsGrid(),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Quick actions'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.person_add,
                    label: 'Add Customer',
                    onTap: () => context.push(AppRoutes.addCustomer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.assignment_outlined,
                    label: 'Assign Plan',
                    onTap: () => context.push(AppRoutes.planAssignments),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.delivery_dining,
                    label: 'Delivery',
                    onTap: () => context.push(AppRoutes.delivery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.payment,
                    label: 'Payments',
                    onTap: () => context.push(AppRoutes.payments),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: List.generate(4, (_) => const _ShimmerCard()),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _DashboardStatCard(
          label: 'Total customers',
          value: _customersCount,
          isRevenue: false,
        ),
        _DashboardStatCard(
          label: "Today's orders",
          value: _ordersCount,
          isRevenue: false,
        ),
        _DashboardStatCard(
          label: 'Delivery staff',
          value: _deliveryStaffCount,
          isRevenue: false,
        ),
        _DashboardStatCard(
          label: 'Revenue (₹)',
          value: _revenue.toInt(),
          isRevenue: true,
        ),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 72,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.shimmerHighlight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.isRevenue,
  });

  final String label;
  final int value;
  final bool isRevenue;

  @override
  Widget build(BuildContext context) {
    final positive = value > 0;
    final IconData icon;
    final Color iconColor;
    if (isRevenue) {
      icon = positive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
      iconColor = positive ? AppColors.trendUp : AppColors.trendDown;
    } else {
      icon = positive ? Icons.trending_up_rounded : Icons.trending_flat_rounded;
      iconColor = positive ? AppColors.trendUp : AppColors.textHint;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _formatValue(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 22, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatValue() {
    if (!isRevenue) return value.toString();
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '₹$value';
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
