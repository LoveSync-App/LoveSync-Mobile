import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_my_couple_code.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';

class CoupleCodePage extends StatefulWidget {
  const CoupleCodePage({super.key});

  @override
  State<StatefulWidget> createState() => _CoupleCodePageState();
}

class _CoupleCodePageState extends State<CoupleCodePage> {
  final GetMyCoupleCode _getMyCoupleCode = GetMyCoupleCode(
    CoupleRepositoryImpl(CoupleRemoteDatasource(DioClient.instance.dio)),
  );

  @override
  void initState() {
    super.initState();
    fetchCoupleCode();
  }

  String code = ""; // Late có được gắn giá trị k

  void fetchCoupleCode() async {
    try {
      final coupleCode = await _getMyCoupleCode.call();

      setState(() {
        code = coupleCode.code;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lấy mã ghép đôi: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onClickScan(BuildContext context) {
    context.push("/couple/scan");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        // shadowColor: Colors.transparent,
        leading: const Icon(Icons.favorite, color: Color(0xFFA03B56), size: 26),
        title: const Text(
          'Ghép đôi',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF1A1C1D),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Color(0xFF1A1C1D),
              size: 26,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không có thông báo mới nào'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color.fromARGB(255, 245, 237, 237),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Bắt Đầu Hành Trình",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF1A1C1D),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Đưa mã này cho người ấy quét hoặc quét mã của họ để bắt đầu hành trình cùng nhau",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  color: Colors.white,
                  // border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  border: Border.all(
                    color: const Color.fromARGB(255, 245, 125, 215),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE0E0E0),
                          // child: const Icon(
                          //   Icons.person,
                          //   size: 30,
                          //   color: Colors.white,
                          // ),
                          // https://th.bing.com/th/id/R.ad0d7e9d172acc5072ebd40cb59a78b1?rik=bFM6xWR%2bKgVpvw&pid=ImgRaw&r=0
                          backgroundImage: NetworkImage(
                            "https://th.bing.com/th/id/OIP.r4A3RhH0Zz0ZKKiBcn4TsAHaHS?o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "MÃ CỦA BẠN",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFA03B56),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              // "LoveSync User",
                              code,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1C1D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      // data: "LoveSync User",
                      data: code,
                      size: 200,
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_clock,
                          size: 20,
                          color: Color(0xFF1A1C1D),
                        ),
                        SizedBox(width: 8),
                        Text("Mã an toàn & Riêng tư"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  _onClickScan(context);
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA03B56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 20,
                      color: Color(0xFFA03B56),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Quét mã",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share, size: 20, color: Color(0xFFA03B56)),
                  SizedBox(width: 8),
                  Text(
                    "Chia sẻ mã của tôi",
                    style: TextStyle(color: Color(0xFFA03B56)),
                  ),
                ],
              ),
            ],
          ),
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
