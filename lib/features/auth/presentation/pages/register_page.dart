import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lovesync_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lovesync_mobile/features/auth/domain/entities/login_response.dart';
import 'package:lovesync_mobile/features/auth/domain/usecases/post_login.dart';
import 'package:lovesync_mobile/features/auth/domain/usecases/post_register.dart';
import 'package:lovesync_mobile/features/e2ee/data/repositories/e2ee_repository_impl.dart';
import 'package:lovesync_mobile/features/e2ee/domain/usecases/e2ee_manager.dart';
import 'package:lovesync_mobile/features/e2ee/presentation/widgets/e2ee_recovery_code_sheet.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isShowPassword = false;
  bool _isShowConfirmPassword = false;

  // checkbox
  bool _isChecked = false;
  bool _isLoading = false;

  late final PostRegister _postRegister;
  late final PostLogin _postLogin;
  late final E2eeManager _e2eeManager;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    final authRepository = AuthRepositoryImpl(
      AuthRemoteDatasource(context.read<DioClient>().dio),
    );
    _postRegister = PostRegister(authRepository);
    _postLogin = PostLogin(authRepository);
    _e2eeManager = E2eeManager(
      repository: E2eeRepositoryImpl.fromDio(context.read<DioClient>().dio),
    );
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    if (!_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với điều khoản dịch vụ')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      await _postRegister(email, password, confirmPassword, name);
      final loginResponse = await _postLogin(email, password);
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      await authProvider.loginWithTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        userId: loginResponse.id,
        notify: false,
      );
      final e2eeReady = await _setupE2eeForNewAccount(loginResponse);
      if (!e2eeReady) {
        await authProvider.logout();
        return;
      }
      await authProvider.loginWithTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        userId: loginResponse.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đăng ký thành công')));
        context.go(AppRoutePaths.coupleHome);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Email đã tồn tại')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng ký thất bại, vui lòng thử lại')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _setupE2eeForNewAccount(LoginResponse response) async {
    final code = await showE2eeRecoveryCodeSheet(
      context: context,
      mode: E2eeRecoveryCodeMode.create,
    );
    if (code == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần tạo mã khôi phục để tiếp tục.')),
      );
      return false;
    }
    try {
      await _e2eeManager.setupNewKeys(userId: response.id, recoveryCode: code);
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Đăng Ký",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 102, 17, 45),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Bắt Đầu Hành Trình Yêu",
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Roboto",
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Tạo tài khoản để kết nối với người ấy",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontFamily: "Roboto",
                      ),
                    ),

                    const SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Họ và tên"),
                              const SizedBox(height: 5),
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.person),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      width: 2,
                                      color: Color.fromARGB(255, 247, 166, 193),
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 255, 68, 131),
                                      width: 2,
                                    ),
                                  ),
                                  hintText: "Nhập họ và tên của bạn",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Email"),
                              const SizedBox(height: 5),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      width: 2,
                                      color: Color.fromARGB(255, 247, 166, 193),
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 255, 68, 131),
                                      width: 2,
                                    ),
                                  ),
                                  hintText: "Nhập email của bạn",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Mật khẩu"),
                              const SizedBox(height: 5),
                              TextField(
                                obscureText: !_isShowConfirmPassword,
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffix: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isShowConfirmPassword =
                                            !_isShowConfirmPassword;
                                      });
                                    },
                                    child: Icon(
                                      _isShowConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      size: 20,
                                    ),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      width: 2,
                                      color: Color.fromARGB(255, 247, 166, 193),
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 255, 68, 131),
                                      width: 2,
                                    ),
                                  ),
                                  hintText: "Nhập mật khẩu của bạn",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Xác nhận mật khẩu"),
                              const SizedBox(height: 5),
                              TextField(
                                obscureText: !_isShowPassword,
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffix: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isShowPassword = !_isShowPassword;
                                      });
                                    },
                                    child: Icon(
                                      _isShowPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      size: 20,
                                    ),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    borderSide: BorderSide(
                                      width: 2,
                                      color: Color.fromARGB(255, 247, 166, 193),
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 255, 68, 131),
                                      width: 2,
                                    ),
                                  ),
                                  hintText: "Nhập xác nhận mật khẩu",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          // Checkbox và Text
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _isChecked,
                                onChanged: (value) {
                                  setState(() {
                                    _isChecked = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                    children: [
                                      TextSpan(text: 'Tôi đồng ý với '),
                                      TextSpan(
                                        text: 'Điều khoản dịch vụ',
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            102,
                                            17,
                                            45,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: ' và '),
                                      TextSpan(
                                        text: 'Chính sách',
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            102,
                                            17,
                                            45,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                _handleRegister();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  154,
                                  188,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Đăng Ký",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Bạn chưa có tài khoản? "),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            context.pop();
                          },
                          child: const Text("Đăng nhập ngay"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white.withValues(alpha: 0.8),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
