import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/customer_detail_delivery_model.dart';
import '../models/customer_detail_model.dart';
import '../models/customer_detail_subscription_model.dart';
import '../models/transaction_model.dart';

/// Low-level API client for customer-details routes (Dio + auth headers via [DioClient]).
abstract final class CustomerDetailService {
  static const String _prefix = '/customer-details';

  /// Throws [ApiException] on logical errors; [DioException] on transport errors.
  static Future<void> _ensureNetwork() async {
    final r = await Connectivity().checkConnectivity();
    final online = r.any(
      (x) =>
          x == ConnectivityResult.wifi ||
          x == ConnectivityResult.mobile ||
          x == ConnectivityResult.ethernet,
    );
    if (!online) {
      throw ApiException('No internet connection.', null);
    }
  }

  static dynamic _parse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'] as bool? ?? false;
      if (!success) {
        final msg =
            data['message'] as String? ?? data['error'] as String? ?? 'Failed';
        throw ApiException(msg, response.statusCode);
      }
      return data['data'];
    }
    throw ApiException('Invalid response', response.statusCode);
  }

  /// Fetches customer info for tab 1.
  static Future<CustomerDetailInfo> fetchInfo(String customerId) async {
    await _ensureNetwork();
    try {
      final res = await DioClient.instance.get('$_prefix/$customerId/info');
      final data = _parse(res);
      if (data is! Map<String, dynamic>) {
        throw ApiException('Invalid response', res.statusCode);
      }
      return CustomerDetailInfo.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Network error',
        e.response?.statusCode,
      );
    }
  }

  /// Fetches active plan + subscription history for tab 2.
  static Future<CustomerDetailSubscriptionsBundle> fetchSubscriptions(
    String customerId,
  ) async {
    await _ensureNetwork();
    try {
      final res =
          await DioClient.instance.get('$_prefix/$customerId/subscriptions');
      final data = _parse(res);
      if (data is! Map<String, dynamic>) {
        throw ApiException('Invalid response', res.statusCode);
      }
      return CustomerDetailSubscriptionsBundle.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Network error',
        e.response?.statusCode,
      );
    }
  }

  /// Fetches merged transactions for tab 3.
  static Future<List<CustomerDetailTransaction>> fetchTransactions(
    String customerId, {
    String? startDate,
    String? endDate,
  }) async {
    await _ensureNetwork();
    try {
      final res = await DioClient.instance.get(
        '$_prefix/$customerId/transactions',
        queryParameters: <String, dynamic>{
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );
      final data = _parse(res);
      if (data is! List) {
        throw ApiException('Invalid response', res.statusCode);
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(CustomerDetailTransaction.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Network error',
        e.response?.statusCode,
      );
    }
  }

  /// Fetches receipt payload for bottom sheet.
  static Future<CustomerDetailReceipt> fetchReceipt(
    String customerId,
    String transactionId,
  ) async {
    await _ensureNetwork();
    try {
      final res = await DioClient.instance.get(
        '$_prefix/$customerId/transactions/$transactionId/receipt',
      );
      final data = _parse(res);
      if (data is! Map<String, dynamic>) {
        throw ApiException('Invalid response', res.statusCode);
      }
      return CustomerDetailReceipt.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Network error',
        e.response?.statusCode,
      );
    }
  }

  /// Fetches wallet + subscription balances for tab 4.
  static Future<CustomerDetailBalance> fetchBalance(String customerId) async {
    await _ensureNetwork();
    try {
      final res = await DioClient.instance.get('$_prefix/$customerId/balance');
      final data = _parse(res);
      if (data is! Map<String, dynamic>) {
        throw ApiException('Invalid response', res.statusCode);
      }
      return CustomerDetailBalance.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Network error',
        e.response?.statusCode,
      );
    }
  }

  /// Posts wallet top-up.
  static Future<CustomerDetailBalance> addBalance(
    String customerId, {
    required double amount,
    required String paymentMode,
    String? note,
  }) async {
    await _ensureNetwork();
    try {
      final res = await DioClient.instance.post(
        '$_prefix/$customerId/add-balance',
        data: <String, dynamic>{
          'amount': amount,
          'paymentMode': paymentMode,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      _parse(res);
      return fetchBalance(customerId);
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Network error',
        e.response?.statusCode,
      );
    }
  }

  /// Posts extra charge (separate pending due or subscription deduction).
  static Future<Map<String, dynamic>> extraCharge(
    String customerId, {
    required double amount,
    required String note,
    required String chargeType,
  }) async {
    await _ensureNetwork();
    try {
      final res = await DioClient.instance.post(
        '$_prefix/$customerId/extra-charge',
        data: <String, dynamic>{
          'amount': amount,
          'note': note,
          'chargeType': chargeType,
        },
      );
      final data = _parse(res);
      if (data is! Map<String, dynamic>) {
        throw ApiException('Invalid response', res.statusCode);
      }
      return data;
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Network error',
        e.response?.statusCode,
      );
    }
  }

  /// Month list for tab 5.
  static Future<List<CustomerDetailDeliveryRow>> fetchDeliveries(
    String customerId, {
    required int month,
    required int year,
  }) async {
    await _ensureNetwork();
    try {
      final res = await DioClient.instance.get(
        '$_prefix/$customerId/deliveries',
        queryParameters: <String, dynamic>{
          'month': month.toString().padLeft(2, '0'),
          'year': year.toString(),
        },
      );
      final data = _parse(res);
      if (data is! List) {
        throw ApiException('Invalid response', res.statusCode);
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(CustomerDetailDeliveryRow.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Network error',
        e.response?.statusCode,
      );
    }
  }

  /// Cancels delivery for a calendar day (YYYY-MM-DD).
  static Future<void> cancelDelivery(
    String customerId,
    String ymd,
  ) async {
    await _ensureNetwork();
    try {
      final res = await DioClient.instance.patch(
        '$_prefix/$customerId/deliveries/$ymd/cancel',
      );
      _parse(res);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      throw ApiException(
        msg ?? e.message ?? 'Network error',
        e.response?.statusCode,
      );
    }
  }
}
