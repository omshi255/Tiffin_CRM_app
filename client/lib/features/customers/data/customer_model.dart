/// Customer model for frontend CRUD operations.
/// Frontend only — in-memory state, no API calls.
class Customer {
  Customer({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;

  Customer copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
  }) {
    return Customer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
    );
  }

  /// fromJson / toJson kept for potential future use
  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
      };

  static Customer fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        phoneNumber: json['phoneNumber'] as String,
        email: json['email'] as String?,
      );
}
