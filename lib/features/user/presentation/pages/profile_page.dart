import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lovesync_mobile/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:lovesync_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lovesync_mobile/features/auth/domain/usecases/post_add_password.dart';
import 'package:lovesync_mobile/features/user/data/datasources/user_remote_datasource.dart';
import 'package:lovesync_mobile/features/user/data/repositories/user_repository_impl.dart';
import 'package:lovesync_mobile/features/user/domain/entities/user_response.dart';
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
  late final PostAddPassword _postAddPassword;
  late final UploadFile _uploadFile;
  late final AuthRemoteDatasource _authRemoteDatasource;
  late final GoogleAuthDatasource _googleAuthDatasource;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();

  UserResponse? _profile;
  File? _selectedAvatar;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUpdatingPassword = false;
  bool _isPickingAvatar = false;

  @override
  void initState() {
    super.initState();

    final dio = context.read<DioClient>().dio;
    _authRemoteDatasource = AuthRemoteDatasource(dio);
    _googleAuthDatasource = GoogleAuthDatasource();
    _postAddPassword = PostAddPassword(
      AuthRepositoryImpl(AuthRemoteDatasource(dio)),
    );
    final userRepository = UserRepositoryImpl(UserRemoteDatasource(dio));
    _getUserInfo = GetUserInfo(userRepository);
    _patchUpdateMe = PatchUpdateMe(userRepository);
    _uploadFile = UploadFile(UploadRepositotyImpl(UploadRemoteDatasource(dio)));

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile({bool showLoading = false}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);

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
    if (_isPickingAvatar || _isSaving || _isUpdatingPassword) return;

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

  Future<void> _showPasswordSheet() async {
    _passwordController.clear();
    _confirmPasswordController.clear();
    var showPassword = false;
    var showConfirmPassword = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Mật khẩu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: !showPassword,
                    decoration:
                        _buildInputDecoration(
                          hintText: 'Nhập mật khẩu mới',
                          icon: Icons.lock_outlined,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setSheetState(
                              () => showPassword = !showPassword,
                            ),
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !showConfirmPassword,
                    decoration:
                        _buildInputDecoration(
                          hintText: 'Nhập lại mật khẩu mới',
                          icon: Icons.lock_outlined,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setSheetState(
                              () => showConfirmPassword = !showConfirmPassword,
                            ),
                            icon: Icon(
                              showConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _isUpdatingPassword
                        ? null
                        : () => _savePassword(sheetContext),
                    icon: _isUpdatingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.key_outlined),
                    label: Text(
                      _isUpdatingPassword ? 'Đang lưu...' : 'Lưu mật khẩu',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFA03B56),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePassword(BuildContext sheetContext) async {
    final navigator = Navigator.of(sheetContext);
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.length < 6) {
      _showSnackBar('Mật khẩu cần có ít nhất 6 ký tự.');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Mật khẩu xác nhận không khớp.');
      return;
    }

    setState(() => _isUpdatingPassword = true);
    try {
      await _postAddPassword(
        password: password,
        passwordConfirm: confirmPassword,
      );
      if (!mounted) return;
      navigator.pop();
      _showSnackBar('Đã cập nhật mật khẩu.');
    } catch (error) {
      if (mounted) {
        _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  Future<void> _logout() async {
    try {
      await _authRemoteDatasource.logout();
    } catch (_) {
      // Always clear the local session even if the network is unavailable.
    }
    try {
      await _googleAuthDatasource.signOut();
    } catch (_) {
      // Password-only accounts may not have a Firebase/Google session.
    }
    if (mounted) await context.read<AuthProvider>().logout();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Bạn có chắc muốn đăng xuất khỏi tài khoản trên thiết bị này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC2414B),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _logout();
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
            onPressed: () => _loadProfile(showLoading: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAFC),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHero(profile),
                  const SizedBox(height: 18),
                  _buildInfoPanel(),
                  const SizedBox(height: 18),
                  _buildActionPanel(),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSaving || _isUpdatingPassword
                          ? null
                          : _saveProfile,
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
                  if (false) ...[
                    OutlinedButton.icon(
                      onPressed: _isUpdatingPassword
                          ? null
                          : _showPasswordSheet,
                      icon: const Icon(Icons.key_outlined),
                      label: const Text('Đổi mật khẩu'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFA03B56),
                        side: const BorderSide(color: Color(0xFFA03B56)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isUpdatingPassword)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHero(UserResponse profile) {
    return Center(child: _buildAvatar(profile));
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
            right: -4,
            bottom: 2,
            child: IconButton.filled(
              onPressed: _isPickingAvatar ? null : _pickAvatar,
              icon: _isPickingAvatar
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt_outlined, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFA03B56),
                foregroundColor: Colors.white,
                minimumSize: const Size(36, 36),
                fixedSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                side: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2DCE3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
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
        ),
      ),
    );
  }

  Widget _buildActionPanel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2DCE3)),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.key_outlined,
            title: 'Đổi mật khẩu',
            subtitle: 'Cập nhật mật khẩu đăng nhập',
            onTap: _isUpdatingPassword ? null : _showPasswordSheet,
          ),
          const Divider(height: 1, color: Color(0xFFF4E3E8)),
          _buildActionTile(
            icon: Icons.logout,
            title: 'Đăng xuất',
            subtitle: 'Rời khỏi tài khoản trên thiết bị này',
            onTap: _confirmLogout,
            destructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool destructive = false,
  }) {
    final color = destructive
        ? const Color(0xFFC2414B)
        : const Color(0xFFA03B56);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: color),
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
