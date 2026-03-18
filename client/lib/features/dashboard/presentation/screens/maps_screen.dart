import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/google_maps_loader.dart';
import '../../../../core/utils/location_helper.dart';
import '../../../delivery/models/delivery_staff_model.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key, this.extra});

  /// Optional [DeliveryStaffModel] when opened from delivery staff list (track on map).
  final Object? extra;

  static const LatLng _defaultCenter = LatLng(19.0760, 72.8777);

  DeliveryStaffModel? get _staff =>
      extra is DeliveryStaffModel ? extra as DeliveryStaffModel : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staff = _staff;
    final center = staff?.location != null
        ? LatLng(staff!.location!.lat, staff.location!.lng)
        : _defaultCenter;

    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: Text(staff != null ? 'Staff location' : 'Delivery route'),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: AppColors.onSurface,
        ),
        body: FutureBuilder<bool>(
          future: ensureGoogleMapsLoaded(
            timeout: const Duration(seconds: 8),
          ),
          builder: (context, snapshot) {
            final mapsLoaded = snapshot.data == true;
            final showLoading =
                snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active;

            if (mapsLoaded) {
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: staff?.location != null ? 15 : 12,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId(staff?.id ?? '1'),
                    position: center,
                    infoWindow: staff != null
                        ? InfoWindow(title: staff.name)
                        : const InfoWindow(),
                  ),
                },
              );
            }

            if (showLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        staff != null
                            ? 'Embedded maps are not loaded on web (Google Maps JS API).'
                            : 'Maps on web need the Google Maps JavaScript API in web/index.html.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Use the Android or iOS app for the in-app map, or open Google Maps in your browser.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (staff != null && staff.location != null) ...[
                        Text(
                          staff.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => LocationHelper.openInMaps(
                            staff.location!.lat,
                            staff.location!.lng,
                          ),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open in Google Maps'),
                        ),
                      ] else if (staff != null) ...[
                        Text(
                          '${staff.name} has no shared location yet.',
                          textAlign: TextAlign.center,
                        ),
                      ] else
                        FilledButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${_defaultCenter.latitude},${_defaultCenter.longitude}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open Google Maps'),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(staff != null ? '${staff.name} on map' : 'Delivery Route'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: staff?.location != null ? 15 : 12,
        ),
        markers: {
          Marker(
            markerId: MarkerId(staff?.id ?? '1'),
            position: center,
            infoWindow: staff != null
                ? InfoWindow(title: staff.name)
                : const InfoWindow(),
          ),
        },
      ),
    );
  }
}
