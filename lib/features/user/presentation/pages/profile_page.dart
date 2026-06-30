import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/user/data/datasources/user_remote_datasource.dart';
import 'package:lovesync_mobile/features/user/data/repositories/user_repository_impl.dart';
import 'package:lovesync_mobile/features/user/domain/entities/user_response.dart';
import 'package:lovesync_mobile/features/user/domain/usecases/delete_me.dart';
import 'package:lovesync_mobile/features/user/domain/usecases/get_user_info.dart';
import 'package:lovesync_mobile/features/user/domain/usecases/patch_update_me.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'package:lovesync_mobile/shared/upload/data/datasources/upload_remote_datasource.dart';
import 'package:lovesync_mobile/shared/upload/data/repositories/upload_repositoty_impl.dart';
import 'package:lovesync_mobile/shared/upload/domain/usecases/upload_file.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final GetUserInfo _getUserInfo;
  late final PatchUpdateMe _patchUpdateMe;
  late final DeleteMe _deleteMe;
  late final UploadFile _uploadFile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  UserResponse? _profile;
  File? _selectedAvatar;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isPickingAvatar = false;

  @override
  void initState() {
    super.initState();

    final dio = context.read<DioClient>().dio;
    final userRepository = UserRepositoryImpl(UserRemoteDatasource(dio));
    _getUserInfo = GetUserInfo(userRepository);
    _patchUpdateMe = PatchUpdateMe(userRepository);
    _deleteMe = DeleteMe(userRepository);
    _uploadFile = UploadFile(UploadRepositotyImpl(UploadRemoteDatasource(dio)));

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _getUserInfo();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameController.text = profile.name;
        _phoneController.text = profile.phone;
        _isLoading = false;
      });
    } on DioException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Không tải được thông tin cá nhân.');
    }
  }

  Future<void> _pickAvatar() async {
    if (_isPickingAvatar || _isSaving || _isDeleting) return;

    setState(() => _isPickingAvatar = true);

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (pickedFile == null || !mounted) return;

      setState(() => _selectedAvatar = File(pickedFile.path));
    } on PlatformException catch (e) {
      if (!mounted || e.code == 'already_active') return;
      _showSnackBar('Không chọn được ảnh đại diện.');
    } finally {
      if (mounted) {
        setState(() => _isPickingAvatar = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final currentProfile = _profile;
    if (currentProfile == null || _isSaving) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Vui lòng nhập tên.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      var avatarUrl = currentProfile.avatar;
      final avatarFile = _selectedAvatar;
      if (avatarFile != null) {
        avatarUrl = await _uploadFile(avatarFile);
      }

      final updatedProfile = await _patchUpdateMe(
        name: name,
        phone: phone,
        avatar: avatarUrl,
      );

      if (!mounted) return;
      setState(() {
        _profile = updatedProfile;
        _selectedAvatar = null;
      });
      _showSnackBar('Đã cập nhật thông tin cá nhân.');
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message ?? 'Không cập nhật được thông tin.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tắt tài khoản?'),
        content: const Text(
          'Tài khoản của bạn sẽ được chuyển sang trạng thái INACTIVE.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tắt tài khoản'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    try {
      await _deleteMe();
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message ?? 'Không tắt được tài khoản.');
      setState(() => _isDeleting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        body: Center(
          child: FilledButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvatar(profile),
                const SizedBox(height: 20),
                _buildProfileSummary(profile),
                const SizedBox(height: 18),
                _buildForm(),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _isDeleting ? null : _confirmDeleteAccount,
                  icon: const Icon(Icons.person_off_outlined),
                  label: const Text('Tắt tài khoản'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: SafeArea(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving || _isDeleting ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA03B56),
                  ),
                ),
              ),
            ),
          ),
          if (_isDeleting)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserResponse profile) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFF3D8E0),
              backgroundImage: _selectedAvatar != null
                  ? FileImage(_selectedAvatar!)
                  : profile.avatar.isNotEmpty
                  ? NetworkImage(profile.avatar)
                  : null,
              child: _selectedAvatar == null && profile.avatar.isEmpty
                  ? const Icon(Icons.person, size: 44, color: Color(0xFFA03B56))
                  : null,
            ),
          ),
          Positioned(
            right: -2,
            bottom: 2,
            child: IconButton.filled(
              onPressed: _isPickingAvatar ? null : _pickAvatar,
              icon: _isPickingAvatar
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt_outlined, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFA03B56),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummary(UserResponse profile) {
    return Column(
      children: [
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6D7278)),
        ),
        const SizedBox(height: 10),
        Chip(
          label: Text(profile.status.isEmpty ? 'ACTIVE' : profile.status),
          backgroundColor: const Color(0xFFFFE8EF),
          labelStyle: const TextStyle(
            color: Color(0xFFA03B56),
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide.none,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Tên hiển thị'),
        TextField(
          controller: _nameController,
          decoration: _buildInputDecoration(
            hintText: 'Nhập tên của bạn',
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 14),
        _buildInputLabel('Số điện thoại'),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _buildInputDecoration(
            hintText: 'Nhập số điện thoại',
            icon: Icons.phone_outlined,
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
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xFFA03B56)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF0D8DF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFA03B56), width: 1.4),
      ),
    );
  }
}
