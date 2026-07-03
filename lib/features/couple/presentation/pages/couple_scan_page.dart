import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_partner_by_code.dart';
import 'package:lovesync_mobile/features/user/data/datasources/user_remote_datasource.dart';
import 'package:lovesync_mobile/features/user/data/repositories/user_repository_impl.dart';
import 'package:lovesync_mobile/features/user/domain/usecases/get_user_info.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class CoupleScanPage extends StatefulWidget {
  const CoupleScanPage({super.key});

  @override
  State<CoupleScanPage> createState() => _CoupleScanPageState();
}

class _CoupleScanPageState extends State<CoupleScanPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
  );

  late final AnimationController _animationController;
  late final Animation<double> _scanAnimation;

  late final GetPartnerByCode _getPartnerByCode;
  late final GetUserInfo _getUserInfo;

  bool _isScanned = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(
      begin: 10,
      end: 240,
    ).animate(_animationController);

    _getPartnerByCode = GetPartnerByCode(
      CoupleRepositoryImpl(
        CoupleRemoteDatasource(context.read<DioClient>().dio),
      ),
    );

    _getUserInfo = GetUserInfo(
      UserRepositoryImpl(UserRemoteDatasource(context.read<DioClient>().dio)),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;
    if (code == null) return;
    _isScanned = true;
    debugPrint('QR Code: $code');
    try {
      final partner = await _getPartnerByCode.call(code);
      final userInfo = await _getUserInfo.call();

      if (mounted) {
        context.push(
          AppRoutes.couplePartnerInfo,
          extra: {
            'partnerCode': code,
            'partnerName': partner.name,
            'partnerAvatarUrl': partner.avatar,
            'userFullName': userInfo.name,
            'userAvatarUrl': userInfo.avatar,
          },
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã ghép đôi không hợp lệ'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi lấy thông tin đối phương'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _onClickCamera() {
    _controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quét Mã Ghép Đôi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFFA03B56),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scanWindow = Rect.fromCenter(
                    center: Offset(
                      constraints.maxWidth / 2,
                      constraints.maxHeight / 2,
                    ),
                    width: 250,
                    height: 250,
                  );

                  return Stack(
                    children: [
                      MobileScanner(
                        controller: _controller,
                        scanWindow: scanWindow,
                        onDetect: _onDetect,
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: IconButton(
                          onPressed: _onClickCamera,
                          icon: Icon(
                            Icons.cameraswitch,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          width: 250,
                          height: 250,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _scanAnimation,
                                builder: (context, child) {
                                  return Positioned(
                                    top: _scanAnimation.value,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 3,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Hướng camera về phía mã QR để quét',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
