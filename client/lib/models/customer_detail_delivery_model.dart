/// One row in the deliveries month list.
class CustomerDetailDeliveryRow {
  const CustomerDetailDeliveryRow({
    required this.date,
    required this.items,
    required this.status,
  });

  final String date;
  final String items;
  final String status;

  factory CustomerDetailDeliveryRow.fromJson(Map<String, dynamic> json) {
    return CustomerDetailDeliveryRow(
      date: json['date']?.toString() ?? '',
      items: json['items']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'items': items,
        'status': status,
      };
}
