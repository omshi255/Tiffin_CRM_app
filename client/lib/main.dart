import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/router/app_router.dart';
import 'core/notifications/notification_badge_service.dart';
import 'services/notification_service.dart';

/// Must be a top-level function for background delivery when the app is terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await showLocalNotificationFromRemoteMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  AppRouter.onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  try {
    if (kIsWeb) {
      debugPrint(
        'Firebase/FCM skipped on web (needs FirebaseOptions). '
        'Run `dart pub global activate flutterfire_cli` then `flutterfire configure` '
        'and use DefaultFirebaseOptions in main.dart to enable.',
      );
    } else {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService().initLocalNotifications();
      await NotificationService().initFCM();
    }
  } catch (e, st) {
    debugPrint('Firebase/FCM init: $e\n$st');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await NotificationBadgeService.init();
  runApp(const ProviderScope(child: TiffinCrmApp()));
}
