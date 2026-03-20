import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/location_helper.dart';
import '../../data/delivery_api.dart';
import '../../../orders/models/order_model.dart';

class DeliveryMapScreen extends StatefulWidget {
  const DeliveryMapScreen({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  // ── Violet palette ────────────────────────────────────────────────────────
  static const _violet900 = Color(0xFF2D1B69);
  static const _violet700 = Color(0xFF4C2DB8);
  static const _violet600 = Color(0xFF5B35D5);
  static const _violet100 = Color(0xFFEDE8FD);
  static const _violet50 = Color(0xFFF5F2FF);
  static const _bg = Color(0xFFF6F4FF);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE4DFF7);
  static const _divider = Color(0xFFEEEBFA);
  static const _textPrimary = Color(0xFF1A0E45);
  static const _textSecondary = Color(0xFF7B6DAB);
  static const _success = Color(0xFF0F7B0F);
  static const _successSoft = Color(0xFFE6F4EA);
  static const _warning = Color(0xFFBA7517);
  static const _warningSoft = Color(0xFFFAEEDA);

  // ── Map constants ─────────────────────────────────────────────────────────
  static const LatLng _defaultCenter = LatLng(19.0760, 72.8777);

  // ── State ─────────────────────────────────────────────────────────────────
  List<OrderModel> _orders = [];
  bool _loading = true;
  bool _updatingLocation = false;
  Set<Marker> _markers = {};
  LatLng? _myPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _load();
    _fetchMyLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await DeliveryApi.getMyDeliveries();
      if (mounted) {
        setState(() => _orders = list);
        _buildMarkers();
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchMyLocation() async {
    final position = await LocationHelper.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _myPosition = LatLng(position.latitude, position.longitude);
        _buildMarkers();
      });
    }
  }

  void _buildMarkers() {
    final Set<Marker> markers = {};
    for (final order in _orders) {
      final loc = order.customerLocation;
      if (loc != null) {
        markers.add(
          Marker(
            markerId: MarkerId(order.id),
            position: LatLng(loc.lat, loc.lng),
            infoWindow: InfoWindow(
              title: order.customerName ?? order.customerId,
              snippet: order.customerAddress,
            ),
          ),
        );
      }
    }
    if (_myPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _myPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'My location'),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  Future<void> _shareMyLocation() async {
    setState(() => _updatingLocation = true);
    try {
      final position = await LocationHelper.getCurrentPosition();
      if (position == null || !mounted) return;
      await DeliveryApi.updateMe({
        'location': {
          'type': 'Point',
          'coordinates': [position.longitude, position.latitude],
        },
      });
      if (mounted) {
        setState(() {
          _myPosition = LatLng(position.latitude, position.longitude);
          _buildMarkers();
        });
        AppSnackbar.success(context, 'Location shared successfully');
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _updatingLocation = false);
    }
  }

  LatLng get _initialTarget {
    if (_myPosition != null) return _myPosition!;
    final withLocation = _orders
        .where((o) => o.customerLocation != null)
        .toList();
    if (withLocation.isNotEmpty) {
      final loc = withLocation.first.customerLocation!;
      return LatLng(loc.lat, loc.lng);
    }
    return _defaultCenter;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mapBody = _buildMapBody();
    if (!widget.showAppBar) return mapBody;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _violet700,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'My Route',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          // Share location
          IconButton(
            icon: _updatingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
            tooltip: 'Share my location',
            onPressed: _updatingLocation ? null : _shareMyLocation,
          ),
          // Refresh
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: mapBody,
    );
  }

  Widget _buildMapBody() {
    if (_loading && _orders.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: _violet600, strokeWidth: 2.5),
      );
    }

    if (kIsWeb) return _buildWebBody();

    // Native map view
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _initialTarget,
            zoom: 14,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          onMapCreated: (c) => _mapController = c,
        ),

        // No deliveries overlay
        if (_orders.isEmpty && !_loading) _buildEmptyMapOverlay(),

        // Stats pill at top
        if (_orders.isNotEmpty)
          Positioned(top: 12, left: 16, right: 16, child: _buildStatsPill()),

        // FAB bottom-right: center on my location
        Positioned(bottom: 24, right: 16, child: _buildLocationFab()),
      ],
    );
  }

  // ── Map overlays ──────────────────────────────────────────────────────────
  Widget _buildStatsPill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: _violet900.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: _success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_orders.length} stop${_orders.length == 1 ? '' : 's'} on route',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Container(width: 1, height: 14, color: _border),
        const SizedBox(width: 10),
        Icon(Icons.navigation_rounded, size: 14, color: _violet600),
        const SizedBox(width: 4),
        Text(
          'Live',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _violet600,
          ),
        ),
      ],
    ),
  );

  Widget _buildLocationFab() => GestureDetector(
    onTap: _updatingLocation ? null : _shareMyLocation,
    child: Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _violet700,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _violet900.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _updatingLocation
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          : const Icon(
              Icons.my_location_rounded,
              color: Colors.white,
              size: 22,
            ),
    ),
  );

  Widget _buildEmptyMapOverlay() => Center(
    child: Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _violet900.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _violet100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.map_outlined, size: 28, color: _violet600),
          ),
          const SizedBox(height: 14),
          const Text(
            'No deliveries on map',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Assigned deliveries will appear here',
            style: TextStyle(fontSize: 13, color: _textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  // ── Web fallback list ─────────────────────────────────────────────────────
  Widget _buildWebBody() {
    final list = _orders
        .where(
          (o) =>
              o.customerLocation != null ||
              (o.customerAddress != null &&
                  o.customerAddress!.trim().isNotEmpty),
        )
        .toList();

    if (list.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _violet100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 28,
                  color: _violet600,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No stops to display',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap a stop below to open it in Google Maps',
                style: TextStyle(fontSize: 13, color: _textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header strip
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: _bg,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${list.length} delivery stop${list.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                'Tap to open in Maps',
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
            ],
          ),
        ),
        Divider(color: _divider, height: 1, thickness: 1),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: list.length,
            itemBuilder: (context, i) => _buildWebStopCard(list[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildWebStopCard(OrderModel o, int index) {
    final loc = o.customerLocation;
    final name = o.customerName ?? o.customerId;
    final addr = o.customerAddress?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          final Uri url;
          if (loc != null) {
            url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${loc.lat},${loc.lng}',
            );
          } else {
            url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addr)}',
            );
          }
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: _violet100,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _violet900.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Stop number
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _violet100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _violet700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      addr.isNotEmpty
                          ? addr
                          : (loc != null
                                ? '${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}'
                                : 'No address'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Open in maps icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _violet50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: const Icon(
                  Icons.open_in_new_rounded,
                  size: 15,
                  color: _violet600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
