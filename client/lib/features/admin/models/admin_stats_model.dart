class AdminStatsModel {
  const AdminStatsModel({
    this.totalVendors = 0,
    this.totalCustomers = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.todayOrders = 0,
    this.todayRevenue = 0,
    this.activeSubscriptions = 0,
    this.pendingOrders = 0,
  });

  final int totalVendors;
  final int totalCustomers;
  final int totalOrders;
  final double totalRevenue;
  final int todayOrders;
  final double todayRevenue;
  final int activeSubscriptions;
  final int pendingOrders;

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalVendors: (json['totalVendors'] is num)
          ? (json['totalVendors'] as num).toInt()
          : 0,
      totalCustomers: (json['totalCustomers'] is num)
          ? (json['totalCustomers'] as num).toInt()
          : 0,
      totalOrders: (json['totalOrders'] is num)
          ? (json['totalOrders'] as num).toInt()
          : 0,
      totalRevenue: (json['totalRevenue'] is num)
          ? (json['totalRevenue'] as num).toDouble()
          : 0,
      todayOrders: (json['todayOrders'] is num)
          ? (json['todayOrders'] as num).toInt()
          : 0,
      todayRevenue: (json['todayRevenue'] is num)
          ? (json['todayRevenue'] as num).toDouble()
          : 0,
      activeSubscriptions: (json['activeSubscriptions'] is num)
          ? (json['activeSubscriptions'] as num).toInt()
          : 0,
      pendingOrders: (json['pendingOrders'] is num)
          ? (json['pendingOrders'] as num).toInt()
          : 0,
    );
  }
}
