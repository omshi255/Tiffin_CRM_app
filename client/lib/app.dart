import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class TiffinCrmApp extends ConsumerWidget {
  const TiffinCrmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DioClient.setNavigatorKey(AppRouter.navigatorKey);
    return MaterialApp.router(
      title: 'TiffinCRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
