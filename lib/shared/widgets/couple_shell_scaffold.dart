import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_invitation_pending.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_my_couple.dart';
import 'package:lovesync_mobile/fcm_initializer.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CoupleShellScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const CoupleShellScaffold({super.key, required this.navigationShell});

  static Future<void> refreshCoupleState(BuildContext context) async {
    final state = context.findAncestorStateOfType<_CoupleShellScaffoldState>();
    if (state != null) {
      await state._fetchCoupleData();
      await state._fetchPendingInvitations();
    }
  }

  static bool isCoupleActive(BuildContext context) {
    return context
            .findAncestorStateOfType<_CoupleShellScaffoldState>()
            ?.isCouple ??
        false;
  }

  @override
  State<StatefulWidget> createState() => _CoupleShellScaffoldState();
}

class _CoupleShellScaffoldState extends State<CoupleShellScaffold>
    with WidgetsBindingObserver {
  late final GetMyCouple _getMyCouple;
  late final GetInvitationPending _getInvitationPending;
  late final StreamSubscription<void> _notificationSubscription;
  bool isLoading = false;
  bool isCouple = true;
  int pendingInvitationCount = 0;
  bool hasPendingNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final repository = CoupleRepositoryImpl(
      CoupleRemoteDatasource(context.read<DioClient>().dio),
    );
    _getMyCouple = GetMyCouple(repository);
    _getInvitationPending = GetInvitationPending(repository);
    _fetchCoupleData();
    _fetchPendingInvitations();
    _notificationSubscription = FcmInitializer.onNotification.listen((_) {
      setState(() {
        hasPendingNotification = true;
      });
    });
  }

  Future<void> _fetchCoupleData() async {
    try {
      if (mounted) {
        setState(() => isLoading = true);
      }
      await _getMyCouple();
      if (mounted) {
        setState(() => isCouple = true);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 404) {
        setState(() => isCouple = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lấy thông tin cặp đôi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchPendingInvitations() async {
    try {
      final invitations = await _getInvitationPending();
      if (mounted) {
        setState(() => pendingInvitationCount = invitations.length);
      }
    } catch (_) {
      if (mounted) {
        setState(() => pendingInvitationCount = 0);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchPendingInvitations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Love Sync",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.pink,
          ),
        ),
        actions: [
          if (isCouple)
            IconButton(
              onPressed: () {
                context.push(AppRoutePaths.chat);
              },
              icon: const Icon(
                Icons.message_outlined,
                color: Color(0xFF1A1C1D),
              ),
            ),
          if (!isCouple)
            IconButton(
              onPressed: () async {
                final accepted = await context.push<bool>(
                  AppRoutePaths.coupleInvitations,
                );
                if (mounted) {
                  setState(() => hasPendingNotification = false);
                }
                await _fetchPendingInvitations();
                if (accepted != true || !mounted) return;

                await _fetchCoupleData();
                if (mounted) {
                  widget.navigationShell.goBranch(
                    RouterIndex.home,
                    initialLocation: true,
                  );
                }
              },
              icon: pendingInvitationCount > 0 || hasPendingNotification
                  ? Badge(
                      label: Text(
                        pendingInvitationCount > 1
                            ? pendingInvitationCount.toString()
                            : '1',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: const Color(0xFFD32F2F),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF1A1C1D),
                      ),
                    )
                  : const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF1A1C1D),
                    ),
            ),
          const SizedBox(width: 12),
        ],
        centerTitle: true,
      ),
      body: widget.navigationShell,
      bottomNavigationBar: Skeletonizer(
        enabled: isLoading,
        child: NavigationBar(
          backgroundColor: const Color(0xFFF9F9FB),
          elevation: 0,
          height: 80,
          selectedIndex: _getSelectedIndex(),
          onDestinationSelected: _onDestinationSelected,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Color(0xFF1A1C1D)),
              label: 'Trang Chủ',
            ),
            if (isCouple) ...const [
              NavigationDestination(
                icon: Icon(Icons.photo_library, color: Color(0xFF1A1C1D)),
                label: 'Kỉ Niệm',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF1A1C1D),
                ),
                label: 'Lịch',
              ),
            ],
            const NavigationDestination(
              icon: Icon(Icons.person_outline, color: Color(0xFF1A1C1D)),
              label: 'Cá Nhân',
            ),
          ],
        ),
      ),
    );
  }

  void _onDestinationSelected(int uiIndex) {
    int routerIndex = uiIndex;
    if (!isCouple) {
      if (uiIndex == 1) {
        routerIndex = RouterIndex.profile;
      }
    } else {
      routerIndex = uiIndex;
    }

    widget.navigationShell.goBranch(
      routerIndex,
      initialLocation: routerIndex == widget.navigationShell.currentIndex,
    );
  }

  int _getSelectedIndex() {
    final int currentRouterIndex = widget.navigationShell.currentIndex;

    if (!isCouple && currentRouterIndex == RouterIndex.profile) {
      return 1;
    }
    return currentRouterIndex;
  }
}

class RouterIndex {
  static const int home = 0;
  static const int memories = 1;
  static const int calendar = 2;
  static const int profile = 3;
}
