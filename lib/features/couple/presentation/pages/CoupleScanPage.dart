import 'package:flutter/material.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_partner_by_code.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  final GetPartnerByCode _getPartnerByCode = GetPartnerByCode(
    CoupleRepositoryImpl(CoupleRemoteDatasource(DioClient.instance.dio)),
  );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đối tác: ${partner.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lấy thông tin đối tác: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _isScanned = false; 
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
