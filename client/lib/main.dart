import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'app.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/notifications/notification_badge_service.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/data/auth_api.dart';
import 'features/customer_portal/data/customer_portal_api.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Show in-app (foreground) notification when FCM message is received.
Future<void> _showForegroundNotification(RemoteMessage message) async {
  final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
  final body = message.notification?.body ?? message.data['message'] ?? '';
  final route = message.data['route'] as String? ?? AppRoutes.notifications;
  const androidDetails = AndroidNotificationDetails(
    'fcm_foreground_channel',
    'App Notifications',
    channelDescription: 'Notifications when app is open',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  const details = NotificationDetails(android: androidDetails);
  final id = (message.hashCode & 0x7FFFFFFF);
  await _localNotifications.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
    payload: route,
  );
}

Future<void> _initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
  );
  const settings = InitializationSettings(android: android, iOS: ios);
  await _localNotifications.initialize(
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
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'fcm_foreground_channel',
          'App Notifications',
          description: 'Notifications when app is open',
          importance: Importance.defaultImportance,
        ));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  AppRouter.onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
  try {
    await Firebase.initializeApp();
    await _initLocalNotifications();
    await _setupFcm();
  } catch (_) {}
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await NotificationBadgeService.init();
  runApp(const ProviderScope(child: TiffinCrmApp()));
}

Future<void> _setupFcm() async {
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (_) {}

  Future<void> syncToken(String token) async {
    if (token.isEmpty) return;
    try {
      final role = await SecureStorage.getUserRole();
      if (role == 'customer') {
        await CustomerPortalApi.updateMyProfile({'fcmToken': token});
      } else if (role != null && role.isNotEmpty) {
        await AuthApi.updateProfile({'fcmToken': token});
      }
    } catch (_) {}
  }

  // Best-effort initial sync on app start (getToken can be null initially).
  for (var i = 0; i < 3; i++) {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await syncToken(token);
        break;
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  // Keep token in sync (FCM can rotate tokens).
  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    await syncToken(token);
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showForegroundNotification(message);
  });
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null && message.data['route'] != null) {
        GoRouter.of(ctx).go(message.data['route'] as String);
      } else if (ctx != null) {
        GoRouter.of(ctx).go(AppRoutes.notifications);
      }
    });
  });
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null) {
        final route = initial.data['route'] as String?;
        GoRouter.of(ctx).go(route ?? AppRoutes.notifications);
      }
    });
  }
}
