import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'package:provider/provider.dart'; // Đảm bảo đã add pub intl để format ngày

class CreateMemoryPage extends StatefulWidget {
  const CreateMemoryPage({super.key});

  @override
  State<StatefulWidget> createState() => _CreateMemoryPageState();
}

class _CreateMemoryPageState extends State<CreateMemoryPage> {
  late final PostCreateMemory _postCreateMemory;
  late final UploadFile _uploadFile;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedEmotion = 'Không cảm xúc';

  bool _isLoading = false;

  final List<String> _emotions = [
    'Không cảm xúc',
    'Lãng mạn',
    'Hạnh phúc',
    'Bình yên',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
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

  Future<void> _createMemory() async {
    try {
      if (!_selectedImage!.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn một hình ảnh hợp lệ')),
          );
        }
        return;
      }
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final imageUrl = await _uploadFile.call(_selectedImage!);
      print("URL ảnh đã upload: $imageUrl"); // Debug URL ảnh sau khi upload

      await _postCreateMemory.call(
        // _selectedImage!.path,
        imageUrl,
        _titleController.text,
        _descController.text,
        _selectedEmotion,
        _selectedDate,
      );
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra khi tạo kỷ niệm ${e.message}')),
        );
      }
    } finally {
      // Dù thành công hay lỗi, có thể reset trạng thái loading ở đây nếu cần
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<File?> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
      return null;
    }
  }

  Future<void> _onPickImage() async {
    final image = await _pickImageFromGallery();
    if (image == null) return;
    setState(() => _selectedImage = image);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.pink.shade300),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // void _onSaveMemory() {
  //   if (_titleController.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Vui lòng nhập tiêu đề kỷ niệm')),
  //     );
  //     return;
  //   }

  //   final memoryData = {
  //     "image": _selectedImage?.path,
  //     "title": _titleController.text,
  //     "description": _descController.text,
  //     "location": _locationController.text,
  //     "date": _selectedDate.toIso8601String(),
  //     "emotion": _selectedEmotion,
  //   };

  //   debugPrint("Dữ liệu tạo mới: $memoryData");
  // }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              "Tạo Kỷ Niệm Mới",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.pink,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageDropzone(),
                  const SizedBox(height: 24),

                  _buildInputLabel("Tiêu đề kỷ niệm *"),
                  TextFormField(
                    controller: _titleController,
                    decoration: _buildInputDecoration(
                      "Nhập tiêu đề ngắn gọn...",
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel("Mô tả"),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    decoration: _buildInputDecoration(
                      "Hôm đó có điều gì đáng nhớ không bạn?",
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel("Địa điểm"),
                  TextFormField(
                    controller: _locationController,
                    decoration: _buildInputDecoration(
                      "Ví dụ: Bãi biển Mỹ Khê, Đà Nẵng",
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel("Thời gian xảy ra"),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel("Cảm xúc hiện tại"),
                  Wrap(
                    spacing: 8.0,
                    children: _emotions.map((emotion) {
                      final isSelected = _selectedEmotion == emotion;
                      return ChoiceChip(
                        label: Text(emotion),
                        selected: isSelected,
                        selectedColor: Colors.pink.shade100,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.pink.shade700
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.pink.shade300
                              : Colors.grey.shade300,
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() => _selectedEmotion = emotion);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _createMemory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Lưu Kỷ Niệm",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText, {IconData? icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      fillColor: Colors.white,
      filled: true,
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.grey.shade600, size: 20)
          : null,
      contentPadding: const EdgeInsets.all(16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.pink, width: 1.5),
      ),
    );
  }

  Widget _buildImageDropzone() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: _onPickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: _selectedImage == null
                    ? Border.all(color: Colors.grey.shade300)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 36,
                            color: Colors.pink.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Thêm hình ảnh kỷ niệm",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          if (_selectedImage != null)
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                onTap: () => setState(() => _selectedImage = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
