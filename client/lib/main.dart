import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/router/app_router.dart';
import 'core/notifications/notification_badge_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  AppRouter.onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  try {
    if (kIsWeb) {
      debugPrint('[OneSignal] Push not initialized on web.');
    } else {
      await NotificationService().initOneSignal();
    }
  } catch (e, st) {
    debugPrint('OneSignal init: $e\n$st');
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
