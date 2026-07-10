import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_my_couple.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_my_couple_days.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/patch_unlink_couple.dart';
import 'package:lovesync_mobile/shared/widgets/couple_shell_scaffold.dart';
import 'package:provider/provider.dart';
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

  late final GetMyCouple _getMyCouple;
  late final GetMyCoupleDays _getMyCoupleDays;
  late final PatchUnlinkCouple _unlinkCouple;

  bool isLoading = true;
  bool _isUnlinking = false;
  double progress = 0.0;
  int days = 0;
  String userName = "Minh Quân";
  String userAvatar = "https://i.pravatar.cc/150?img=3";
  String partnerName = "";
  String partnerAvatar = "https://i.pravatar.cc/150?img=3";

  Future<void> _fetchCouple({bool showLoading = true}) async {
    try {
      if (showLoading && mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final couple = await _getMyCouple.call();

      if (!mounted) return;

      setState(() {
        userName = couple.userName;
        userAvatar = couple.userAvatar;
        partnerName = couple.partnerName;
        partnerAvatar = couple.partnerAvatar;
      });

      await _fetchCoupleDays();
    } on DioException {
      if (mounted) context.go(AppRoutePaths.coupleCode);
    } catch (_) {
      if (mounted) context.go(AppRoutePaths.coupleCode);
    } finally {
      if (mounted && showLoading) setState(() => isLoading = false);
    }
  }

  Future<void> _refreshCouple() {
    return _fetchCouple(showLoading: false);
  }

  Future<void> _fetchCoupleDays() async {
    final coupleDay = await _getMyCoupleDays.call();
    if (!mounted) return;

    setState(() {
      days = coupleDay.loveDays;
      progress = (days % 365) / 365;
    });
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

    _getMyCouple = GetMyCouple(
      CoupleRepositoryImpl(
        CoupleRemoteDatasource(context.read<DioClient>().dio),
      ),
    );

    _getMyCoupleDays = GetMyCoupleDays(
      CoupleRepositoryImpl(
        CoupleRemoteDatasource(context.read<DioClient>().dio),
      ),
    );
    _unlinkCouple = PatchUnlinkCouple(
      CoupleRepositoryImpl(
        CoupleRemoteDatasource(context.read<DioClient>().dio),
      ),
    );

    _fetchCouple();
  }

  Future<void> _confirmUnlinkCouple() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy ghép đôi?'),
        content: const Text(
          'Bạn sẽ không còn liên kết với người ấy. Bạn có thể ghép đôi lại sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC2414B),
            ),
            child: const Text('Hủy ghép đôi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUnlinking = true);
    try {
      await _unlinkCouple();
      if (!mounted) return;
      await CoupleShellScaffold.refreshCoupleState(context);
      if (mounted) context.go(AppRoutePaths.coupleCode);
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể hủy ghép đôi. Vui lòng thử lại.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUnlinking = false);
    }
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refreshCouple,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SizedBox(
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
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.pink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: _isUnlinking ? null : _confirmUnlinkCouple,
                      icon: _isUnlinking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link_off_outlined),
                      label: Text(
                        _isUnlinking
                            ? 'Đang hủy ghép đôi...'
                            : 'Không ghép đôi nữa',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFC2414B),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
