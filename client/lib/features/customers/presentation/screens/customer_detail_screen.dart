import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../models/customer_model.dart';
import '../../data/customer_api.dart';
import '../../../subscriptions/data/subscription_api.dart';
import '../../../subscriptions/models/subscription_model.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final CustomerModel customer;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  CustomerModel? _customer;
  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final c = await CustomerApi.getById(widget.customer.id);
      final subs = await SubscriptionApi.list(customerId: widget.customer.id);
      if (mounted) {
        setState(() {
          _customer = c;
          _subscriptions = subs as List<SubscriptionModel>;
        });
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreditWalletSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreditWalletSheet(
        customerId: _customer!.id,
        onSuccess: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wallet credited')),
          );
          _load();
        },
        onError: (e) => ErrorHandler.show(ctx, e),
      ),
    );
  }

  void _openWhatsAppLowBalance() {
    final phone = _customer?.whatsapp ?? _customer?.phone ?? '';
    if (phone.isEmpty) return;
    final msg = WhatsAppHelper.lowBalanceMessage(
      _customer!.name,
      _customer!.balance ?? 0,
    );
    WhatsAppHelper.openWithMessage(phone, msg);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete ${_customer?.name ?? widget.customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await CustomerApi.delete(widget.customer.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer deleted')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (mounted) ErrorHandler.show(context, e);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _customer ?? widget.customer;

    if (_isLoading && _customer == null) {
      return Scaffold(
        appBar: AppBar(title: Text(c.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(AppRoutes.editCustomer, extra: c),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      c.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(c.phone, style: theme.textTheme.bodyLarge),
                    if (c.email != null && c.email!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(c.email!, style: theme.textTheme.bodyMedium),
                    ],
                    if (c.address != null && c.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        c.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (c.balance != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Wallet: ₹${c.balance!.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => WhatsAppHelper.openChat(
                      c.whatsapp ?? c.phone,
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showCreditWalletSheet,
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Credit Wallet'),
                  ),
                ),
              ],
            ),
            if (c.balance != null && c.balance! < 100) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openWhatsAppLowBalance,
                icon: const Icon(Icons.warning_amber),
                label: const Text('WhatsApp: Low balance reminder'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Subscription History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_subscriptions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No subscriptions yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ..._subscriptions.map((s) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(s.planName ?? s.planId),
                    subtitle: Text(
                      '${s.startDate.day}/${s.startDate.month}/${s.startDate.year} - ${s.endDate.day}/${s.endDate.month}/${s.endDate.year}',
                    ),
                    trailing: Chip(
                      label: Text(s.status, style: theme.textTheme.labelSmall),
                      backgroundColor: s.status == 'active'
                          ? AppColors.secondaryContainer
                          : theme.colorScheme.surfaceContainerHigh,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CreditWalletSheet extends StatefulWidget {
  const _CreditWalletSheet({
    required this.customerId,
    required this.onSuccess,
    required this.onError,
  });

  final String customerId;
  final VoidCallback onSuccess;
  final void Function(dynamic) onError;

  @override
  State<_CreditWalletSheet> createState() => _CreditWalletSheetState();
}

class _CreditWalletSheetState extends State<_CreditWalletSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'cash';

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BottomSheetHandle(),
            Text(
              'Credit Wallet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 12),
            Text('Payment method', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Cash'),
                  selected: _paymentMethod == 'cash',
                  onSelected: (_) => setState(() => _paymentMethod = 'cash'),
                ),
                ChoiceChip(
                  label: const Text('UPI'),
                  selected: _paymentMethod == 'upi',
                  onSelected: (_) => setState(() => _paymentMethod = 'upi'),
                ),
                ChoiceChip(
                  label: const Text('Card'),
                  selected: _paymentMethod == 'card',
                  onSelected: (_) => setState(() => _paymentMethod = 'card'),
                ),
                ChoiceChip(
                  label: const Text('Bank Transfer'),
                  selected: _paymentMethod == 'bank_transfer',
                  onSelected: (_) => setState(() => _paymentMethod = 'bank_transfer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter valid amount')),
                  );
                  return;
                }
                try {
                  await CustomerApi.creditWallet(
                    widget.customerId,
                    amount: amount,
                    paymentMethod: _paymentMethod,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  );
                  if (mounted) widget.onSuccess();
                } catch (e) {
                  if (mounted) widget.onError(e);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Add Money'),
            ),
          ],
        ),
      ),
    );
  }
}
