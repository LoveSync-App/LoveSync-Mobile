import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lovesync_mobile/features/memory/presentation/pages/share_memory_page.dart';

class MemoryCapturePage extends StatefulWidget {
  const MemoryCapturePage({super.key});

  @override
  State<MemoryCapturePage> createState() => _MemoryCapturePageState();
}

class _MemoryCapturePageState extends State<MemoryCapturePage>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isInitializing = true;
  bool _isTakingPicture = false;
  bool _flashEnabled = false;
  String? _cameraError;
  File? _capturedImage;
  DateTime? _capturedAt;
  int _cameraGeneration = 0;
  bool _isPageDisposing = false;
  final Set<CameraController> _disposedControllers = HashSet.identity();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadCameras());
  }

  @override
  void dispose() {
    _isPageDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeController(rebuild: false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_capturedImage != null) return;
    if (state == AppLifecycleState.inactive) {
      unawaited(_disposeController());
    } else if (state == AppLifecycleState.resumed && _cameras.isNotEmpty) {
      unawaited(_initializeCamera(_cameras[_cameraIndex]));
    }
  }

  Future<void> _loadCameras() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _cameraError = 'Thiết bị không tìm thấy camera.';
        });
        return;
      }

      _cameras = cameras;
      final backCameraIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _cameraIndex = backCameraIndex < 0 ? 0 : backCameraIndex;
      await _initializeCamera(cameras[_cameraIndex]);
    } on CameraException catch (error) {
      _setCameraError(error);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _cameraError = 'Không thể mở camera.';
        });
      }
    }
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    final generation = ++_cameraGeneration;
    if (mounted) {
      setState(() {
        _isInitializing = true;
        _cameraError = null;
      });
    }

    await _disposeController(invalidateInitialization: false, rebuild: true);
    if (!mounted || generation != _cameraGeneration) return;

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted ||
          generation != _cameraGeneration ||
          _controller != controller) {
        await _disposeCameraController(controller);
        return;
      }
      await controller.setFlashMode(FlashMode.off);
      if (!mounted ||
          generation != _cameraGeneration ||
          _controller != controller) {
        await _disposeCameraController(controller);
        return;
      }
      setState(() {
        _isInitializing = false;
        _flashEnabled = false;
      });
    } on CameraException catch (error) {
      if (_controller == controller) _controller = null;
      await _disposeCameraController(controller);
      if (generation == _cameraGeneration) _setCameraError(error);
    }
  }

  void _setCameraError(CameraException error) {
    if (!mounted) return;
    final permissionDenied =
        error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt' ||
        error.code == 'CameraAccessRestricted';
    setState(() {
      _isInitializing = false;
      _cameraError = permissionDenied
          ? 'LoveSync chưa được cấp quyền camera.'
          : 'Không thể khởi động camera.';
    });
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);
    try {
      final image = await controller.takePicture();
      await _useImage(File(image.path));
    } on CameraException {
      if (mounted) {
        _showMessage('Không thể chụp ảnh. Bạn có thể chọn ảnh từ thư viện.');
      }
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1440,
      );
      if (image != null) await _useImage(File(image.path));
    } catch (_) {
      if (mounted) _showMessage('Không thể mở thư viện ảnh.');
    }
  }

  Future<void> _useImage(File image) async {
    final capturedAt = DateTime.now();
    await _disposeController();
    if (!mounted) return;
    setState(() {
      _capturedImage = image;
      _capturedAt = capturedAt;
    });
  }

  Future<void> _retakePicture() async {
    setState(() {
      _capturedImage = null;
      _capturedAt = null;
    });
    if (_cameras.isEmpty) {
      await _loadCameras();
    } else {
      await _initializeCamera(_cameras[_cameraIndex]);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isInitializing) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _initializeCamera(_cameras[_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final nextValue = !_flashEnabled;
    try {
      await controller.setFlashMode(nextValue ? FlashMode.auto : FlashMode.off);
      if (mounted) setState(() => _flashEnabled = nextValue);
    } on CameraException {
      if (mounted) _showMessage('Camera này không hỗ trợ đèn flash.');
    }
  }

  Future<void> _disposeController({
    bool invalidateInitialization = true,
    bool rebuild = true,
  }) async {
    if (invalidateInitialization) _cameraGeneration++;
    final controller = _controller;
    _controller = null;

    if (rebuild && mounted && !_isPageDisposing) {
      setState(() => _isInitializing = true);
      await WidgetsBinding.instance.endOfFrame;
    } else if (!rebuild) {
      await Future<void>.delayed(Duration.zero);
    }

    if (controller != null) {
      await _disposeCameraController(controller);
    }
  }

  Future<void> _disposeCameraController(CameraController controller) async {
    if (!_disposedControllers.add(controller)) return;
    try {
      await controller.dispose();
    } catch (_) {
      // Native camera channels may already be detached during lifecycle changes.
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capturedImage = _capturedImage;
    final capturedAt = _capturedAt;
    if (capturedImage != null && capturedAt != null) {
      return Scaffold(
        body: SafeArea(
          child: ShareMemorySheet(
            initialImage: capturedImage,
            capturedAt: capturedAt,
            isPage: true,
            onRetake: _retakePicture,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black87],
                stops: [0, 0.48, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                const Text(
                  'Lưu lại khoảnh khắc của hai bạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildCameraControls(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _controller;
    if (_cameraError != null) {
      return _CameraFallback(
        message: _cameraError!,
        onPickGallery: _pickFromGallery,
      );
    }
    if (_isInitializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final previewSize = controller.value.previewSize!;
    final previewRatio = previewSize.height / previewSize.width;
    final screenRatio = size.width / size.height;
    final scale = previewRatio / screenRatio;

    return ClipRect(
      child: Transform.scale(
        scale: scale < 1 ? 1 / scale : scale,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CameraIconButton(
            icon: Icons.close,
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Khoảnh khắc mới',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          _CameraIconButton(
            icon: _flashEnabled ? Icons.flash_auto : Icons.flash_off,
            onPressed: _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CameraIconButton(
            icon: Icons.photo_library_outlined,
            size: 54,
            onPressed: _pickFromGallery,
          ),
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 86,
              height: 86,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _isTakingPicture
                      ? Colors.white54
                      : const Color(0xFFFFEEF3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          _CameraIconButton(
            icon: Icons.cameraswitch_outlined,
            size: 54,
            onPressed: _switchCamera,
          ),
        ],
      ),
    );
  }
}

class _CameraIconButton extends StatelessWidget {
  const _CameraIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 46,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        backgroundColor: Colors.black.withValues(alpha: 0.38),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback({required this.message, required this.onPickGallery});

  final String message;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF24171C),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 64,
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Chọn ảnh từ thư viện'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
