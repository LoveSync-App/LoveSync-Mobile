import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:lovesync_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:lovesync_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_code_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_confirmation_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_days_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/couple_scan_page.dart';
import 'package:lovesync_mobile/features/couple/presentation/pages/partner_info_page.dart';
import 'package:lovesync_mobile/features/memory/presentation/pages/create_memory_page.dart';
import 'package:lovesync_mobile/features/memory/presentation/pages/memory_list_page.dart';
import 'package:lovesync_mobile/features/message/presentation/pages/realtime_message_page.dart';
import 'package:lovesync_mobile/features/user/presentation/pages/profile_page.dart';
import 'package:lovesync_mobile/shared/widgets/couple_shell_scaffold.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AppRouter {
  late final AuthProvider _authProvider;
  AppRouter(this._authProvider);

  GoRouter get router => GoRouter(
    refreshListenable: _authProvider,
    // initialLocation: '/couple/partner-info',
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
      GoRoute(
        path: "/couple/scan",
        builder: (context, state) => const CoupleScanPage(),
      ),
      GoRoute(
        path: "/couple/partner-info",
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
        path: '/couple/confirmation',
        builder: (context, state) => const CoupleConfirmationPage(),
      ),
      GoRoute(
        path: '/memory/create',
        builder: (context, state) => const CreateMemoryPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/message',
        builder: (context, state) => const RealtimeMessagePage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CoupleShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/couple',
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
                path: "/memories",
                builder: (context, state) => MemoryListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                // Ngày kỹ niệm
                path: "/anniversaries",
                builder: (context, state) => const _ComingSoonTabPage(
                  icon: Icons.calendar_today,
                  title: 'Ngày Kỹ Niệm',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/settings",
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
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';

      if (isLoadingInit) {
        return location == '/loading' ? null : '/loading';
      }

      if (location == '/loading') {
        return accessToken.isNotEmpty ? '/couple' : '/login';
      }

      if (accessToken.isEmpty && !isAuthPage) {
        return '/login';
      }

      if (accessToken.isNotEmpty && isAuthPage) {
        return '/couple';
      }

      return null;
    },
  );
}

class _ComingSoonTabPage extends StatelessWidget {
  const _ComingSoonTabPage({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFFA03B56)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                },
                child: const Text("Đăng Xuất"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
