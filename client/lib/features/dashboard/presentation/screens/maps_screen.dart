import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  static const LatLng _defaultCenter = LatLng(19.0760, 72.8777);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Route'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: AppColors.onSurface,
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _defaultCenter,
          zoom: 12,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('1'),
            position: _defaultCenter,
          ),
        },
      ),
    );
  }
}
