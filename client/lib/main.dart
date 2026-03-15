import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await _setupFcm();
  } catch (_) {}
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Foreground: notification can be shown via flutter_local_notifications if needed
  });
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null && message.data['route'] != null) {
        GoRouter.of(ctx).go(message.data['route'] as String);
      }
    });
  });
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null && initial.data['route'] != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null) {
        GoRouter.of(ctx).go(initial.data['route'] as String);
      }
    });
  }
}
