import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/router/app_router.dart';
import '../core/router/app_routes.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/data/auth_api.dart';

/// Android notification channel — must match [AndroidManifest] meta-data and server FCM `channelId`.
const String kTiffinCrmNotificationChannelId = 'tiffin_crm_channel';

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Top-level background handler calls this after [Firebase.initializeApp].
Future<void> showLocalNotificationFromRemoteMessage(RemoteMessage message) async {
  debugPrint(
    '[FCM DEBUG] showLocalNotificationFromRemoteMessage '
    'messageId=${message.messageId} dataKeys=${message.data.keys.toList()}',
  );
  await _ensureLocalNotificationsReady();
  await showLocalNotification(message);
}

Future<void> _ensureLocalNotificationsReady() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
  );
  const settings = InitializationSettings(android: android, iOS: ios);
  await _flutterLocalNotificationsPlugin.initialize(settings: settings);
  if (defaultTargetPlatform == TargetPlatform.android) {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            kTiffinCrmNotificationChannelId,
            'Tiffin CRM Notifications',
            description: 'Order updates, payments, and alerts',
            importance: Importance.max,
          ),
        );
  }
}

Future<void> showLocalNotification(RemoteMessage message) async {
  final title = message.notification?.title ??
      message.data['title'] as String? ??
      'Tiffin CRM';
  final body = message.notification?.body ??
      message.data['message'] as String? ??
      message.data['body'] as String? ??
      '';
  final route =
      message.data['route'] as String? ?? AppRoutes.notifications;
  debugPrint(
    '[FCM DEBUG] showLocalNotification title="$title" bodyLen=${body.length} route=$route',
  );

  const androidDetails = AndroidNotificationDetails(
    kTiffinCrmNotificationChannelId,
    'Tiffin CRM Notifications',
    channelDescription: 'Order updates, payments, and alerts',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
  final id = message.messageId?.hashCode ?? (message.hashCode & 0x7FFFFFFF);
  try {
    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: route,
    );
    debugPrint('[FCM DEBUG] flutter_local_notifications.show completed id=$id');
  } catch (e, st) {
    debugPrint('[FCM DEBUG] flutter_local_notifications.show FAILED: $e\n$st');
    rethrow;
  }
}

/// Foreground + cold start: wire tap handling and channels.
class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._();
  static final NotificationService _instance = NotificationService._();

  static bool _localInitialized = false;
  static bool _fcmListenersAttached = false;

  /// Call from [main] after [Firebase.initializeApp] (not from background isolate).
  Future<void> initLocalNotifications() async {
    if (_localInitialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _flutterLocalNotificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = AppRouter.navigatorKey.currentContext;
            if (ctx != null) {
              GoRouter.of(ctx).go(response.payload!);
            }
          });
        }
      },
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              kTiffinCrmNotificationChannelId,
              'Tiffin CRM Notifications',
              description: 'Order updates, payments, and alerts',
              importance: Importance.max,
            ),
          );
    }
    _localInitialized = true;
  }

  Future<void> _requestAndroidPostNotifications() async {
    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  /// Registers FCM token, syncs to backend, and attaches listeners (once).
  Future<void> initFCM() async {
    debugPrint('[FCM DEBUG] initFCM() start');
    await _requestAndroidPostNotifications();

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    await _syncTokenBestEffort();
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] token refreshed: $newToken');
      _saveTokenToBackend(newToken);
    });

    if (!_fcmListenersAttached) {
      _fcmListenersAttached = true;
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[FCM DEBUG] onMessage (foreground) '
          'messageId=${message.messageId} '
          'notification=${message.notification?.title}',
        );
        showLocalNotificationFromRemoteMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '[FCM DEBUG] onMessageOpenedApp '
          'messageId=${message.messageId} data=${message.data}',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = AppRouter.navigatorKey.currentContext;
          if (ctx == null) return;
          final route = message.data['route'] as String?;
          if (route != null && route.isNotEmpty) {
            GoRouter.of(ctx).go(route);
          } else {
            GoRouter.of(ctx).go(AppRoutes.notifications);
          }
        });
      });

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        debugPrint(
          '[FCM DEBUG] getInitialMessage (cold start) '
          'messageId=${initial.messageId}',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = AppRouter.navigatorKey.currentContext;
          if (ctx == null) return;
          final route = initial.data['route'] as String?;
          GoRouter.of(ctx).go(route ?? AppRoutes.notifications);
        });
      }
    }
    debugPrint('[FCM DEBUG] initFCM() finished (listeners attached=$_fcmListenersAttached)');
  }

  Future<void> _saveTokenToBackend(String token) async {
    if (token.isEmpty) {
      debugPrint('[FCM DEBUG] _saveTokenToBackend skipped: empty token');
      return;
    }
    try {
      final access = await SecureStorage.getAccessToken();
      if (access != null && access.isNotEmpty) {
        await AuthApi.saveFcmToken(token);
        debugPrint(
          '[FCM DEBUG] _saveTokenToBackend OK '
          'tokenPrefix=${token.length > 24 ? token.substring(0, 24) : token}...',
        );
      } else {
        debugPrint(
          '[FCM DEBUG] _saveTokenToBackend skipped: no access token (login first)',
        );
      }
    } catch (e) {
      debugPrint('[FCM DEBUG] _saveTokenToBackend error: $e');
    }
  }

  Future<void> _syncTokenBestEffort() async {
    for (var i = 0; i < 3; i++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          debugPrint('[FCM] device token: $token');
          await _saveTokenToBackend(token);
          return;
        }
      } catch (e) {
        debugPrint('[FCM] getToken error: $e');
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  /// After OTP / Truecaller login — token is saved with fresh auth headers.
  Future<void> registerTokenAfterLogin() async {
    if (kIsWeb) return;
    await _syncTokenBestEffort();
  }
}
