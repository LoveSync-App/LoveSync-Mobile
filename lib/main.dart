import 'package:flutter/material.dart';
import 'package:lovesync_mobile/core/storage/impl/shared_preferences_auth_storage.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'app_router.dart';
import 'package:provider/provider.dart';

void main() {
  // runApp(const MyApp());
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(SharedPreferencesAuthStorage())..load(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp.router(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: AppRouter(authProvider).router,
    );
  }
}
