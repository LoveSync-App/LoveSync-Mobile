import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:lovesync_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:lovesync_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:lovesync_mobile/features/calendar/presentation/pages/calendar_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_code_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_confirmation_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_days_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_scan_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/partner_info_page.dart';
import 'package:lovesync_mobile/features/location/presentation/pages/live_location_page.dart';
import 'package:lovesync_mobile/features/location/presentation/pages/location_preview_page.dart';
import 'package:lovesync_mobile/features/location/presentation/pages/location_snapshot_page.dart';
import 'package:lovesync_mobile/features/memory/presentation/pages/memory_capture_page.dart';
import 'package:lovesync_mobile/features/memory/presentation/pages/memory_list_page.dart';
import 'package:lovesync_mobile/features/message/presentation/pages/network_video_viewer_page.dart';
import 'package:lovesync_mobile/features/message/presentation/pages/realtime_message_page.dart';
import 'package:lovesync_mobile/features/user/presentation/pages/profile_page.dart';
import 'package:lovesync_mobile/shared/widgets/couple_shell_scaffold.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';

class AppRouter {
  late final AuthProvider _authProvider;
  AppRouter(this._authProvider);

  GoRouter get router => GoRouter(
    refreshListenable: _authProvider,
    // initialLocation: '/couple/partner-info',
    initialLocation: AppRoutes.login,
    // initialLocation: '/couple/code',
    routes: [
      GoRoute(
        path: AppRoutes.loading,
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
      GoRoute(
        path: AppRoutes.coupleScan,
        builder: (context, state) => const CoupleScanPage(),
      ),
      GoRoute(
        path: AppRoutes.couplePartnerInfo,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PartnerInfoPage(
            partnerCode: extra['partnerCode'] as String,
            partnerName: extra['partnerName'] as String,
            partnerAvatarUrl: extra['partnerAvatarUrl'] as String,
            userFullName: extra['userFullName'] as String,
            userAvatarUrl: extra['userAvatarUrl'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.coupleConfirmation,
        builder: (context, state) => const CoupleConfirmationPage(),
      ),
      GoRoute(
        path: AppRoutes.memoryCreate,
        builder: (context, state) => const MemoryCapturePage(),
      ),
      GoRoute(path: AppRoutes.login, builder: (context, state) => LoginPage()),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.message,
        builder: (context, state) => const RealtimeMessagePage(),
      ),
      GoRoute(
        path: AppRoutes.locationPreview,
        builder: (context, state) => const LocationPreviewPage(),
      ),
      GoRoute(
        path: AppRoutes.locationLive,
        builder: (context, state) => const LiveLocationPage(),
      ),
      GoRoute(
        path: AppRoutes.locationSnapshot,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! LocationSnapshotRouteExtra) {
            return const Scaffold(
              body: Center(child: Text('Thiếu dữ liệu vị trí')),
            );
          }
          return LocationSnapshotPage(
            latitude: extra.latitude,
            longitude: extra.longitude,
            address: extra.address,
            label: extra.label,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.messageVideoViewer,
        builder: (context, state) {
          final extra = state.extra;
          final url = extra is Map ? extra['url']?.toString() : null;
          if (url == null || url.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Thiếu đường dẫn video')),
            );
          }
          return NetworkVideoViewerPage(url: url);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CoupleShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.couple,
                builder: (context, state) => const CoupleDaysPage(),
                routes: [
                  GoRoute(
                    path: 'code',
                    builder: (context, state) => const CoupleCodePage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.memories,
                builder: (context, state) => MemoryListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.anniversaries,
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final accessToken = _authProvider.accessToken;
      final isLoadingInit = _authProvider.isLoadingInit;

      final location = state.matchedLocation;

      final isAuthPage =
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.forgotPassword;

      if (isLoadingInit) {
        return location == AppRoutes.loading ? null : AppRoutes.loading;
      }

      if (location == AppRoutes.loading) {
        return accessToken.isNotEmpty ? AppRoutes.couple : AppRoutes.login;
      }

      if (accessToken.isEmpty && !isAuthPage) {
        return AppRoutes.login;
      }

      if (accessToken.isNotEmpty && isAuthPage) {
        return AppRoutes.couple;
      }

      return null;
    },
  );
}
