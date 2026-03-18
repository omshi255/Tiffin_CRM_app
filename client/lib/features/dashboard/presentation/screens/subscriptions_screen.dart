import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../customers/data/customer_api.dart';
import '../../../plans/data/plan_api.dart';
import '../../../plans/models/plan_model.dart';
import '../../../subscriptions/data/subscription_api.dart';
import '../../../subscriptions/models/subscription_model.dart';
import '../../../../models/customer_model.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key, this.initialPlan});

  final PlanModel? initialPlan;

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  List<SubscriptionModel> _list = [];
  bool _loading = true;
  static const List<String> _statusTabs = [
    'active',
    'paused',
    'expired',
    'cancelled',
  ];
  late TabController _tabController;
  String get _currentStatus => _statusTabs[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _load();
    final plan = widget.initialPlan;
    if (plan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openAssignSubscription(plan);
      });
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) _load();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await SubscriptionApi.list(status: _currentStatus, limit: 50);

      final inner = res['data'];
      List<dynamic> rawList = [];
      if (inner is List) {
        rawList = inner;
      } else if (inner is Map<String, dynamic>) {
        rawList = (inner['data'] as List?) ?? [];
      }

      final list = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => SubscriptionModel.fromJson(e))
          .toList();

      if (mounted) setState(() => _list = list);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetail(SubscriptionModel sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SubscriptionDetailSheet(
        subscription: sub,
        onRenew: () async {
          final start = sub.endDate.isBefore(DateTime.now())
              ? DateTime.now()
              : sub.endDate;
          final end = DateTime(start.year, start.month + 1, start.day);
          try {
            await SubscriptionApi.renew(sub.id, start, end);
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          } catch (e) {
            if (ctx.mounted) ErrorHandler.show(ctx, e);
          }
        },
        onViewCustomer: () {
          Navigator.pop(ctx);
          final c = CustomerModel(
            id: sub.customerId,
            name: sub.customerName ?? sub.customerId,
            phone: sub.customerPhone ?? '',
            email: null,
            address: sub.customerAddress,
            area: null,
            landmark: null,
            whatsapp: null,
            notes: null,
            tags: null,
            balance: null,
            location: null,
            vendorId: null,
            status: 'active',
            createdAt: null,
          );
          context.push(AppRoutes.customerDetail, extra: c);
        },
      ),
    );
  }

  void _openAssignSubscription([PlanModel? preselectedPlan]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AssignSubscriptionSheet(
        preselectedPlan: preselectedPlan,
        onCreated: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Assignments'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: _statusTabs
                    .map((s) => Tab(text: s[0].toUpperCase() + s.substring(1)))
                    .toList(),
              ),
              Container(height: 1, color: AppColors.border),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _list.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 48),
                        Center(
                          child: Text(
                            'No $_currentStatus plan assignments',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _list.length,
                      itemBuilder: (context, index) {
                        final sub = _list[index];
                        final totalDays = sub.endDate
                            .difference(sub.startDate)
                            .inDays;
                        final now = DateTime.now();
                        final daysRemaining = sub.endDate.isAfter(now)
                            ? sub.endDate.difference(now).inDays
                            : 0;
                        final progress = totalDays > 0
                            ? (1 - (daysRemaining / totalDays)).clamp(0.0, 1.0)
                            : 1.0;
                        final statusColor = statusBorderColor(sub.status);
                        final planName = sub.planName ?? sub.planId;
                        final customerName = sub.customerName ?? sub.customerId;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _showDetail(sub),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          customerName,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
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
                                          color: statusColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          sub.status,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: statusColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    planName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${sub.startDate.day}/${sub.startDate.month}/${sub.startDate.year} - ${sub.endDate.day}/${sub.endDate.month}/${sub.endDate.year}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: AppColors.border,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAssignSubscription(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Assign Plan'),
      ),
    );
  }
}

class _SubscriptionDetailSheet extends StatelessWidget {
  const _SubscriptionDetailSheet({
    required this.subscription,
    required this.onRenew,
    required this.onViewCustomer,
  });

  final SubscriptionModel subscription;
  final VoidCallback onRenew;
  final VoidCallback onViewCustomer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnded =
        subscription.status.toLowerCase() == 'expired' ||
        subscription.status.toLowerCase() == 'cancelled';
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
                Text('Plan assignment detail', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(
                  'Customer: ${subscription.customerName ?? subscription.customerId}',
                ),
                if (subscription.customerPhone != null)
                  Text('Phone: ${subscription.customerPhone}'),
                if (subscription.customerAddress != null)
                  Text('Address: ${subscription.customerAddress}'),
                Text('Plan: ${subscription.planName ?? subscription.planId}'),
                if (subscription.planType != null)
                  Text('Plan type: ${subscription.planType}'),
                Text('Status: ${subscription.status}'),
                if (subscription.deliverySlot != null)
                  Text('Delivery slot: ${subscription.deliverySlot}'),
                if (subscription.deliveryDays != null &&
                    subscription.deliveryDays!.isNotEmpty)
                  Text(
                    'Delivery days: ${subscription.deliveryDays!.map((d) => ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d]).join(', ')}',
                  ),
                if (subscription.totalAmount != null)
                  Text(
                    'Total: ₹${subscription.totalAmount!.toStringAsFixed(0)}',
                  ),
                if (subscription.paidAmount != null)
                  Text('Paid: ₹${subscription.paidAmount!.toStringAsFixed(0)}'),
                Text('Auto renewal: ${subscription.autoRenew}'),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: onViewCustomer,
                  child: const Text('View Customer'),
                ),
                if (!isEnded) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onRenew,
                    child: const Text('Extend end date'),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
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

class _AssignSubscriptionSheet extends StatefulWidget {
  const _AssignSubscriptionSheet({
    this.preselectedPlan,
    required this.onCreated,
  });

