import 'dart:math' as math;

/// Wallet + subscription balances for the Balance tab.
class CustomerDetailBalance {
  const CustomerDetailBalance({
    required this.walletBalance,
    required this.subscriptionBalance,
  });

  final double walletBalance;
  final double subscriptionBalance;

  factory CustomerDetailBalance.fromJson(Map<String, dynamic> json) {
    final raw = (json['walletBalance'] is num)
        ? (json['walletBalance'] as num).toDouble()
        : 0.0;
    return CustomerDetailBalance(
      walletBalance: math.max(0, raw),
      subscriptionBalance: (json['subscriptionBalance'] is num)
          ? (json['subscriptionBalance'] as num).toDouble()
          : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'walletBalance': walletBalance,
        'subscriptionBalance': subscriptionBalance,
      };
}

/// API DTO for GET /customer-details/:id/info (customer profile summary).
class CustomerDetailInfo {
  const CustomerDetailInfo({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.planName,
    required this.startDate,
    required this.status,
  });

  final String name;
  final String phone;
  final String email;
  final String address;
  final String planName;
  final String startDate;
  final String status;

  /// Parses JSON from API `data` payload.
  factory CustomerDetailInfo.fromJson(Map<String, dynamic> json) {
    return CustomerDetailInfo(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
    );
  }

  /// Serializes for caching or debug.
  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'planName': planName,
        'startDate': startDate,
        'status': status,
      };
}

/// Receipt payload for bottom sheet / share.
class CustomerDetailReceipt {
  const CustomerDetailReceipt({
    required this.businessName,
    required this.date,
    required this.description,
    required this.items,
    required this.total,
    required this.paymentMode,
    required this.type,
  });

  final String businessName;
  final String date;
  final String description;
  final List<CustomerDetailReceiptLine> items;
  final double total;
  final String paymentMode;
  final String type;

  factory CustomerDetailReceipt.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final lines = <CustomerDetailReceiptLine>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          lines.add(CustomerDetailReceiptLine.fromJson(e));
        }
      }
    }
    return CustomerDetailReceipt(
      businessName: json['businessName']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      items: lines,
      total: (json['total'] is num) ? (json['total'] as num).toDouble() : 0,
      paymentMode: json['paymentMode']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'date': date,
        'description': description,
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
        'paymentMode': paymentMode,
        'type': type,
      };
}

class CustomerDetailReceiptLine {
  const CustomerDetailReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final double quantity;
  final double unitPrice;

  factory CustomerDetailReceiptLine.fromJson(Map<String, dynamic> json) {
    return CustomerDetailReceiptLine(
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : 1,
      unitPrice: (json['unitPrice'] is num)
          ? (json['unitPrice'] as num).toDouble()
          : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}
