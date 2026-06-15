import 'package:flutter/material.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/core/storage/impl/shared_preferences_auth_storage.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'app_router.dart';
import 'package:provider/provider.dart';

void main() {
  // runApp(const MyApp());
  runApp(
      MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(SharedPreferencesAuthStorage())..load(),
        ),
        Provider<DioClient>(
          create: (_) => DioClient(SharedPreferencesAuthStorage()),
        ),
      ],
      child: const MyApp(),
    ),
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
      routerConfig: AppRouter(authProvider).router,
    );
  }
}
