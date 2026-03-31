/// Active plan card for the Meal Plan tab.
class CustomerDetailActivePlan {
  const CustomerDetailActivePlan({
    required this.id,
    required this.planName,
    required this.itemsPerDay,
    required this.pricePerMonth,
    required this.startDate,
    required this.endDate,
    required this.remainingDays,
  });

  final String id;
  final String planName;
  final int itemsPerDay;
  final double pricePerMonth;
  final String startDate;
  final String endDate;
  final int remainingDays;

  factory CustomerDetailActivePlan.fromJson(Map<String, dynamic> json) {
    return CustomerDetailActivePlan(
      id: json['id']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      itemsPerDay: (json['itemsPerDay'] is num)
          ? (json['itemsPerDay'] as num).toInt()
          : 0,
      pricePerMonth: (json['pricePerMonth'] is num)
          ? (json['pricePerMonth'] as num).toDouble()
          : 0,
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      remainingDays: (json['remainingDays'] is num)
          ? (json['remainingDays'] as num).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'planName': planName,
        'itemsPerDay': itemsPerDay,
        'pricePerMonth': pricePerMonth,
        'startDate': startDate,
        'endDate': endDate,
        'remainingDays': remainingDays,
      };
}

/// Past subscription row.
class CustomerDetailSubscriptionHistoryItem {
  const CustomerDetailSubscriptionHistoryItem({
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.amountPaid,
    required this.completed,
  });

  final String planName;
  final String startDate;
  final String endDate;
  final double amountPaid;
  final bool completed;

  factory CustomerDetailSubscriptionHistoryItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return CustomerDetailSubscriptionHistoryItem(
      planName: json['planName']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      amountPaid: (json['amountPaid'] is num)
          ? (json['amountPaid'] as num).toDouble()
          : 0,
      completed: json['completed'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'planName': planName,
        'startDate': startDate,
        'endDate': endDate,
        'amountPaid': amountPaid,
        'completed': completed,
      };
}

/// Bundle: active plan + history list.
class CustomerDetailSubscriptionsBundle {
  const CustomerDetailSubscriptionsBundle({
    this.activePlan,
    required this.history,
  });

  final CustomerDetailActivePlan? activePlan;
  final List<CustomerDetailSubscriptionHistoryItem> history;

  factory CustomerDetailSubscriptionsBundle.fromJson(Map<String, dynamic> json) {
    CustomerDetailActivePlan? active;
    final ap = json['activePlan'];
    if (ap is Map<String, dynamic>) {
      active = CustomerDetailActivePlan.fromJson(ap);
    }
    final h = <CustomerDetailSubscriptionHistoryItem>[];
    final raw = json['history'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          h.add(CustomerDetailSubscriptionHistoryItem.fromJson(e));
        }
      }
    }
    return CustomerDetailSubscriptionsBundle(activePlan: active, history: h);
  }

  Map<String, dynamic> toJson() => {
        'activePlan': activePlan?.toJson(),
        'history': history.map((e) => e.toJson()).toList(),
      };
}
