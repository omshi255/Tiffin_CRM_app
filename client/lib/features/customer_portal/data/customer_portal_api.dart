import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/customer_model.dart';
import '../../orders/models/order_model.dart';
import '../../subscriptions/models/subscription_model.dart';

abstract final class CustomerPortalApi {
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
}

