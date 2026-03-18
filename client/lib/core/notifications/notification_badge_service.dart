import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/customer_portal/data/customer_portal_api.dart';
import '../../features/dashboard/data/notification_api.dart';

/// Global service to track unread notification count for all roles.
final class NotificationBadgeService {
  NotificationBadgeService._();

  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  static Timer? _timer;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _refresh();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      _refresh();
    });
  }

  static Future<void> _refresh() async {
    int total = 0;
    try {
      final res = await NotificationApi.getMyNotifications(
        page: 1,
        limit: 1,
        isRead: false,
      );
      final t = res['total'];
      if (t is int) total += t;
    } catch (_) {}

    try {
      final res = await CustomerPortalApi.getMyNotifications(
        page: 1,
        limit: 1,
        isRead: false,
      );
      final t = res['total'];
      if (t is int) total += t;
    } catch (_) {}

    if (unreadCount.value != total) {
      unreadCount.value = total;
    }
  }

  /// Force an immediate refresh from the server.
  static Future<void> refreshNow() => _refresh();

  /// Optimistically adjust the unread count (e.g. after delete).
  static void adjustBy(int delta) {
    final next = unreadCount.value + delta;
    unreadCount.value = next < 0 ? 0 : next;
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
    _initialized = false;
  }
}

