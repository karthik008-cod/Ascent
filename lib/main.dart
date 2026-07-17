import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const ProviderScope(child: AscentApp()));
}

class AscentApp extends ConsumerWidget {
  const AscentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Ascent',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Dark mode first
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
