class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.status = 'active',
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String status;

  String get fullName => name;
}
