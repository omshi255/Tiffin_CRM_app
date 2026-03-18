import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
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
  static const LatLng _defaultCenter = LatLng(19.0760, 72.8777);
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
        AppSnackbar.success(context, 'Location shared');
      }
    } catch (e) {
      if (mounted) ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _updatingLocation = false);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _initialTarget {
    if (_myPosition != null) return _myPosition!;
    final withLocation = _orders.where((o) => o.customerLocation != null).toList();
    if (withLocation.isNotEmpty) {
      final loc = withLocation.first.customerLocation!;
      return LatLng(loc.lat, loc.lng);
    }
    return _defaultCenter;
  }

  Widget _buildWebBody(ThemeData theme) {
    if (_loading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
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
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _orders.isEmpty
                  ? 'No deliveries to show'
                  : 'No address or coordinates on these orders. Open stops in Google Maps from the list below once addresses are set.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final o = list[i];
        final loc = o.customerLocation;
        final name = o.customerName ?? o.customerId;
        final addr = o.customerAddress?.trim() ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(name),
            subtitle: Text(
              addr.isNotEmpty
                  ? addr
                  : (loc != null
                      ? '${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}'
                      : ''),
            ),
            trailing: const Icon(Icons.open_in_new),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapBody = _loading && _orders.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : kIsWeb
            ? _buildWebBody(theme)
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialTarget,
                      zoom: 14,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (c) {
                      _mapController = c;
                    },
                  ),
                  if (_orders.isEmpty && !_loading)
                    Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No deliveries to show on map',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                ],
              );
    if (!widget.showAppBar) return mapBody;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My route'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
        actions: [
          IconButton(
            icon: _updatingLocation
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.location_on),
            tooltip: 'Share my location',
            onPressed: _updatingLocation ? null : _shareMyLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: mapBody,
    );
  }
}
