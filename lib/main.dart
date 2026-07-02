import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/core/storage/impl/shared_preferences_auth_storage.dart';
import 'package:lovesync_mobile/features/call/data/datasources/call_remote_datasource.dart';
import 'package:lovesync_mobile/features/call/presentation/providers/call_provider.dart';
import 'package:lovesync_mobile/features/call/presentation/widgets/call_overlay.dart';
import 'package:lovesync_mobile/features/location/data/datasources/location_remote_datasource.dart';
import 'package:lovesync_mobile/features/location/presentation/providers/location_sharing_provider.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'app_router.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN');

  await Firebase.initializeApp();

  await _requestNotificationPermission();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(SharedPreferencesAuthStorage())..load(),
        ),
        Provider<DioClient>(
          create: (context) => DioClient(
            SharedPreferencesAuthStorage(),
            onUnauthorized: context.read<AuthProvider>().logout,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CallProvider>(
          create: (context) =>
              CallProvider(CallRemoteDatasource(context.read<DioClient>().dio)),
          update: (_, authProvider, callProvider) {
            callProvider?.updateAuth(
              token: authProvider.accessToken,
              userId: authProvider.userId,
            );
            return callProvider!;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, LocationSharingProvider>(
          create: (context) => LocationSharingProvider(
            LocationRemoteDatasource(context.read<DioClient>().dio),
          ),
          update: (_, authProvider, locationProvider) {
            unawaited(
              locationProvider?.updateAuth(
                token: authProvider.accessToken,
                userId: authProvider.userId,
              ),
            );
            return locationProvider!;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _requestNotificationPermission() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return MaterialApp.router(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN'), Locale('en')],
      routerConfig: AppRouter(authProvider).router,
      builder: (context, child) =>
          CallOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
