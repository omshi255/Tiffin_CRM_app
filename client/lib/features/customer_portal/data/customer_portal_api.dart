import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/customer_model.dart';
import '../../../models/notification_model.dart';
import '../../orders/models/order_model.dart';
import '../../subscriptions/models/subscription_model.dart';

abstract final class CustomerPortalApi {
  static Future<CustomerBalanceModel> _getMyBalanceFallback() async {
    final profileRes = await DioClient.instance.get(ApiEndpoints.customerMe);
    final profileData = parseData(profileRes);
    if (profileData is! Map<String, dynamic>) {
      throw ApiException('Invalid response');
    }

    final walletBalance = (profileData['walletBalance'] is num)
        ? (profileData['walletBalance'] as num).toDouble()
        : (profileData['balance'] is num)
            ? (profileData['balance'] as num).toDouble()
            : 0.0;

    double subscriptionBalance = 0.0;
    try {
      final planRes = await DioClient.instance.get(ApiEndpoints.customerMePlan);
      final planData = parseData(planRes);
      if (planData is Map<String, dynamic>) {
        if (planData['remainingBalance'] is num) {
          subscriptionBalance = (planData['remainingBalance'] as num).toDouble();
        } else {
          final total = (planData['totalAmount'] is num)
              ? (planData['totalAmount'] as num).toDouble()
              : 0.0;
          final paid = (planData['paidAmount'] is num)
              ? (planData['paidAmount'] as num).toDouble()
              : 0.0;
          subscriptionBalance = (total - paid).clamp(0, double.infinity);
        }
      }
    } catch (_) {
      subscriptionBalance = 0.0;
    }

    return CustomerBalanceModel(
      walletBalance: walletBalance,
      subscriptionBalance: subscriptionBalance,
    );
  }

  static Future<CustomerModel> getMyProfile() async {
    final response = await DioClient.instance.get(ApiEndpoints.customerMe);
    final data = parseData(response);
    if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
    return CustomerModel.fromJson(data);
  }

  static Future<CustomerModel> updateMyProfile(Map<String, dynamic> body) async {
    final response = await DioClient.instance.put(
      ApiEndpoints.customerMe,
      data: body,
    );
    final data = parseData(response);
    if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
    return CustomerModel.fromJson(data);
  }

  static Future<CustomerBalanceModel> getMyBalance() async {
    // Use fallback-only path for now to avoid any /customer/me/balance probing
    // against production where the endpoint is not deployed yet.
    return _getMyBalanceFallback();
  }

  static Future<SubscriptionModel?> getMyActivePlan() async {
    final response = await DioClient.instance.get(ApiEndpoints.customerMePlan);
    final data = parseData(response);
    if (data == null) return null;
    if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
    return SubscriptionModel.fromJson(data);
  }

  // Returns a map with keys: orders (List<OrderModel>), total (int), page (int), totalPages (int)
  static Future<Map<String, dynamic>> getMyOrders({
    int page = 1,
    int limit = 20,
    String? status,
    String? date,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (date != null && date.isNotEmpty) query['date'] = date;
    final response = await DioClient.instance.get(
      ApiEndpoints.customerMeOrders,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is! Map<String, dynamic>) {
      return {'orders': <OrderModel>[], 'total': 0, 'page': page, 'totalPages': 0};
    }
    final list = data['data'] is List ? data['data'] as List : [];
    final orders = list
        .whereType<Map<String, dynamic>>()
        .map((e) => OrderModel.fromJson(e))
        .toList();
    final total = (data['total'] is num) ? (data['total'] as num).toInt() : orders.length;
    final currentPage = (data['page'] is num) ? (data['page'] as num).toInt() : page;
    final totalPages =
        (data['totalPages'] is num) ? (data['totalPages'] as num).toInt() : 1;
    return {
      'orders': orders,
      'total': total,
      'page': currentPage,
      'totalPages': totalPages,
    };
  }

  /// Today's order (first order for today).
  static Future<OrderModel?> getTodayOrder() async {
    final res = await getMyOrders(page: 1, limit: 20);
    final orders = res['orders'] as List<OrderModel>? ?? [];
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    for (final o in orders) {
      final od = DateTime(o.date.year, o.date.month, o.date.day);
      if (od == today) return o;
    }
    return null;
  }

  /// Notifications for the logged-in customer.
  static Future<Map<String, dynamic>> getMyNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (isRead != null) query['isRead'] = isRead;
    final response = await DioClient.instance.get(
      ApiEndpoints.customerMeNotifications,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is! Map<String, dynamic>) {
      return {
        'notifications': <NotificationModel>[],
        'total': 0,
        'page': page,
        'totalPages': 0,
      };
    }
    final list = data['data'] is List ? data['data'] as List : [];
    final notifications = list
        .whereType<Map<String, dynamic>>()
        .map((e) => NotificationModel.fromJson(e))
        .toList();
    final total = (data['total'] is num) ? (data['total'] as num).toInt() : 0;
    final currentPage = (data['page'] is num) ? (data['page'] as num).toInt() : page;
    final totalPages =
        (data['totalPages'] is num) ? (data['totalPages'] as num).toInt() : 1;
    return {
      'notifications': notifications,
      'total': total,
      'page': currentPage,
      'totalPages': totalPages,
    };
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await DioClient.instance.patch(
      ApiEndpoints.customerMeNotificationMarkRead(notificationId),
    );
  }

  static Future<void> deleteNotification(String notificationId) async {
    await DioClient.instance.delete(
      ApiEndpoints.customerMeNotificationById(notificationId),
    );
  }

  static Future<void> clearReadNotifications() async {
    await DioClient.instance.delete(
      ApiEndpoints.customerMeNotificationsClearRead,
    );
  }

  static Future<void> markAllNotificationsRead() async {
    await DioClient.instance.patch(
      '${ApiEndpoints.customerMeNotifications}/read-all',
    );
  }
}

