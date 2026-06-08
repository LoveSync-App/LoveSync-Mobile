import 'package:flutter/material.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_my_couple.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_my_couple_days.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CoupleDaysPage extends StatefulWidget {
  const CoupleDaysPage({super.key});

  @override
  State<CoupleDaysPage> createState() => _CoupleDaysPageState();
}

class _CoupleDaysPageState extends State<CoupleDaysPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _heartAnimation;

  // final double progress = (50 % 365) / 365;

  late final GetMyCouple _getMyCouple = new GetMyCouple(
    CoupleRepositoryImpl(CoupleRemoteDatasource(DioClient.instance.dio)),
  );
  late final GetMyCoupleDays _getMyCoupleDays = new GetMyCoupleDays(
    CoupleRepositoryImpl(CoupleRemoteDatasource(DioClient.instance.dio)),
  );

  bool isLoading = true;
  double progress = 0.0;
  int days = 0;
  String userName = "Minh Quân";
  String userAvatar = "https://i.pravatar.cc/150?img=3";
  String partnerName = "";
  String partnerAvatar = "https://i.pravatar.cc/150?img=3";

  void _fetchCouple() async {
    try {
      setState(() {
        isLoading = true;
      });

      final couple = await _getMyCouple.call();

      if (mounted) {
        setState(() {
          userName = couple.userName;
          // userAvatar = couple.userAvatar;
          partnerName = couple.partnerName;
          // partnerAvatar = couple.partnerAvatar;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lấy thông tin cặp đôi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _fetchCoupleDays() async {
    try {
      setState(() {
        isLoading = true;
      });

      final coupleDay = await _getMyCoupleDays.call();

      if (mounted) {
        setState(() {
          days = coupleDay.loveDays;
          progress = (days % 365) / 365;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lấy số ngày yêu nhau: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _heartAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
    ]).animate(_animationController);

    _fetchCoupleDays();
    _fetchCouple();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _NamePill({required String name}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.favorite, color: Colors.pink),
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
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: Skeletonizer(
                    enabled: isLoading,
                    child: Container(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                              // "https://i.pravatar.cc/150?img=3",
                              userAvatar,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _NamePill(name: userName),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _heartAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartAnimation.value,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.pink,
                          size: 50,
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Skeletonizer(
                    enabled: isLoading,
                    child: Container(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                              // "https://i.pravatar.cc/150?img=3",
                              partnerAvatar,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _NamePill(name: partnerName),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 20),
            Skeletonizer(
              enabled: isLoading,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.88),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Ngày yêu nhau"),
                        const SizedBox(height: 8),
                        Text(
                          "${days} ngày",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}% năm ${(days ~/ 365) + 1 == 1 ? "đầu tiên" : "thứ ${(days ~/ 365) + 1}"}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: CircularProgressIndicator(
                      value: progress, // số ngày / 365
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Colors.pink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        height: 60,
        selectedIndex: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Color(0xFF1A1C1D)),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library, color: Color(0xFF1A1C1D)),
            label: 'Kĩ Niệm',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today, color: Color(0xFF1A1C1D)),
            label: 'Lịch Hẹn',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Color(0xFF1A1C1D)),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
