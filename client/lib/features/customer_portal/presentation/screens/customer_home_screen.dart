import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/location_helper.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../models/customer_model.dart';
import '../../data/customer_portal_api.dart';
import '../../../auth/data/auth_api.dart';
import '../../../orders/data/order_api.dart';
import '../../../orders/models/order_model.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('iMeals'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.customerNotifications),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _CustomerHomeTab(),
          _CustomerMyPlanTab(),
          _CustomerOrdersTab(),
          _CustomerWalletTab(),
          _CustomerProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), label: 'My Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _CustomerHomeTab extends StatefulWidget {
  const _CustomerHomeTab();

  @override
  State<_CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<_CustomerHomeTab> {
  OrderModel? _todayOrder;
  CustomerModel? _profile;
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final order = await CustomerPortalApi.getTodayOrder();
      final profile = await CustomerPortalApi.getMyProfile();
      if (mounted) {
        setState(() {
          _todayOrder = order;
          _profile = profile;
        });
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'processing' || s == 'cooking' || s == 'to_process') return 'Cooking';
    if (s == 'out_for_delivery' || s == 'in_transit') return 'On the way';
    if (s == 'delivered') return 'Delivered';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading && _todayOrder == null && _profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final balance = _profile?.balance ?? 0.0;
    final lowBalance = balance < 100;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Hello, ${_profile?.name ?? 'there'}! 👋',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: "Today's meal"),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _todayOrder == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No order for today',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your tiffin will appear here once generated.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _todayOrder!.slot ?? 'Today\'s meal',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(_todayOrder!.status),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Wallet'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 32, color: AppColors.primary),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '₹${balance.toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (lowBalance && balance >= 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Low balance. Top up to avoid service interruption.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerMyPlanTab extends StatefulWidget {
  const _CustomerMyPlanTab();

  @override
  State<_CustomerMyPlanTab> createState() => _CustomerMyPlanTabState();
}

class _CustomerMyPlanTabState extends State<_CustomerMyPlanTab> {
  OrderModel? _todayOrder;
  List<_PlanItemRow> _items = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final order = await CustomerPortalApi.getTodayOrder();
      if (!mounted) return;
      _todayOrder = order;
      _items = _parseItems(order);
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_PlanItemRow> _parseItems(OrderModel? order) {
    if (order == null) return [];
    final list = <_PlanItemRow>[];
    final slots = order.mealSlots;
    if (slots == null) return [];
    for (final e in slots) {
      if (e is! Map<String, dynamic>) continue;
      final itemId = e['itemId']?.toString() ?? e['_id']?.toString() ?? '';
      final name = e['name']?.toString() ?? e['itemName']?.toString() ?? 'Item';
      final q = (e['quantity'] is num) ? (e['quantity'] as num).toInt() : 1;
      list.add(_PlanItemRow(itemId: itemId, name: name, quantity: q.clamp(1, 999)));
    }
    return list;
  }

