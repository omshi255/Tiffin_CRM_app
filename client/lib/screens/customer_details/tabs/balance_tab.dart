import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../models/customer_detail_model.dart';
import '../../../services/customer_detail_service.dart';

import 'customer_info_tab.dart';

class _P {
  static const g1 = Color(0xFF7B3FE4);
  static const s900 = Color(0xFF0F172A);
  static const s600 = Color(0xFF475569);
  static const s200 = Color(0xFFE2E8F0);
  static const s100 = Color(0xFFF8FAFC);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF59E0B);
}

/// Wallet / subscription balance and charge forms.
class BalanceTab extends StatefulWidget {
  const BalanceTab({super.key, required this.customerId});

  final String customerId;

  @override
  State<BalanceTab> createState() => _BalanceTabState();
}

class _BalanceTabState extends State<BalanceTab> {
  CustomerDetailBalance? _balance;
  bool _loading = true;
  String? _error;

  final _addAmount = TextEditingController();
  final _addNote = TextEditingController();
  String _payMode = 'cash';

  final _extraAmount = TextEditingController();
  final _extraReason = TextEditingController();

  final _addForm = GlobalKey<FormState>();
  final _extraForm = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addAmount.dispose();
    _addNote.dispose();
    _extraAmount.dispose();
    _extraReason.dispose();
    super.dispose();
  }

  /// Fetches balances for the summary card.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final b = await CustomerDetailService.fetchBalance(widget.customerId);
      if (mounted) {
        setState(() {
          _balance = b;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is ApiException ? (e.message ?? 'Error') : '$e';
        });
      }
    }
  }

  /// Submits wallet top-up and refreshes balances.
  Future<void> _submitAdd() async {
    if (!(_addForm.currentState?.validate() ?? false)) return;
    final amt = double.tryParse(_addAmount.text.trim());
    if (amt == null || amt <= 0) {
      AppSnackbar.error(context, 'Enter a valid amount');
      return;
    }
    try {
      await CustomerDetailService.addBalance(
        widget.customerId,
        amount: amt,
        paymentMode: _payMode,
        note: _addNote.text.trim().isEmpty ? null : _addNote.text.trim(),
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Balance added');
      _addAmount.clear();
      _addNote.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e is ApiException ? (e.message ?? 'Error') : '$e');
      }
    }
  }

  /// Confirms and applies extra charge (separate or subscription).
  Future<void> _confirmExtra(String chargeType) async {
    if (!(_extraForm.currentState?.validate() ?? false)) return;
    final amt = double.tryParse(_extraAmount.text.trim());
    if (amt == null || amt <= 0) {
      AppSnackbar.error(context, 'Enter a valid amount');
      return;
    }
    final reason = _extraReason.text.trim();
    if (reason.isEmpty) {
      AppSnackbar.error(context, 'Reason is required');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber, color: _P.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm charge',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          chargeType == 'separate'
              ? '₹${amt.toStringAsFixed(0)} will be added to pending due.\n$reason'
              : '₹${amt.toStringAsFixed(0)} will be deducted from subscription balance.\n$reason',
          style: const TextStyle(fontSize: 13, color: _P.s600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await CustomerDetailService.extraCharge(
        widget.customerId,
        amount: amt,
        note: reason,
        chargeType: chargeType,
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Charge recorded');
      _extraAmount.clear();
      _extraReason.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e is ApiException ? (e.message ?? 'Error') : '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Shimmer.fromColors(
        baseColor: _P.s200,
        highlightColor: _P.s100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return CustomerDetailNetworkError(message: _error!, onRetry: _load);
    }

    final b = _balance!;
    final walletColor = b.walletBalance > 0 ? _P.green : _P.red;
    final subColor = b.subscriptionBalance > 0 ? _P.green : _P.red;

    return RefreshIndicator(
      color: _P.g1,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _P.s200, width: 0.5),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: walletColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Wallet Balance: ₹${b.walletBalance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: walletColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: _P.g1),
                        onPressed: _load,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.subscriptions, color: subColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Subscription Balance: ₹${b.subscriptionBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: subColor,
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
          Row(
            children: const [
              Icon(Icons.add_circle_outline, color: _P.green),
              SizedBox(width: 8),
              Text(
                'Add Balance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _P.s900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Form(
            key: _addForm,
            child: Column(
              children: [
                TextFormField(
                  controller: _addAmount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _payMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment mode',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'cash',
                      child: Row(
                        children: [
                          Icon(Icons.money, size: 18),
                          SizedBox(width: 8),
                          Text('Cash'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'upi',
                      child: Row(
                        children: [
                          Icon(Icons.phone_android, size: 18),
                          SizedBox(width: 8),
                          Text('UPI'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'online',
                      child: Row(
                        children: [
                          Icon(Icons.credit_card, size: 18),
                          SizedBox(width: 8),
                          Text('Online'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _payMode = v ?? 'cash'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _addNote,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Add Balance'),
                    onPressed: _submitAdd,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Icon(Icons.remove_circle_outline, color: _P.red),
              SizedBox(width: 8),
              Text(
                'Extra Charge',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _P.s900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Form(
            key: _extraForm,
            child: Column(
              children: [
                TextFormField(
                  controller: _extraAmount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _extraReason,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 2 extra rotis',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Charge Separately'),
                        onPressed: () => _confirmExtra('separate'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.remove_circle),
                        label: const Text('Deduct'),
                        onPressed: () => _confirmExtra('subscription'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
