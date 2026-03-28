import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:latlong2/latlong.dart';

/// OpenStreetMap Nominatim (free). Use a descriptive User-Agent per usage policy.
/// Browsers forbid setting [User-Agent] on fetch; the default browser UA is sent on web.
abstract final class NominatimGeocodeService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        if (!kIsWeb) 'User-Agent': 'tiffin_crm/1.0 (delivery routing)',
        'Accept': 'application/json',
      },
    ),
  );

  /// Returns first search hit or null.
  static Future<LatLng?> searchFirst(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'json',
      'limit': '1',
    });
    final res = await _dio.get<List<dynamic>>(uri.toString());
    final list = res.data;
    if (list == null || list.isEmpty) return null;
    final first = list.first;
    if (first is! Map<String, dynamic>) return null;
    final lat = first['lat'];
    final lon = first['lon'];
    if (lat is! String || lon is! String) return null;
    final la = double.tryParse(lat);
    final lo = double.tryParse(lon);
    if (la == null || lo == null) return null;
    return LatLng(la, lo);
  }
}
