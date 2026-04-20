import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/notifications/notification_badge_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  DioClient.setNavigatorKey(AppRouter.navigatorKey);
  try {
    await dotenv.load(fileName: 'assets/config/onesignal.env');
  } catch (e, st) {
    if (kDebugMode) debugPrint('dotenv load onesignal.env: $e\n$st');
  }
  final prefs = await SharedPreferences.getInstance();
  AppRouter.onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  try {
    if (kIsWeb) {
      if (kDebugMode) debugPrint('[OneSignal] Push not initialized on web.');
    } else {
      await NotificationService().initOneSignal();
    }
  } catch (e, st) {
    if (kDebugMode) debugPrint('OneSignal init: $e\n$st');
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
