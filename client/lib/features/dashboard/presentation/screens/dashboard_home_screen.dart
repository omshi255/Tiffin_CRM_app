import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      final staff = await DeliveryApi.listStaff(page: 1, limit: 50);
      deliveryCount = staff.length;
    } catch (_) {
      deliveryCount = 0;
    }
    if (mounted) setState(() => _deliveryStaffCount = deliveryCount);

    try {
      final payments = await PaymentApi.list(page: 1, limit: 100);
      for (final p in payments) {
        revenue += p.amount;
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
      onRefresh: _loadStats,
      child: SingleChildScrollView(
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
            ),
            const SizedBox(height: 20),

            const SectionHeader(title: 'Overview'),
            const SizedBox(height: 8),

            if (_loading) _buildShimmer() else _buildStatsGrid(context),

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
    return SizedBox(
      height: 220,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
        children: List.generate(4, (_) => _ShimmerCard()),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = 220.0;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: constraints.maxWidth,
            height: maxHeight,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _StatCard(
                  title: 'Total Customers',
                  value: '$_customersCount',
                  icon: Icons.people,
                  accentColor: AppColors.primary,
                ),
                _StatCard(
                  title: "Today's Orders",
                  value: '$_ordersCount',
                  icon: Icons.receipt_long,
                  accentColor: AppColors.secondary,
                ),
                _StatCard(
                  title: 'Delivery Staff',
                  value: '$_deliveryStaffCount',
                  icon: Icons.delivery_dining,
                  accentColor: AppColors.warning,
                ),
                _StatCard(
                  title: 'Revenue (₹)',
                  value: _revenue.toInt().toString(),
                  icon: Icons.currency_rupee,
                  accentColor: AppColors.success,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withValues(
              alpha: _opacity.value,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scale = Tween<double>(
      begin: 0.85,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = double.tryParse(widget.value) ?? 0;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 28, color: widget.accentColor),
              const SizedBox(height: 8),
              Flexible(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: number),
                  duration: const Duration(milliseconds: 900),
                  builder: (context, value, child) {
                    return Text(
                      value.toInt().toString(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  widget.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
