import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/CoupleCodePage.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/CoupleScanPage.dart';

class AppRouter {
  GoRouter get router => GoRouter(
    // initialLocation: '/',
    initialLocation: '/couple/code',
    routes: [
      GoRoute(
        path: "/couple/code",
        builder: (context, state) => const CoupleCodePage(),
      ),
      GoRoute(
        path: "/couple/scan",
        builder: (context, state) => const CoupleScanPage(),
      ),
    ],
  );
}