  Future<void> _save() async {
    if (_todayOrder == null || _items.isEmpty) return;
    setState(() => _saving = true);
    try {
      final quantities = _items
          .map((e) => {'itemId': e.itemId, 'quantity': e.quantity})
          .toList();
      await OrderApi.updateQuantities(_todayOrder!.id, quantities);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved')),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_todayOrder == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined, size: 64, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No order for today',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(title: 'Your plan'),
              const SizedBox(height: 8),
              Text(
                'Adjust quantities (min 1). Tap Save to apply.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ..._items.map((item) => _PlanItemStepper(
                    item: item,
                    onChanged: () => setState(() {}),
                  )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanItemRow {
  _PlanItemRow({
    required this.itemId,
    required this.name,
    required this.quantity,
  });
  final String itemId;
  final String name;
  int quantity;
}

class _PlanItemStepper extends StatelessWidget {
  const _PlanItemStepper({
    required this.item,
    required this.onChanged,
  });
  final _PlanItemRow item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: item.quantity <= 1
                      ? null
                      : () {
                          item.quantity--;
                          onChanged();
                        },
                ),
                Text(
                  '${item.quantity}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    item.quantity++;
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerOrdersTab extends StatefulWidget {
  const _CustomerOrdersTab();

  @override
  State<_CustomerOrdersTab> createState() => _CustomerOrdersTabState();
}

class _CustomerOrdersTabState extends State<_CustomerOrdersTab> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _statusFilter;
  Timer? _refreshTimer;

  static const List<String?> _statusValues = [
    null,
    'pending',
    'processing',
    'out_for_delivery',
    'delivered',
  ];
  static const List<String> _statusLabels = [
    'All',
    'Pending',
    'Processing',
    'Out for delivery',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await CustomerPortalApi.getMyOrders(
        page: 1,
        limit: 50,
        status: _statusFilter,
      );
      final orders = (res['orders'] as List<OrderModel>? ?? []);
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showOrderStatusSheet(OrderModel o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _OrderStatusSheet(order: o),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(_statusLabels.length, (i) {
              final selected = _statusFilter == _statusValues[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_statusLabels[i]),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _statusFilter = _statusValues[i]);
                    _load();
                  },
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: _loading && _orders.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _orders.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 48),
                            Center(
                              child: Text(
                                'No orders yet',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final o = _orders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  o.slot ?? 'Daily tiffin',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${o.date.day}/${o.date.month}/${o.date.year} • ${o.status}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                onTap: () => _showOrderStatusSheet(o),
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

class _OrderStatusSheet extends StatelessWidget {
  const _OrderStatusSheet({required this.order});
  final OrderModel order;

  static const List<String> _steps = [
    'Order Placed',
    'Cooking',
    'On the Way',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order.status.toLowerCase();
    int currentStep = 1;
    if (status == 'pending' || status == 'assigned') {
      currentStep = 1;
    } else if (status == 'processing' || status == 'cooking' || status == 'to_process') {
      currentStep = 2;
    } else if (status == 'out_for_delivery' || status == 'in_transit') {
      currentStep = 3;
    } else if (status == 'delivered') {
      currentStep = 4;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order status',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(4, (i) {
                final done = (i + 1) <= currentStep;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? AppColors.success : AppColors.outline,
                        ),
                        child: done
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _steps[i],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                          color: done ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (status == 'out_for_delivery' || status == 'in_transit') ...[
                const SizedBox(height: 16),
                if (order.deliveryStaffName != null || order.deliveryStaffPhone != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.delivery_dining, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.deliveryStaffName ?? 'Delivery partner',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (order.deliveryStaffPhone != null)
                                  Text(
                                    order.deliveryStaffPhone!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (order.deliveryStaffPhone != null &&
                              order.deliveryStaffPhone!.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.call),
                              onPressed: () {
                                final uri = Uri.parse(
                                    'tel:${order.deliveryStaffPhone!.replaceAll(RegExp(r'\D'), '')}');
                                launchUrl(uri);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerWalletTab extends StatefulWidget {
  const _CustomerWalletTab();

  @override
  State<_CustomerWalletTab> createState() => _CustomerWalletTabState();
}

class _CustomerWalletTabState extends State<_CustomerWalletTab> {
  CustomerModel? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await CustomerPortalApi.getMyProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final balance = _profile?.balance ?? 0.0;
    final lowBalance = balance < 100;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'Current balance'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 40, color: AppColors.primary),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${balance.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Available balance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (lowBalance && balance >= 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Low balance. Please top up to continue service.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const SectionHeader(title: 'Transaction history'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No transactions yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerProfileTab extends StatefulWidget {
  const _CustomerProfileTab();

  @override
  State<_CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<_CustomerProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  CustomerModel? _profile;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await CustomerPortalApi.getMyProfile();
      if (mounted) {
        _profile = profile;
        _nameController.text = profile.name;
        _addressController.text = profile.address ?? '';
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, e);
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
      };
      await CustomerPortalApi.updateMyProfile(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareLocation() async {
    final position = await LocationHelper.getCurrentPosition();
    if (position == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location')),
        );
      }
      return;
    }
    try {
      await CustomerPortalApi.updateMyProfile({
        'location': {
          'type': 'Point',
          'coordinates': [position.longitude, position.latitude],
        },
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location shared with vendor')),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final p = _profile;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'My Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            if (p != null)
              Text(
                p.phone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _shareLocation,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Share location with vendor'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await AuthApi.logout();
    } catch (_) {}
    await SecureStorage.clearAll();
    if (!mounted) return;
    context.go(AppRoutes.roleSelection);
  }
}

