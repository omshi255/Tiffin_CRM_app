import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/location_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../data/delivery_api.dart';
import '../../../auth/data/auth_api.dart';
import '../../../orders/data/order_api.dart';
import '../../../orders/models/order_model.dart';
import 'delivery_map_screen.dart';
import 'delivery_profile_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _statusFilter;
  bool _updatingLocation = false;
  int _selectedTab = 0;
  Timer? _locationTimer;

  static const List<String?> _filterValues = [null, 'pending', 'processing', 'out_for_delivery', 'delivered'];
  static const List<String> _filterLabels = ['All', 'Pending', 'Cooking', 'On the way', 'Delivered'];

  @override
  void initState() {
    super.initState();
    _load();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _updateLocationSilent();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateLocationSilent() async {
    try {
      final position = await LocationHelper.getCurrentPosition();
      if (position == null || !mounted) return;
      await DeliveryApi.updateMe({
        'location': {
          'type': 'Point',
          'coordinates': [position.longitude, position.latitude],
        },
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await DeliveryApi.getMyDeliveries();
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<OrderModel> get _filteredOrders {
    if (_statusFilter == null) return _orders;
    return _orders.where((o) => o.status == _statusFilter).toList();
  }

  Future<void> _shareMyLocation() async {
    setState(() => _updatingLocation = true);
    try {
      final position = await LocationHelper.getCurrentPosition();
      if (position == null || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get location. Enable location and try again.')),
          );
        }
        return;
      }
      await DeliveryApi.updateMe({
        'location': {
          'type': 'Point',
          'coordinates': [position.longitude, position.latitude],
        },
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location shared')),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _updatingLocation = false);
    }
  }

  Future<void> _logout() async {
    final router = GoRouter.of(context);
    await AuthApi.logout();
    await SecureStorage.clearAll();
    if (!mounted) return;
    router.go(AppRoutes.roleSelection);
  }

  void _showOrderSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _OrderActionSheet(
        order: order,
        onAccept: () async {
          try {
            await OrderApi.accept(order.id);
            await OrderApi.updateStatus(order.id, 'out_for_delivery');
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          } catch (e) {
            if (ctx.mounted) ErrorHandler.show(ctx, e);
          }
        },
        onReject: () async {
          final reason = await showDialog<String>(
            context: ctx,
            builder: (c) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Reject delivery'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    hintText: 'e.g. Too far, unavailable',
                  ),
                  maxLines: 2,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, controller.text.trim()),
                    child: const Text('Reject'),
                  ),
                ],
              );
            },
          );
          if (reason == null) return;
          try {
            await OrderApi.reject(order.id, reason: reason.isEmpty ? 'Rejected' : reason);
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          } catch (e) {
            if (ctx.mounted) ErrorHandler.show(ctx, e);
          }
        },
        onStartDelivery: () async {
          try {
            await OrderApi.updateStatus(order.id, 'out_for_delivery');
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          } catch (e) {
            if (ctx.mounted) ErrorHandler.show(ctx, e);
          }
        },
        onMarkDelivered: () async {
          try {
            await OrderApi.updateStatus(order.id, 'delivered');
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          } catch (e) {
            if (ctx.mounted) ErrorHandler.show(ctx, e);
          }
        },
        onWhatsApp: () {
          final phone = order.customerPhone;
          if (phone != null && phone.isNotEmpty) {
            WhatsAppHelper.openChat(phone);
          }
        },
        onCall: () {
          final phone = order.customerPhone;
          if (phone != null && phone.isNotEmpty) {
            WhatsAppHelper.callPhone(phone);
          }
        },
        onOpenMaps: () {
          final loc = order.customerLocation;
          if (loc != null) {
            LocationHelper.openInMaps(loc.lat, loc.lng);
          } else if (order.customerAddress != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No coordinates for this address')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredOrders;

    final titles = ['Tasks', 'Map', 'Profile'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedTab]),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        actions: _selectedTab == 0
            ? [
                IconButton(
                  icon: _updatingLocation
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.location_on_outlined),
                  tooltip: 'Share my location',
                  onPressed: _updatingLocation ? null : _shareMyLocation,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading ? null : _load,
                ),
                PopupMenuButton<void>(
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: null,
                      child: ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
                      ),
                    ),
                  ],
                  onSelected: (_) => _logout(),
                ),
              ]
            : null,
        bottom: _selectedTab == 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: List.generate(_filterLabels.length, (i) {
                      final selected = _statusFilter == _filterValues[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_filterLabels[i]),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _statusFilter = _filterValues[i]),
                        ),
                      );
                    }),
                  ),
                ),
              )
            : null,
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildTasksBody(context, theme, filtered),
          const DeliveryMapScreen(showAppBar: false),
          const DeliveryProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _selectedTab = 1),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              icon: const Icon(Icons.map),
              label: const Text('View on map'),
            )
          : null,
    );
  }

  Widget _buildTasksBody(BuildContext context, ThemeData theme, List<OrderModel> filtered) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 48),
                      Center(
                        child: Text(
                          'No deliveries assigned',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final borderColor = statusBorderColor(order.status);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showOrderSheet(order),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border(
                                left: BorderSide(
                                  color: borderColor,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                order.customerName ?? order.customerId,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (order.customerAddress != null &&
                                      order.customerAddress!.isNotEmpty)
                                    Text(
                                      order.customerAddress!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  Text(
                                    '${order.slot ?? '—'} • ${order.status}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: borderColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.status,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: borderColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
  }
}

class _OrderActionSheet extends StatelessWidget {
  const _OrderActionSheet({
    required this.order,
    required this.onAccept,
    required this.onReject,
    required this.onStartDelivery,
    required this.onMarkDelivered,
    required this.onWhatsApp,
    required this.onCall,
    required this.onOpenMaps,
  });

  final OrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onStartDelivery;
  final VoidCallback onMarkDelivered;
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order.status.toLowerCase();
    final needsAcceptReject = status == 'pending' || status == 'to_process' || status == 'assigned';
    final canStart = status != 'in_transit' && status != 'delivered' && status != 'out_for_delivery';
    final canDeliver = status == 'in_transit' || status == 'out_for_delivery';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            order.customerName ?? order.customerId,
            style: theme.textTheme.titleLarge,
          ),
          if (order.customerAddress != null) ...[
            const SizedBox(height: 4),
            Text(
              order.customerAddress!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          Text('Slot: ${order.slot ?? '—'} • ${order.status}'),
          const SizedBox(height: 24),
          if (needsAcceptReject) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (canStart && !needsAcceptReject)
            FilledButton.icon(
              onPressed: onStartDelivery,
              icon: const Icon(Icons.delivery_dining),
              label: const Text('Start delivery'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          if (canDeliver) ...[
            if (canStart && !needsAcceptReject) const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onMarkDelivered,
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark delivered'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenMaps,
                  icon: const Icon(Icons.map),
                  label: const Text('Maps'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
