import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../core/auth/jwt_payload_reader.dart';
import '../core/config/onesignal_config.dart';
import '../core/router/app_router.dart';
import '../core/router/app_routes.dart';
import '../core/storage/secure_storage.dart';

/// Push delivery via OneSignal. Backend targets [external_id] = MongoDB User or Customer _id.
class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._();
  static final NotificationService _instance = NotificationService._();

  static bool _initialized = false;

  Future<void> initOneSignal() async {
    if (kIsWeb) {
      debugPrint('[OneSignal] skipped on web');
      return;
    }
    if (kOneSignalAppId.isEmpty) {
      debugPrint(
        '[OneSignal] kOneSignalAppId empty — set --dart-define=ONESIGNAL_APP_ID=...',
      );
      return;
    }
    if (_initialized) return;

    OneSignal.initialize(kOneSignalAppId);
    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      debugPrint('[OneSignal] click additionalData: $data');
      if (data == null) return;
      final map = Map<String, dynamic>.from(data);
      _navigateFromPayload(map);
    });

    _initialized = true;
    debugPrint('[OneSignal] initialized');
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx == null) return;
      final router = GoRouter.of(ctx);
      final screen = data['screen']?.toString();
      switch (screen) {
        case 'orderDetail':
        case 'wallet':
        case 'subscriptions':
          router.go(AppRoutes.customerHome);
          break;
        case 'myDeliveries':
          router.go(AppRoutes.deliveryDashboard);
          break;
        case 'home':
          router.go(AppRoutes.dashboard);
          break;
        default:
          final route = data['route']?.toString();
          if (route != null && route.isNotEmpty) {
            router.go(route);
          } else {
            router.go(AppRoutes.notifications);
          }
      }
    });
  }

  /// Match backend: customer pushes use Customer [_id]; vendor/staff/admin use User [_id] (JWT userId).
  Future<void> syncExternalIdAfterLogin() async {
    if (kIsWeb || !_initialized || kOneSignalAppId.isEmpty) return;
    try {
      final token = await SecureStorage.getAccessToken();
      final role = await SecureStorage.getUserRole();
      String? externalId;

      if (token != null && token.isNotEmpty) {
        final claims = readJwtPayload(token);
        if (role == 'customer') {
          final cid = claims['customerId']?.toString();
          if (cid != null && cid.isNotEmpty) externalId = cid;
        }
        externalId ??= claims['userId']?.toString();
      }
      externalId ??= await SecureStorage.getUserId();

      if (externalId != null && externalId.isNotEmpty) {
        await OneSignal.login(externalId);
        debugPrint('[OneSignal] login externalId=$externalId role=$role');
      }
    } catch (e) {
      debugPrint('[OneSignal] login error: $e');
    }
  }

  /// Kept name for existing call sites (OTP / login / splash).
  Future<void> registerTokenAfterLogin() async {
    await syncExternalIdAfterLogin();
  }

  static Future<void> logoutPushUser() async {
    if (kIsWeb || kOneSignalAppId.isEmpty) return;
    try {
      await OneSignal.logout();
      debugPrint('[OneSignal] logout');
    } catch (e) {
      debugPrint('[OneSignal] logout error: $e');
    }
  }
}
