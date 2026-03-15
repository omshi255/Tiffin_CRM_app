class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.status = 'active',
    this.whatsapp,
    this.area,
    this.landmark,
    this.notes,
    this.tags,
    this.balance,
    this.location,
    this.vendorId,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String status;
  final String? whatsapp;
  final String? area;
  final String? landmark;
  final String? notes;
  final List<String>? tags;
  final double? balance;
  final GeoPoint? location;
  final String? vendorId;
  final DateTime? createdAt;

  String get fullName => name;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    List<String>? tags;
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tags = (json['tags'] as List)
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    GeoPoint? location;
    if (json['location'] is Map<String, dynamic>) {
      final loc = json['location'] as Map<String, dynamic>;
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
        final lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
        if (lng != null && lat != null) location = GeoPoint(lat: lat, lng: lng);
      }
    }
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        createdAt = DateTime.tryParse(json['createdAt'] as String);
      }
    }
    return CustomerModel(
      id: id,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      status: json['status']?.toString() ?? 'active',
      whatsapp: json['whatsapp']?.toString(),
      area: json['area']?.toString(),
      landmark: json['landmark']?.toString(),
      notes: json['notes']?.toString(),
      tags: tags,
      balance: (json['balance'] is num)
          ? (json['balance'] as num).toDouble()
          : null,
      location: location,
      vendorId: json['vendorId']?.toString(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      'status': status,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (area != null) 'area': area,
      if (landmark != null) 'landmark': landmark,
      if (notes != null) 'notes': notes,
      if (tags != null && tags!.isNotEmpty) 'tags': tags,
      if (location != null)
        'location': {
          'type': 'Point',
          'coordinates': [location!.lng, location!.lat],
        },
    };
  }
}

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});
  final double lat;
  final double lng;
}
