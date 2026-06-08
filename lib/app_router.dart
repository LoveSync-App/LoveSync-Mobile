import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_code_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_scan_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/partner_info_page.dart';

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
      GoRoute(
        path: "/couple/partner-info",
        builder: (context, state) =>
            PartnerInfoPage(partnerName: state.extra as String),
      ),
    ],
  );
}
