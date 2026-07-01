import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/memory/data/datasources/memory_remote_datasource.dart';
import 'package:lovesync_mobile/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:lovesync_mobile/features/memory/domain/usecases/post_create_memory.dart';
import 'package:lovesync_mobile/shared/upload/data/datasources/upload_remote_datasource.dart';
import 'package:lovesync_mobile/shared/upload/data/repositories/upload_repositoty_impl.dart';
import 'package:lovesync_mobile/shared/upload/domain/usecases/upload_file.dart';
import 'package:provider/provider.dart';

class ShareMemorySheet extends StatefulWidget {
  const ShareMemorySheet({
    super.key,
    required this.initialImage,
    required this.capturedAt,
    this.isPage = false,
    this.onRetake,
  });

  final File initialImage;
  final DateTime capturedAt;
  final bool isPage;
  final Future<void> Function()? onRetake;

  @override
  State<ShareMemorySheet> createState() => _ShareMemorySheetState();
}

class _ShareMemorySheetState extends State<ShareMemorySheet> {
  late final PostCreateMemory _postCreateMemory;
  late final UploadFile _uploadFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentController = TextEditingController();

  File? _selectedImage;
  DateTime? _capturedAt;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
    _capturedAt = widget.capturedAt;
    _postCreateMemory = PostCreateMemory(
      MemoryRepositoryImpl(
        MemoryRemoteDatasource(context.read<DioClient>().dio),
      ),
    );
    _uploadFile = UploadFile(
      UploadRepositotyImpl(
        UploadRemoteDatasource(context.read<DioClient>().dio),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1440,
      );
      if (pickedFile == null || !mounted) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _capturedAt = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        source == ImageSource.camera
            ? 'Không thể mở camera. Hãy kiểm tra quyền camera.'
            : 'Không thể chọn hình ảnh.',
      );
    }
  }

  Future<void> _showImageSourcePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Lưu khoảnh khắc ngay bây giờ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Chụp ngay',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Chọn ảnh',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createMemory() async {
    if (_isLoading) return;

    final image = _selectedImage;
    final capturedAt = _capturedAt;
    final content = _contentController.text.trim();

    if (image == null || capturedAt == null || !image.existsSync()) {
      _showMessage('Hãy chụp hoặc chọn một hình ảnh trước.');
      return;
    }
    if (content.isEmpty) {
      _showMessage('Hãy viết vài dòng về khoảnh khắc này.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final imageUrl = await _uploadFile(image);
      await _postCreateMemory(
        fileUrl: imageUrl,
        description: content,
        time: capturedAt,
      );

      if (mounted) Navigator.pop(context, true);
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final serverMessage = data is Map
          ? (data['message'] ?? data['error'])?.toString()
          : null;
      _showMessage(serverMessage ?? 'Không thể chia sẻ kỷ niệm lúc này.');
    } catch (_) {
      if (mounted) _showMessage('Không thể chia sẻ kỷ niệm lúc này.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8FA),
      borderRadius: widget.isPage
          ? BorderRadius.zero
          : const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              32 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isPage)
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8C8CD),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chia sẻ khoảnh khắc',
                        style: TextStyle(
                          color: Color(0xFFA03B56),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      icon: Icon(
                        widget.isPage ? Icons.arrow_back : Icons.close,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildImageCard(),
                if (_capturedAt != null) ...[
                  const SizedBox(height: 12),
                  _buildCapturedTime(),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Nội dung kỷ niệm *',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  minLines: 4,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Điều gì khiến khoảnh khắc này trở nên đáng nhớ?',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFF0DDE3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFA03B56),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _createMemory,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFA03B56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.favorite),
                    label: const Text(
                      'Chia sẻ ngay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFA03B56)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCapturedTime() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAF0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 19, color: Color(0xFFA03B56)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Khoảnh khắc lúc ${DateFormat('HH:mm, dd/MM/yyyy').format(_capturedAt!)}',
              style: const TextStyle(
                color: Color(0xFFA03B56),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    final image = _selectedImage;
    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: Container(
        width: double.infinity,
        height: 260,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0DDE3)),
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEAF0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      size: 38,
                      color: Color(0xFFA03B56),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Chụp hoặc chọn khoảnh khắc',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Thời gian sẽ được lưu tự động',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(image, fit: BoxFit.cover),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FilledButton.icon(
                      onPressed: widget.onRetake ?? _showImageSourcePicker,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.65),
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(
                        widget.onRetake == null ? 'Đổi ảnh' : 'Chụp lại',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        foregroundColor: const Color(0xFFA03B56),
        side: const BorderSide(color: Color(0xFFE7B8C5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
