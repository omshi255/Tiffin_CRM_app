import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/network/api_exception.dart';
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
