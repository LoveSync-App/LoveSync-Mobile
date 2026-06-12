import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:lovesync_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_code_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_days_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_scan_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/partner_info_page.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AppRouter {
  late final AuthProvider _authProvider;
  AppRouter(this._authProvider);

  GoRouter get router => GoRouter(
    refreshListenable: _authProvider,
    initialLocation: '/login',
    // initialLocation: '/couple/code',
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Đang Tải...'),
              ],
            ),
          ),
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: "/couple/code",
        builder: (context, state) => const CoupleCodePage(),
      ),
      GoRoute(
        path: "/couple/scan",
        builder: (context, state) => const CoupleScanPage(),
      ),
      GoRoute(
        path: "/couple/partner-info",
        builder: (context, state) =>
            PartnerInfoPage(partnerName: state.extra as String),
      ),
      GoRoute(
        path: "/couple/get-days",
        builder: (context, state) => const CoupleDaysPage(),
      ),
    ],
    redirect: (context, state) {
      final accessToken = context.read<AuthProvider>().accessToken;
      final isLoggingIn = context.read<AuthProvider>().isLoadingInit;

      if (isLoggingIn) {
        return '/loading';
      }

      if (state.matchedLocation == '/register' ||
          state.matchedLocation == '/login') {
        return null;
      }

      if (accessToken.isEmpty) {
        return '/login';
      }
    },
  );
}
