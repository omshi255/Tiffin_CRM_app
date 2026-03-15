import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../customers/data/customer_api.dart';
import '../../../payments/data/invoice_api.dart';
import '../../../payments/data/payment_api.dart';
import '../../../payments/models/invoice_model.dart';
import '../../../payments/models/payment_model.dart';
import '../../../../models/customer_model.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<PaymentModel> _payments = [];
  List<InvoiceModel> _overdue = [];
  List<CustomerModel> _customers = [];
  bool _loading = true;
  final _amountController = TextEditingController();
  CustomerModel? _selectedCustomer;
  String _mode = 'cash';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final payRes = await PaymentApi.list(limit: 50);
      final overdueList = await InvoiceApi.getOverdue();

      // Fixed: use limit 100 and parse res['data'] correctly
      final custRes = await CustomerApi.list(limit: 100, status: 'active');
      final rawList = (custRes['data'] as List?) ?? [];
      final customers = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => CustomerModel.fromJson(e))
          .toList();

      if (mounted) {
        setState(() {
          _payments = payRes;
          _overdue = overdueList;
          _customers = customers;
        });
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recordPayment() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a customer')));
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    try {
      await PaymentApi.create({
        'customerId': _selectedCustomer!.id,
        'amount': amount,
        'paymentMethod': _mode,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment recorded')));
        _amountController.clear();
        setState(() => _selectedCustomer = null);
        _load();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Collect Payment Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Collect Payment',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<CustomerModel>(
                              value: _selectedCustomer,
                              decoration: const InputDecoration(
                                labelText: 'Customer',
                              ),
                              items: _customers
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text('${c.name} (${c.phone})'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCustomer = v),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                labelText: 'Amount (₹)',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: ['cash', 'upi', 'card', 'bank_transfer']
                                  .map((m) {
                                    return ChoiceChip(
                                      label: Text(m.replaceAll('_', ' ')),
                                      selected: _mode == m,
                                      onSelected: (_) =>
                                          setState(() => _mode = m),
                                    );
                                  })
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _saving ? null : _recordPayment,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Record Payment'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Overdue Invoices
                    const SectionHeader(title: 'Overdue Invoices'),
                    const SizedBox(height: 12),
                    if (_overdue.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No overdue payments 🎉',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ..._overdue.map(
                        (inv) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFFEBEE),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                            title: Text(inv.customerName ?? inv.customerId),
                            subtitle: Text(
                              inv.dueDate != null
                                  ? 'Due: ${inv.dueDate!.day}/${inv.dueDate!.month}/${inv.dueDate!.year}'
                                  : '—',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Text(
                              '₹${inv.amount.toStringAsFixed(0)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Payment History
                    const SectionHeader(title: 'Payment History'),
                    const SizedBox(height: 12),
                    if (_payments.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No payments recorded yet',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ..._payments.map(
                        (p) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.payments_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(p.customerName ?? p.customerId),
                            subtitle: Text(
                              '${p.paymentMethod.replaceAll('_', ' ')} • ${p.paymentDate != null ? '${p.paymentDate!.day}/${p.paymentDate!.month}/${p.paymentDate!.year}' : '—'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Text(
                              '₹${p.amount.toStringAsFixed(0)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
