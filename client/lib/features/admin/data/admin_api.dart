import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/customer_model.dart';
import '../models/admin_stats_model.dart';
import '../../delivery/models/delivery_staff_model.dart';
import '../../plans/models/plan_model.dart';
import '../../items/models/item_model.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../../orders/models/order_model.dart';
import '../../payments/models/payment_model.dart';
import '../../payments/models/invoice_model.dart';

abstract final class AdminApi {
  static Future<AdminStatsModel> getStats() async {
    final response = await DioClient.instance.get(ApiEndpoints.adminStats);
    final data = parseData(response);
    if (data is! Map<String, dynamic>) throw ApiException('Invalid response');
    return AdminStatsModel.fromJson(data);
  }

  static Future<List<dynamic>> getVendors({
    int page = 1,
    int limit = 20,
    bool? isActive,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (isActive != null) query['isActive'] = isActive;
    final response = await DioClient.instance.get(
      ApiEndpoints.adminVendors,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is List) return data;
    if (data is Map && data['vendors'] is List) return data['vendors'] as List;
    return [];
  }

  static Future<List<CustomerModel>> getCustomers({
    int page = 1,
    int limit = 20,
    String? vendorId,
    String? status,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (vendorId != null) query['vendorId'] = vendorId;
    if (status != null) query['status'] = status;
    final response = await DioClient.instance.get(
      ApiEndpoints.adminCustomers,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => CustomerModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<DeliveryStaffModel>> getDeliveryStaff({
    int page = 1,
    int limit = 20,
    String? vendorId,
    bool? isActive,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (vendorId != null) query['vendorId'] = vendorId;
    if (isActive != null) query['isActive'] = isActive;
    final response = await DioClient.instance.get(
      ApiEndpoints.adminDeliveryStaff,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => DeliveryStaffModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<PlanModel>> getPlans({
    int page = 1,
    int limit = 20,
    String? vendorId,
    bool? isActive,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (vendorId != null) query['vendorId'] = vendorId;
    if (isActive != null) query['isActive'] = isActive;
    final response = await DioClient.instance.get(
      ApiEndpoints.adminPlans,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => PlanModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<ItemModel>> getItems({
    int page = 1,
    int limit = 20,
    String? vendorId,
    bool? isActive,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (vendorId != null) query['vendorId'] = vendorId;
    if (isActive != null) query['isActive'] = isActive;
    final response = await DioClient.instance.get(
      ApiEndpoints.adminItems,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => ItemModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<SubscriptionModel>> getSubscriptions({
    int page = 1,
    int limit = 20,
    String? vendorId,
    String? status,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (vendorId != null) query['vendorId'] = vendorId;
    if (status != null) query['status'] = status;
    final response = await DioClient.instance.get(
      ApiEndpoints.adminSubscriptions,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => SubscriptionModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<OrderModel>> getOrders({
    int page = 1,
    int limit = 20,
    String? vendorId,
    String? status,
    String? date,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (vendorId != null) query['vendorId'] = vendorId;
    if (status != null) query['status'] = status;
    if (date != null) query['date'] = date;
    final response = await DioClient.instance.get(
      ApiEndpoints.adminOrders,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => OrderModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<PaymentModel>> getPayments({
    int page = 1,
    int limit = 20,
    String? vendorId,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (vendorId != null) query['vendorId'] = vendorId;
    final response = await DioClient.instance.get(
      ApiEndpoints.adminPayments,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => PaymentModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<InvoiceModel>> getInvoices({
    int page = 1,
    int limit = 20,
    String? vendorId,
    String? paymentStatus,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (vendorId != null) query['vendorId'] = vendorId;
    if (paymentStatus != null) query['paymentStatus'] = paymentStatus;
    final response = await DioClient.instance.get(
      ApiEndpoints.adminInvoices,
      queryParameters: query,
    );
    final data = parseData(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => InvoiceModel.fromJson(e))
          .toList();
    }
    return [];
  }
}
