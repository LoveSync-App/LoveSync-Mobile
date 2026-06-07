import 'package:flutter/material.dart';

class CoupleCodePage extends StatefulWidget {
  const CoupleCodePage({super.key});

  @override
  State<StatefulWidget> createState() => _CoupleCodePageState();
}

class _CoupleCodePageState extends State<CoupleCodePage> {
  @override
  void initState() {
    super.initState();
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
                          child: const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
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
                            const Text(
                              "LoveSync User",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1C1D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(width: 200, height: 200, color: Colors.grey[300]),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đang được phát triển'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
