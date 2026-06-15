import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_my_couple.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CoupleShellScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const CoupleShellScaffold({super.key, required this.navigationShell});

  @override
  State<StatefulWidget> createState() => _CoupleShellScaffoldState();
}

class _CoupleShellScaffoldState extends State<CoupleShellScaffold> {
  late final GetMyCouple _getMyCouple;
  bool isLoading = false;
  bool isCouple = true;

  @override
  void initState() {
    super.initState();
    _getMyCouple = GetMyCouple(
      CoupleRepositoryImpl(
        CoupleRemoteDatasource(context.read<DioClient>().dio),
      ),
    );
    _fetchCoupleData();
  }

  Future<void> _fetchCoupleData() async {
    try {
      if (mounted) {
        setState(() => isLoading = true);
      }
      await _getMyCouple();
    } on DioException catch (e) {
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
          IconButton(
            onPressed: () => {context.push('/couple/confirmation')},
            icon: Icon(
              Icons.notifications_none,
              color: const Color(0xFF1A1C1D),
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
                label: 'Kĩ Niệm',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today, color: Color(0xFF1A1C1D)),
                label: 'Lịch hẹn',
              ),
            ],
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: Color(0xFF1A1C1D)),
              label: 'Cài Đặt',
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
        routerIndex = RouterIndex.settings;
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

    if (!isCouple && currentRouterIndex == RouterIndex.settings) {
      return 1;
    }
    return currentRouterIndex;
  }
}

class RouterIndex {
  static const int home = 0;
  static const int memories = 1;
  static const int dates = 2;
  static const int settings = 3;
}
