import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:lovesync_mobile/features/calendar/domain/usecases/create_calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/domain/usecases/delete_calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/domain/usecases/update_calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/presentation/pages/calendar_event_form_page.dart';
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
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'package:lovesync_mobile/shared/widgets/couple_shell_scaffold.dart';
import 'package:provider/provider.dart';

class AppRouter {
  AppRouter(this._authProvider);

  final AuthProvider _authProvider;

  GoRouter get router => GoRouter(
    refreshListenable: _authProvider,
    initialLocation: AppRoutePaths.authLogin,
    routes: [
      ..._legacyRedirectRoutes,
      _loadingRoute,
      ..._authRoutes,
      ..._coupleRoutes,
      ..._memoryRoutes,
      ..._calendarEventRoutes,
      ..._chatRoutes,
      ..._locationRoutes,
      _mainShellRoute,
    ],
    redirect: _guardByAuthState,
  );

  GoRoute get _loadingRoute => GoRoute(
    path: AppRoutePaths.loading,
    builder: (context, state) => const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Đang tải...'),
          ],
        ),
      ),
    ),
  );

  List<GoRoute> get _authRoutes => [
    GoRoute(
      path: AppRoutePaths.authLogin,
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: AppRoutePaths.authRegister,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutePaths.authForgotPassword,
      builder: (context, state) => const ForgotPasswordPage(),
    ),
  ];

  List<GoRoute> get _coupleRoutes => [
    GoRoute(
      path: AppRoutePaths.coupleScan,
      builder: (context, state) => const CoupleScanPage(),
    ),
    GoRoute(
      path: AppRoutePaths.couplePartnerInfo,
      builder: (context, state) => _buildPartnerInfoPage(state),
    ),
    GoRoute(
      path: AppRoutePaths.coupleInvitations,
      builder: (context, state) => const CoupleConfirmationPage(),
    ),
  ];

  List<GoRoute> get _memoryRoutes => [
    GoRoute(
      path: AppRoutePaths.memoryCreate,
      builder: (context, state) => const MemoryCapturePage(),
    ),
  ];

  List<GoRoute> get _calendarEventRoutes => [
    GoRoute(
      path: AppRoutePaths.calendarEventCreate,
      builder: (context, state) => _buildCalendarEventFormPage(context, state),
    ),
    GoRoute(
      path: AppRoutePaths.calendarEventDetail,
      builder: (context, state) => _buildCalendarEventFormPage(context, state),
    ),
  ];

  List<GoRoute> get _chatRoutes => [
    GoRoute(
      path: AppRoutePaths.chat,
      builder: (context, state) => const RealtimeMessagePage(),
    ),
    GoRoute(
      path: AppRoutePaths.chatVideoViewer,
      builder: (context, state) => _buildChatVideoViewerPage(state),
    ),
  ];

  List<GoRoute> get _locationRoutes => [
    GoRoute(
      path: AppRoutePaths.locationSnapshotPreview,
      builder: (context, state) => const LocationPreviewPage(),
    ),
    GoRoute(
      path: AppRoutePaths.locationLiveMap,
      builder: (context, state) => const LiveLocationPage(),
    ),
    GoRoute(
      path: AppRoutePaths.locationSnapshotViewer,
      builder: (context, state) => _buildLocationSnapshotPage(state),
    ),
  ];

  StatefulShellRoute get _mainShellRoute => StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        CoupleShellScaffold(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutePaths.coupleHome,
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
            path: AppRoutePaths.memoryList,
            builder: (context, state) => MemoryListPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutePaths.calendar,
            builder: (context, state) => const CalendarPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutePaths.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );

  List<GoRoute> get _legacyRedirectRoutes => [
    _redirect(LegacyAppRoutePaths.login, AppRoutePaths.authLogin),
    _redirect(LegacyAppRoutePaths.register, AppRoutePaths.authRegister),
    _redirect(
      LegacyAppRoutePaths.forgotPassword,
      AppRoutePaths.authForgotPassword,
    ),
    _redirect(
      LegacyAppRoutePaths.coupleConfirmation,
      AppRoutePaths.coupleInvitations,
    ),
    _redirect(LegacyAppRoutePaths.memoryCreate, AppRoutePaths.memoryCreate),
    _redirect(LegacyAppRoutePaths.anniversaries, AppRoutePaths.calendar),
    _redirect(LegacyAppRoutePaths.settings, AppRoutePaths.profile),
    _redirect(LegacyAppRoutePaths.message, AppRoutePaths.chat),
    _redirect(
      LegacyAppRoutePaths.locationPreview,
      AppRoutePaths.locationSnapshotPreview,
    ),
    _redirect(LegacyAppRoutePaths.locationLive, AppRoutePaths.locationLiveMap),
    _redirect(
      LegacyAppRoutePaths.locationSnapshot,
      AppRoutePaths.locationSnapshotViewer,
    ),
    _redirect(
      LegacyAppRoutePaths.messageVideoViewer,
      AppRoutePaths.chatVideoViewer,
    ),
  ];

  GoRoute _redirect(String legacyPath, String targetPath) {
    return GoRoute(path: legacyPath, redirect: (context, state) => targetPath);
  }

  String? _guardByAuthState(BuildContext context, GoRouterState state) {
    final accessToken = _authProvider.accessToken;
    final isLoadingInit = _authProvider.isLoadingInit;
    final location = state.matchedLocation;
    final isAuthPage = _authPaths.contains(location);

    if (isLoadingInit) {
      return location == AppRoutePaths.loading ? null : AppRoutePaths.loading;
    }

    if (location == AppRoutePaths.loading) {
      return accessToken.isNotEmpty
          ? AppRoutePaths.coupleHome
          : AppRoutePaths.authLogin;
    }

    if (accessToken.isEmpty && !isAuthPage) {
      return AppRoutePaths.authLogin;
    }

    if (accessToken.isNotEmpty && isAuthPage) {
      return AppRoutePaths.coupleHome;
    }

    return null;
  }

  Set<String> get _authPaths => {
    AppRoutePaths.authLogin,
    AppRoutePaths.authRegister,
    AppRoutePaths.authForgotPassword,
  };

  Widget _buildPartnerInfoPage(GoRouterState state) {
    final extra = state.extra;
    if (extra is! Map<String, dynamic>) {
      return const _MissingRouteExtraPage(message: 'Thiếu dữ liệu ghép đôi');
    }
    return PartnerInfoPage(
      partnerCode: extra['partnerCode'] as String,
      partnerName: extra['partnerName'] as String,
      partnerAvatarUrl: extra['partnerAvatarUrl'] as String,
      userFullName: extra['userFullName'] as String,
      userAvatarUrl: extra['userAvatarUrl'] as String,
    );
  }

  Widget _buildLocationSnapshotPage(GoRouterState state) {
    final extra = state.extra;
    if (extra is! LocationSnapshotRouteExtra) {
      return const _MissingRouteExtraPage(message: 'Thiếu dữ liệu vị trí');
    }
    return LocationSnapshotPage(
      latitude: extra.latitude,
      longitude: extra.longitude,
      address: extra.address,
      label: extra.label,
    );
  }

  Widget _buildChatVideoViewerPage(GoRouterState state) {
    final extra = state.extra;
    final url = extra is Map ? extra['url']?.toString() : null;
    if (url == null || url.isEmpty) {
      return const _MissingRouteExtraPage(message: 'Thiếu đường dẫn video');
    }
    return NetworkVideoViewerPage(url: url);
  }

  Widget _buildCalendarEventFormPage(
    BuildContext context,
    GoRouterState state,
  ) {
    final repository = CalendarRepositoryImpl.fromDio(
      Provider.of<DioClient>(context, listen: false).dio,
    );
    final extra = state.extra;
    final routeExtra = extra is CalendarEventRouteExtra ? extra : null;
    final isDetailRoute = state.pathParameters.containsKey('eventId');

    if (isDetailRoute && routeExtra?.event == null) {
      return const _MissingRouteExtraPage(
        message: 'Thiáº¿u dá»¯ liá»‡u lá»‹ch',
      );
    }

    return CalendarEventFormPage(
      createCalendarEvent: CreateCalendarEvent(repository),
      updateCalendarEvent: UpdateCalendarEvent(repository),
      deleteCalendarEvent: DeleteCalendarEvent(repository),
      event: routeExtra?.event,
      initialDate: routeExtra?.initialDate,
    );
  }
}

class _MissingRouteExtraPage extends StatelessWidget {
  const _MissingRouteExtraPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}
