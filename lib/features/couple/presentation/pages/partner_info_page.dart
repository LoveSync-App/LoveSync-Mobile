import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/couple.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/post_create_couple.dart';
import 'package:provider/provider.dart';

class PartnerInfoPage extends StatefulWidget {
  final String userFullName;
  final String userAvatarUrl;
  final String partnerName;
  final String partnerAvatarUrl;
  final String partnerCode;

  const PartnerInfoPage({
    super.key,
    required this.userFullName,
    required this.userAvatarUrl,
    required this.partnerName,
    required this.partnerAvatarUrl,
    required this.partnerCode,
  });

  @override
  State<PartnerInfoPage> createState() => _PartnerInfoPageState();
}

class _PartnerInfoPageState extends State<PartnerInfoPage>
    with SingleTickerProviderStateMixin {
  late final PostCreateCouple _postCreateCouple;

  @override
  initState() {
    super.initState();
    _postCreateCouple = PostCreateCouple(
      CoupleRepositoryImpl(
        CoupleRemoteDatasource(context.read<DioClient>().dio),
      ),
    );
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBE5EA), Color(0xFFF8F2F6), Color(0xFFEAE2FF)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: -10,
                top: 20,
                child: Opacity(
                  opacity: 0.18,
                  child: Icon(
                    Icons.favorite_border,
                    size: 130,
                    color: Colors.pink.shade300,
                  ),
                ),
              ),
              Positioned(
                right: -25,
                bottom: 45,
                child: Opacity(
                  opacity: 0.08,
                  child: Transform.rotate(
                    angle: -0.35,
                    child: Icon(
                      Icons.favorite_border,
                      size: 180,
                      color: Colors.deepPurple.shade300,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 40,
                top: 140,
                child: Opacity(
                  opacity: 0.12,
                  child: Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Colors.pink.shade200,
                  ),
                ),
              ),
              Positioned(
                left: 100,
                top: 270,
                child: Opacity(
                  opacity: 0.12,
                  child: Icon(
                    Icons.favorite_border,
                    size: 14,
                    color: Colors.pink.shade200,
                  ),
                ),
              ),
              Positioned(
                right: 55,
                top: 155,
                child: Opacity(
                  opacity: 0.12,
                  child: Icon(
                    Icons.favorite_border,
                    size: 14,
                    color: Colors.deepPurple.shade200,
                  ),
                ),
              ),
              Positioned(
                right: 30,
                top: 330,
                child: Opacity(
                  opacity: 0.12,
                  child: Icon(
                    Icons.favorite_border,
                    size: 12,
                    color: Colors.deepPurple.shade200,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 470,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    Icons.favorite_border,
                    size: 10,
                    color: Colors.pink.shade200,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 38,
                                  backgroundImage: NetworkImage(
                                    widget.userAvatarUrl,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _NamePill(name: widget.userFullName),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.pink.shade300,
                                          Colors.purple.shade200,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.favorite_border,
                                      color: Colors.pink.shade400,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const SizedBox(height: 56),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 38,
                                  backgroundImage: NetworkImage(
                                    widget.partnerAvatarUrl,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _NamePill(name: widget.partnerName),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 34,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Đã tìm thấy người ấy!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1F1F),
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: Colors.brown.shade300,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Bạn có muốn kết nối với ',
                                ),
                                TextSpan(
                                  text: widget.partnerName,
                                  style: TextStyle(
                                    color: Colors.pink.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' để bắt đầu hành trình của bạn?',
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.menu_book_outlined,
                                  color: Colors.pink.shade700,
                                  size: 28,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Nhật Ký Chung',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  color: Colors.deepPurple.shade400,
                                  size: 28,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Sự Kiện Chung',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(29),
                          color: Color(0xFFA03B56),
                          // gradient: const LinearGradient(
                          //   colors: [Color(0xFFC13E67), Color(0xFF6A58A8)],
                          // ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9B4A7A).withOpacity(0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _postCreateCouple(widget.partnerCode);
                              if (mounted) {
                                // Navigator.pop(context, true);
                                context.go("/couple");
                              }
                            } on DioException catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Lỗi khi kết nối server"),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(29),
                            ),
                          ),
                          child: const Text(
                            'Xác Nhận Kết Nối',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.deepPurple.shade300,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.45),
                        ),
                        child: Text(
                          'Không phải người đó? Thử lại',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.deepPurple.shade400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
