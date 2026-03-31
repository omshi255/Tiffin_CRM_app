import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../models/customer_detail_model.dart';
import '../../../services/customer_detail_service.dart';

class _P {
  static const g1 = Color(0xFF7B3FE4);
  static const s900 = Color(0xFF0F172A);
  static const s600 = Color(0xFF475569);
  static const s200 = Color(0xFFE2E8F0);
  static const s100 = Color(0xFFF8FAFC);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
}

/// Loads and displays customer profile rows for the Info tab.
class CustomerInfoTab extends StatefulWidget {
  const CustomerInfoTab({super.key, required this.customerId});

  final String customerId;

  @override
  State<CustomerInfoTab> createState() => _CustomerInfoTabState();
}

class _CustomerInfoTabState extends State<CustomerInfoTab> {
  CustomerDetailInfo? _info;
  bool _loading = true;
  String? _error;
  bool _sendingLink = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches customer info from the API.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await CustomerDetailService.fetchInfo(widget.customerId);
      if (mounted) {
        setState(() {
          _info = data;
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

  String _formatStart(String iso) {
    if (iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat.yMMMd().format(d.toLocal());
  }

  /// Creates a login link and opens WhatsApp with the generated message.
  Future<void> _sendLoginLink() async {
    setState(() => _sendingLink = true);
    try {
      final result = await CustomerDetailService.sendLoginLink(widget.customerId);
      if (!mounted) return;
      final phone = result['phone']?.toString() ?? '';
      final message = result['message']?.toString() ?? '';
      final ok = await WhatsAppHelper.openWithMessage(phone, message);
      if (!mounted) return;
      if (ok) {
        AppSnackbar.success(context, 'Login link sent to $phone');
      } else {
        AppSnackbar.error(context, 'Could not open WhatsApp');
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _sendingLink = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildShimmer(context);
    }
    if (_error != null) {
      return CustomerDetailNetworkError(
        message: _error!,
        onRetry: _load,
      );
    }
    final i = _info!;
    final active = i.status.toLowerCase() == 'active';

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
            child: Column(
              children: [
                _tile(Icons.person, 'Name', i.name),
                const Divider(height: 1),
                _tile(Icons.phone, 'Phone', i.phone),
                const Divider(height: 1),
                _tile(Icons.email_outlined, 'Email', i.email.isEmpty ? '—' : i.email),
                const Divider(height: 1),
                _tile(
                  Icons.location_on_outlined,
                  'Address',
                  i.address.isEmpty ? '—' : i.address,
                ),
                const Divider(height: 1),
                _tile(
                  Icons.card_membership,
                  'Plan Name',
                  i.planName.isEmpty ? '—' : i.planName,
                ),
                const Divider(height: 1),
                _tile(Icons.calendar_today, 'Start Date', _formatStart(i.startDate)),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    active ? Icons.check_circle : Icons.cancel,
                    color: active ? _P.green : _P.red,
                  ),
                  title: const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _P.s600,
                    ),
                  ),
                  subtitle: Text(
                    active ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _P.s900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CUSTOMER PORTAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5B21B6),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDDD6FE),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.link_rounded,
                            color: Color(0xFF7B3FE4),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Send Login Link',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Customer will receive a WhatsApp message with a secure login link valid for 24 hours.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sendingLink ? null : _sendLoginLink,
                          icon: _sendingLink
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.whatsapp_rounded, size: 16),
                          label: Text(
                            _sendingLink ? 'Sending...' : 'Send via WhatsApp',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: _P.g1, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _P.s600,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _P.s900,
        ),
      ),
    );
  }

  /// Placeholder shimmer while the first request is in flight.
  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _P.s200,
      highlightColor: _P.s100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

/// Offline / error state with tap-to-retry.
class CustomerDetailNetworkError extends StatelessWidget {
  const CustomerDetailNetworkError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = message.toLowerCase().contains('internet');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: offline ? onRetry : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                offline ? Icons.wifi_off : Icons.error_outline,
                size: 48,
                color: const Color(0xFF475569),
              ),
              const SizedBox(height: 12),
              Text(
                offline ? 'No internet. Tap to retry' : message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (!offline) ...[
                const SizedBox(height: 16),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
