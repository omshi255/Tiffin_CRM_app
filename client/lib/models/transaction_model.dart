/// Single merged transaction row (ledger + legacy payments).
class CustomerDetailTransaction {
  const CustomerDetailTransaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.paymentMode,
    required this.items,
  });

  final String id;
  final String date;
  final String description;
  final double amount;
  final String type;
  final String paymentMode;
  final List<CustomerDetailTransactionItem> items;

  factory CustomerDetailTransaction.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final list = <CustomerDetailTransactionItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(CustomerDetailTransactionItem.fromJson(e));
        }
      }
    }
    return CustomerDetailTransaction(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount:
          (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0,
      type: json['type']?.toString() ?? '',
      paymentMode: json['paymentMode']?.toString() ?? '',
      items: list,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'description': description,
        'amount': amount,
        'type': type,
        'paymentMode': paymentMode,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class CustomerDetailTransactionItem {
  const CustomerDetailTransactionItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final double quantity;
  final double unitPrice;

  factory CustomerDetailTransactionItem.fromJson(Map<String, dynamic> json) {
    return CustomerDetailTransactionItem(
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
