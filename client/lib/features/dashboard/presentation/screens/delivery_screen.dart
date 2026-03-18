import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../delivery/data/delivery_api.dart';
import '../../../delivery/models/delivery_staff_model.dart';
import '../../../orders/data/order_api.dart';
import '../../../orders/models/order_model.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key, this.embeddedInShell = false});

  /// When true (e.g. dashboard Orders tab), no duplicate [Scaffold]/[AppBar].
  final bool embeddedInShell;

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _statusFilter;
  final Set<String> _selectedIds = {};
  bool _bulkMode = false;

  static const List<String> _filterLabels = [
    'All',
    'Pending',
    'Cooking',
    'On the way',
    'Delivered',
  ];
  static const List<String?> _filterValues = [
    null,
    'pending',
    'processing',
    'out_for_delivery',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Fetch all deliveries using the delivery API instead of only today's orders.
      final list = await DeliveryApi.getAllDeliveries();
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

  static String _todayDateStr() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  Future<void> _generate() async {
    try {
      final dateStr = _todayDateStr();
      try {
        await OrderApi.generate(date: dateStr);
      } catch (_) {
        try {
          await OrderApi.process(date: dateStr);
        } catch (_) {}
      }
      if (mounted) {
        AppSnackbar.success(context, 'Orders generated for today');
        await _load();
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    }
  }

  Future<void> _process() async {
    try {
      final dateStr = _todayDateStr();
      await OrderApi.process(date: dateStr);
      if (mounted) {
        AppSnackbar.success(context, 'Orders processed');
        await _load();
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    }
  }

  void _showOrderSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _OrderDetailSheet(
        order: order,
        onAssign: () => _openAssignSheet(ctx, [order.id]),
        onStatusChange: (status) async {
          try {
            await OrderApi.updateStatus(order.id, status);
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
          } else {
            AppSnackbar.error(context, 'No phone number');
          }
        },
      ),
    );
  }

  Future<void> _openAssignSheet(
    BuildContext sheetContext,
    List<String> orderIds,
  ) async {
    List<DeliveryStaffModel> staff = [];
    try {
      staff = await DeliveryApi.listStaff(limit: 50, isActive: true);
    } catch (e) {
      if (sheetContext.mounted) ErrorHandler.show(sheetContext, e);
      return;
    }
    if (!sheetContext.mounted) return;
    showModalBottomSheet(
      context: sheetContext,
      builder: (ctx) => _AssignStaffSheet(
        staff: staff,
        orderIds: orderIds,
        onAssigned: () {
          Navigator.pop(ctx); // close assign sheet
          if (sheetContext.mounted)
            Navigator.pop(sheetContext); // close order sheet only if mounted
          _load();
        },
      ),
    );
  }

  void _toggleBulkMode() {
    setState(() {
      _bulkMode = !_bulkMode;
      if (!_bulkMode) _selectedIds.clear();
    });
  }

  void _toggleSelect(OrderModel order) {
    setState(() {
      if (_selectedIds.contains(order.id)) {
        _selectedIds.remove(order.id);
      } else {
        _selectedIds.add(order.id);
      }
    });
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(_filterLabels.length, (i) {
          final selected = _statusFilter == _filterValues[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _filterLabels[i],
                style: TextStyle(
                  color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: selected,
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.onPrimary,
              onSelected: (_) {
                setState(() => _statusFilter = _filterValues[i]);
              },
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _appBarActions(Color fg) {
    return [
      IconButton(
        icon: Icon(Icons.playlist_add, color: fg),
        tooltip: 'Generate orders',
        onPressed: _loading ? null : _generate,
      ),
      IconButton(
        icon: Icon(Icons.check_circle_outline, color: fg),
        tooltip: 'Process orders',
        onPressed: _loading ? null : _process,
      ),
      IconButton(
        icon: Icon(_bulkMode ? Icons.cancel : Icons.checklist, color: fg),
        tooltip: _bulkMode ? 'Cancel selection' : 'Bulk assign',
        onPressed: _toggleBulkMode,
      ),
    ];
  }

  Widget _bodyContent(ThemeData theme, List<OrderModel> filtered) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: filtered.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'No orders for today',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.add),
                    label: const Text('Generate today\'s orders'),
                  ),
                ),
              ],
            )
          : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final order = filtered[index];
                        final isLast = index == filtered.length - 1;
                        final borderColor = statusBorderColor(order.status);
                        final selected =
                            _bulkMode && _selectedIds.contains(order.id);
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 24,
                                child: Column(
                                  children: [
                                    if (_bulkMode)
                                      GestureDetector(
                                        onTap: () => _toggleSelect(order),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected
                                                ? AppColors.primary
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: selected
                                                  ? AppColors.primary
                                                  : AppColors.border,
                                              width: 2,
                                            ),
                                          ),
                                          child: selected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: borderColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.surface,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    if (!isLast)
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          color: AppColors.border,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      if (_bulkMode) {
                                        _toggleSelect(order);
                                      } else {
                                        _showOrderSheet(order);
                                      }
                                    },
                                    onLongPress: _bulkMode
                                        ? null
                                        : () {
                                            setState(() {
                                              _bulkMode = true;
                                              _selectedIds.add(order.id);
                                            });
                                          },
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
                                          order.customerName ??
                                              order.customerId,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (order.customerAddress != null &&
                                                order
                                                    .customerAddress!
                                                    .isNotEmpty)
                                              Text(
                                                order.customerAddress!,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                            Text(
                                              order.slot ?? '—',
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
                                            color: borderColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            order.status,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: borderColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredOrders;
    final body = _bodyContent(theme, filtered);

    final fab = _bulkMode && _selectedIds.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: () => _openAssignSheet(context, _selectedIds.toList()),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            icon: const Icon(Icons.person_add),
            label: Text('Assign (${_selectedIds.length})'),
          )
        : FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.maps),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            icon: const Icon(Icons.map),
            label: const Text('View Map'),
          );

    if (widget.embeddedInShell) {
      return ColoredBox(
        color: AppColors.background,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Daily orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ..._appBarActions(AppColors.primary),
                    ],
                  ),
                ),
                _filterChips(),
                Expanded(child: body),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: fab,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Deliveries'),
        actions: _appBarActions(AppColors.onPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _filterChips(),
        ),
      ),
      body: body,
      floatingActionButton: fab,
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({
    required this.order,
    required this.onAssign,
    required this.onStatusChange,
    required this.onWhatsApp,
  });

  final OrderModel order;
  final VoidCallback onAssign;
  final void Function(String status) onStatusChange;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  order.customerName ?? order.customerId,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (order.customerAddress != null)
                  Text(
                    order.customerAddress!,
                    style: theme.textTheme.bodyMedium,
                  ),
                if (order.slot != null) Text('Slot: ${order.slot}'),
                Text('Status: ${order.status}'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onAssign,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Assign Delivery Boy'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Update status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['processing', 'out_for_delivery', 'delivered'].map(
                    (s) {
                      return OutlinedButton(
                        onPressed: () => onStatusChange(s),
                        child: Text(s.replaceAll('_', ' ')),
                      );
                    },
                  ).toList(),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp Customer'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignStaffSheet extends StatelessWidget {
  const _AssignStaffSheet({
    required this.staff,
    required this.orderIds,
    required this.onAssigned,
  });

  final List<DeliveryStaffModel> staff;
  final List<String> orderIds;
  final VoidCallback onAssigned;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No delivery staff found. Add staff first.'),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign to delivery person',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...staff.map(
                (s) => ListTile(
                  title: Text(s.name),
                  subtitle: Text(s.phone),
                  onTap: () async {
                    try {
                      if (orderIds.length == 1) {
                        await OrderApi.assign(orderIds.first, s.id);
                      } else {
                        await OrderApi.assignBulk(orderIds, s.id);
                      }
                      if (context.mounted) {
                        AppSnackbar.success(context, 'Assigned');
                        onAssigned();
                      }
                    } catch (e) {
                      if (context.mounted) ErrorHandler.show(context, e);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
