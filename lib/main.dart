import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/core/storage/impl/shared_preferences_auth_storage.dart';
import 'package:lovesync_mobile/features/call/data/datasources/call_remote_datasource.dart';
import 'package:lovesync_mobile/features/call/data/repositories/call_repository_impl.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/accept_call.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/cancel_call.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/end_call.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/get_active_call.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/issue_call_token.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/reject_call.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/start_call.dart';
import 'package:lovesync_mobile/features/call/presentation/providers/call_provider.dart';
import 'package:lovesync_mobile/features/call/presentation/widgets/call_overlay.dart';
import 'package:lovesync_mobile/features/location/data/datasources/location_remote_datasource.dart';
import 'package:lovesync_mobile/features/location/data/repositories/location_repository_impl.dart';
import 'package:lovesync_mobile/features/location/domain/usecases/get_live_locations.dart';
import 'package:lovesync_mobile/features/location/domain/usecases/post_send_location_snapshot.dart';
import 'package:lovesync_mobile/features/location/domain/usecases/post_start_live_location.dart';
import 'package:lovesync_mobile/features/location/domain/usecases/post_stop_live_location.dart';
import 'package:lovesync_mobile/features/location/domain/usecases/put_update_live_location.dart';
import 'package:lovesync_mobile/features/location/presentation/providers/location_sharing_provider.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'app_router.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(SharedPreferencesAuthStorage())..load(),
        ),
        Provider<DioClient>(
          create: (context) => DioClient(
            SharedPreferencesAuthStorage(),
            onUnauthorized: context.read<AuthProvider>().handleUnauthorized,
            onTokenRefreshed: context.read<AuthProvider>().updateTokenPair,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CallProvider>(
          create: (context) {
            final repository = CallRepositoryImpl(
              CallRemoteDatasource(context.read<DioClient>().dio),
            );
            return CallProvider(
              startCall: StartCall(repository),
              acceptCall: AcceptCall(repository),
              rejectCall: RejectCall(repository),
              cancelCall: CancelCall(repository),
              endCall: EndCall(repository),
              getActiveCall: GetActiveCall(repository),
              issueCallToken: IssueCallToken(repository),
              onSessionRevoked: context.read<AuthProvider>().invalidateSession,
            );
          },
          update: (_, authProvider, callProvider) {
            callProvider?.updateAuth(
              token: authProvider.accessToken,
              userId: authProvider.userId,
            );
            return callProvider!;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, LocationSharingProvider>(
          create: (context) {
            final repository = LocationRepositoryImpl(
              LocationRemoteDatasource(context.read<DioClient>().dio),
            );
            return LocationSharingProvider(
              getLiveLocations: GetLiveLocations(repository),
              postSendLocationSnapshot: PostSendLocationSnapshot(repository),
              postStartLiveLocation: PostStartLiveLocation(repository),
              postStopLiveLocation: PostStopLiveLocation(repository),
              putUpdateLiveLocation: PutUpdateLiveLocation(repository),
            );
          },
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

  unawaited(_initializePostAppServices());
}

Future<void> _initializePostAppServices() async {
  try {
    await initializeDateFormatting('vi_VN');
    await _requestNotificationPermission();
  } catch (error, stackTrace) {
    debugPrint('Không thể khởi tạo Firebase: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
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
