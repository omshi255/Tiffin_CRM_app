import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/customer_model.dart';

/// In-memory CRUD controller for customers.
/// Frontend only — no backend API. All data is stored locally in memory.
class CustomersNotifier extends ChangeNotifier {
  List<Customer> _customers = [];
  List<Customer> get customers => List.unmodifiable(_customers);

  static String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

  void addCustomer(Customer customer) {
    final newCustomer = Customer(
      id: _generateId(),
      fullName: customer.fullName,
      phoneNumber: customer.phoneNumber,
      email: customer.email,
    );
    _customers = [..._customers, newCustomer];
    notifyListeners();
  }

  void updateCustomer(Customer customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      _customers = [
        ..._customers.sublist(0, index),
        customer,
        ..._customers.sublist(index + 1),
      ];
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers = _customers.where((c) => c.id != id).toList();
    notifyListeners();
  }

  Customer? getById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

final customersProvider =
    ChangeNotifierProvider<CustomersNotifier>((_) => CustomersNotifier());
