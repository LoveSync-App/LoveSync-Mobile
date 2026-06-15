import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoupleShellScaffold extends StatelessWidget {
  const CoupleShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: const Icon(Icons.favorite, color: Colors.pink),
        title: const Text(
          "Love Sync",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.pink,
          ),
        ),
        actions: [
          Icon(Icons.notifications, color: Colors.pink.shade700),
          const SizedBox(width: 12),
        ],
        centerTitle: true,
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        height: 60,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Color(0xFF1A1C1D)),
            label: 'Trang Chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library, color: Color(0xFF1A1C1D)),
            label: 'Kĩ Niệm',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today, color: Color(0xFF1A1C1D)),
            label: 'Lịch hẹn',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Color(0xFF1A1C1D)),
            label: 'Cài Đặt',
          ),
        ],
      ),
    );
  }
}
