import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_partner_by_code.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_my_couple_code.dart';
import 'package:lovesync_mobile/features/user/data/datasources/user_remote_datasource.dart';
import 'package:lovesync_mobile/features/user/data/repositories/user_repository_impl.dart';
import 'package:lovesync_mobile/features/user/domain/usecases/get_user_info.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class CoupleCodePage extends StatefulWidget {
  const CoupleCodePage({super.key});

  @override
  State<StatefulWidget> createState() => _CoupleCodePageState();
}

class _CoupleCodePageState extends State<CoupleCodePage> {
  late final GetMyCoupleCode _getMyCoupleCode;
  late final GetPartnerByCode _getPartnerByCode;
  late final GetUserInfo _getUserInfo;
  final TextEditingController _manualCodeController = TextEditingController();
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final dio = context.read<DioClient>().dio;
    final coupleRepository = CoupleRepositoryImpl(CoupleRemoteDatasource(dio));
    _getMyCoupleCode = GetMyCoupleCode(coupleRepository);
    _getPartnerByCode = GetPartnerByCode(coupleRepository);
    _getUserInfo = GetUserInfo(UserRepositoryImpl(UserRemoteDatasource(dio)));

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
    context.push(AppRoutePaths.coupleScan);
  }

  Future<void> _shareMyCode() async {
    final coupleCode = code.trim();
    if (coupleCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã ghép đôi đang được tải. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final logo = await rootBundle.load('assets/logo.png');
    await SharePlus.instance.share(
      ShareParams(
        title: 'Mã ghép đôi LoveSync',
        text:
            'Mình mời bạn ghép đôi trên LoveSync. Nhập mã ghép đôi của mình: $coupleCode',
        files: [
          XFile.fromData(
            logo.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'lovesync-logo.png',
          ),
        ],
        fileNameOverrides: const ['lovesync-logo.png'],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _showManualCodeDialog() async {
    _manualCodeController.clear();
    final partnerCode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nhập mã ghép đôi'),
        content: TextField(
          controller: _manualCodeController,
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            hintText: 'Nhập mã của người ấy',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_manualCodeController.text),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA03B56),
            ),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );

    final code = partnerCode?.trim();
    if (code == null || code.isEmpty || !mounted) return;

    try {
      final partner = await _getPartnerByCode(code);
      final userInfo = await _getUserInfo();
      if (!mounted) return;
      context.push(
        AppRoutePaths.couplePartnerInfo,
        extra: {
          'partnerCode': code,
          'partnerName': partner.name,
          'partnerAvatarUrl': partner.avatar,
          'userFullName': userInfo.name,
          'userAvatarUrl': userInfo.avatar,
        },
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã ghép đôi không hợp lệ hoặc không thể kiểm tra.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    "Quét mã",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 20,
                      color: Color(0xFFA03B56),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showManualCodeDialog,
              icon: const Icon(Icons.keyboard_outlined),
              label: const Text('Không quét được? Nhập mã ghép đôi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA03B56),
                side: const BorderSide(color: Color(0xFFA03B56)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              key: _shareButtonKey,
              onPressed: _shareMyCode,
              icon: const Icon(Icons.share, size: 20),
              label: const Text('Chia sẻ mã của tôi'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFA03B56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