  final PlanModel? preselectedPlan;
  final VoidCallback onCreated;

  @override
  State<_AssignSubscriptionSheet> createState() =>
      _AssignSubscriptionSheetState();
}

class _AssignSubscriptionSheetState extends State<_AssignSubscriptionSheet> {
  CustomerModel? _customer;
  PlanModel? _plan;
  String? _selectedPlanId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String _deliverySlot = 'morning';
  List<int> _deliveryDays = [1, 2, 3, 4, 5, 6]; // Mon-Sat default
  final _notesController = TextEditingController();
  bool _loading = false;
  List<CustomerModel> _customers = [];
  List<PlanModel> _plans = [];

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _plan = widget.preselectedPlan;
    _selectedPlanId = widget.preselectedPlan?.id;
    _loadCustomers();
    _loadPlans();
  }

  Future<void> _loadCustomers() async {
    try {
      final res = await CustomerApi.list(limit: 100, status: 'active');
      final rawList = (res['data'] as List?) ?? [];
      final customers = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => CustomerModel.fromJson(e))
          .toList();
      if (mounted) setState(() => _customers = customers);
    } catch (_) {}
  }

  Future<void> _loadPlans() async {
    try {
      final list = await PlanApi.list(limit: 50, isActive: true);
      if (mounted) {
        setState(() {
          _plans = list;
          if (list.isEmpty) {
            _selectedPlanId = null;
            _plan = null;
          } else {
            if (_plan != null && list.any((p) => p.id == _plan!.id)) {
              _selectedPlanId = _plan!.id;
            } else if (_plan == null) {
              _plan = list.first;
              _selectedPlanId = list.first.id;
            } else {
              _plan = null;
              _selectedPlanId = null;
            }
          }
        });
      }
    } catch (_) {}
  }

  void _toggleDay(int day) {
    setState(() {
      if (_deliveryDays.contains(day)) {
        _deliveryDays = _deliveryDays.where((d) => d != day).toList();
      } else {
        _deliveryDays = [..._deliveryDays, day]..sort();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_customer == null || _plan == null) {
      AppSnackbar.error(context, 'Select customer and plan');
      return;
    }
    if (_deliveryDays.isEmpty) {
      AppSnackbar.error(context, 'Select at least one delivery day');
      return;
    }
    setState(() => _loading = true);
    try {
      await SubscriptionApi.create({
        'customerId': _customer!.id,
        'planId': _plan!.id,
        'startDate': _startDate.toIso8601String().split('T').first,
        'endDate': _endDate.toIso8601String().split('T').first,
        'deliverySlot': _deliverySlot,
        'deliveryDays': _deliveryDays,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      });
      if (mounted) {
        AppSnackbar.success(context, 'Subscription created');
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            const BottomSheetHandle(),
            Text('Assign Plan', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<CustomerModel>(
              initialValue: _customer,
              decoration: const InputDecoration(labelText: 'Customer'),
              items: _customers
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.name} (${c.phone})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _customer = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _plans.any((p) => p.id == _selectedPlanId)
                  ? _selectedPlanId
                  : null,
              decoration: const InputDecoration(labelText: 'Plan'),
              hint: const Text('Select Plan'),
              items: _plans
                  .map(
                    (p) => DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(
                        '${p.planName} - ₹${p.price.toStringAsFixed(0)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                setState(() {
                  _selectedPlanId = id;
                  _plan = _plans.firstWhere((p) => p.id == id);
                });
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _startDate = d);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End date'),
              subtitle: Text(
                '${_endDate.day}/${_endDate.month}/${_endDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (d != null) setState(() => _endDate = d);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _deliverySlot,
              decoration: const InputDecoration(labelText: 'Delivery slot'),
              items: [
                'morning',
                'afternoon',
                'evening',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _deliverySlot = v ?? 'morning'),
            ),
            const SizedBox(height: 16),
            Text(
              'Delivery Days',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: List.generate(7, (i) {
                final selected = _deliveryDays.contains(i);
                return FilterChip(
                  label: Text(_dayLabels[i]),
                  selected: selected,
                  onSelected: (_) => _toggleDay(i),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Assign Plan'),
            ),
          ],
        );
      },
    );
  }
}
