import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../customers/data/customer_api.dart';
import '../../../payments/data/invoice_api.dart';
import '../../../payments/models/invoice_model.dart';
import '../../../../models/customer_model.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<InvoiceModel> _invoices = [];
  bool _loading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await InvoiceApi.list(
        limit: 50,
        paymentStatus: _statusFilter,
      );
      if (mounted) setState(() => _invoices = list);
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetail(InvoiceModel inv) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Invoice ${inv.id.substring(inv.id.length > 8 ? inv.id.length - 8 : 0)}',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Customer: ${inv.customerName ?? inv.customerId}'),
            Text('Amount: ₹${inv.amount.toStringAsFixed(0)}'),
            Text('Status: ${inv.status}'),
            if (inv.dueDate != null)
              Text('Due: ${inv.dueDate!.day}/${inv.dueDate!.month}/${inv.dueDate!.year}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                try {
                  final url = await InvoiceApi.share(inv.id);
                  if (ctx.mounted && url.isNotEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Share link: $url')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) ErrorHandler.show(ctx, e);
                }
              },
              child: const Text('Share / Get link'),
            ),
            if (inv.status.toLowerCase() != 'voided') ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text('Void invoice'),
                      content: const Text('Void this invoice?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Void'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  try {
                    await InvoiceApi.voidInvoice(inv.id);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _load();
                    }
                  } catch (e) {
                    if (ctx.mounted) ErrorHandler.show(ctx, e);
                  }
                },
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Void invoice'),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _openGenerateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _GenerateInvoiceSheet(onGenerated: () {
        Navigator.pop(ctx);
        _load();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        actions: [
          PopupMenuButton<String?>(
            initialValue: _statusFilter,
            onSelected: (v) {
              setState(() {
                _statusFilter = v;
                _load();
              });
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(value: 'unpaid', child: Text('Unpaid')),
              const PopupMenuItem(value: 'paid', child: Text('Paid')),
              const PopupMenuItem(value: 'voided', child: Text('Voided')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _invoices.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 48),
                        Center(
                          child: Text(
                            'No invoices',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _invoices.length,
                      itemBuilder: (context, index) {
                        final inv = _invoices[index];
                        final invNumber = inv.id.length > 8
                            ? inv.id.substring(inv.id.length - 8)
                            : inv.id;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text('INV-$invNumber'),
                            subtitle: Text(
                              '${inv.customerName ?? inv.customerId} • ₹${inv.amount.toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.picture_as_pdf,
                              color: inv.status == 'unpaid'
                                  ? AppColors.warning
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            onTap: () => _showDetail(inv),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openGenerateSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GenerateInvoiceSheet extends StatefulWidget {
  const _GenerateInvoiceSheet({required this.onGenerated});

  final VoidCallback onGenerated;

  @override
  State<_GenerateInvoiceSheet> createState() => _GenerateInvoiceSheetState();
}

class _GenerateInvoiceSheetState extends State<_GenerateInvoiceSheet> {
  List<CustomerModel> _customers = [];
  CustomerModel? _customer;
  DateTime _billingStart = DateTime.now();
  DateTime _billingEnd = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (_loaded) return;
    try {
      final res = await CustomerApi.list(limit: 100);
      final list = (res['customers'] as List<CustomerModel>?) ?? [];
      if (mounted) {
        setState(() {
          _customers = list;
          _loaded = true;
          if (list.isNotEmpty && _customer == null) _customer = list.first;
        });
      }
    } catch (_) {}
  }

  Future<void> _generate() async {
    if (_customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a customer')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await InvoiceApi.generate(
        customerId: _customer!.id,
        billingStart: _billingStart,
        billingEnd: _billingEnd,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice generated')),
        );
        widget.onGenerated();
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Generate Invoice',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CustomerModel>(
              initialValue: _customer,
              decoration: const InputDecoration(labelText: 'Customer'),
              items: _customers
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.name} (${c.phone})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _customer = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Billing start'),
              subtitle: Text(
                '${_billingStart.day}/${_billingStart.month}/${_billingStart.year}',
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _billingStart,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _billingStart = d);
              },
            ),
            ListTile(
              title: const Text('Billing end'),
              subtitle: Text(
                '${_billingEnd.day}/${_billingEnd.month}/${_billingEnd.year}',
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _billingEnd,
                  firstDate: _billingStart,
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (d != null) setState(() => _billingEnd = d);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _generate,
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
                  : const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
}
