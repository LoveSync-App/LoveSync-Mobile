import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lovesync_mobile/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:lovesync_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lovesync_mobile/features/auth/domain/entities/login_response.dart';
import 'package:lovesync_mobile/features/auth/domain/usecases/post_google_login.dart';
import 'package:lovesync_mobile/features/auth/domain/usecases/post_login.dart';
import 'package:lovesync_mobile/features/e2ee/data/repositories/e2ee_repository_impl.dart';
import 'package:lovesync_mobile/features/e2ee/domain/usecases/e2ee_manager.dart';
import 'package:lovesync_mobile/features/e2ee/presentation/widgets/e2ee_recovery_code_sheet.dart';
import 'package:lovesync_mobile/features/user/data/datasources/user_remote_datasource.dart';
import 'package:lovesync_mobile/features/user/data/repositories/user_repository_impl.dart';
import 'package:lovesync_mobile/features/user/domain/usecases/post_register_device.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final PostLogin _postLogin;
  late final PostGoogleLogin _postGoogleLogin;
  late final PostRegisterDevice _postRegisterDevice;
  late final GoogleAuthDatasource _googleAuthDatasource;
  late final E2eeManager _e2eeManager;

  bool _isShowPassword = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  initState() {
    super.initState();
    final authRepository = AuthRepositoryImpl(
      AuthRemoteDatasource(context.read<DioClient>().dio),
    );
    _postLogin = PostLogin(authRepository);
    _postGoogleLogin = PostGoogleLogin(authRepository);
    _googleAuthDatasource = GoogleAuthDatasource();
    _e2eeManager = E2eeManager(
      repository: E2eeRepositoryImpl.fromDio(context.read<DioClient>().dio),
    );
    _postRegisterDevice = PostRegisterDevice(
      UserRepositoryImpl(UserRemoteDatasource(context.read<DioClient>().dio)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notice = context.read<AuthProvider>().consumeAuthNotice();
      if (notice != null && notice.isNotEmpty) {
        _showMessage(notice);
      }
    });
  }

  void _onClickLogin() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập đầy đủ email và mật khẩu'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final response = await _postLogin.call(email, password);

      if (mounted) await _completeLogin(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onClickGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final identity = await _googleAuthDatasource.signIn();
      final response = await _postGoogleLogin(
        firebaseIdToken: identity.firebaseIdToken,
        name: identity.name,
        avatar: identity.avatar,
      );
      if (mounted) await _completeLogin(response);
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        await _resetGoogleSession();
        if (mounted) {
          _showMessage(error.description ?? 'Không thể đăng nhập Google.');
        }
      }
    } on FirebaseAuthException catch (error) {
      await _resetGoogleSession();
      if (mounted) {
        _showMessage(error.message ?? 'Firebase không thể xác thực Google.');
      }
    } catch (error) {
      await _resetGoogleSession();
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetGoogleSession() async {
    try {
      await _googleAuthDatasource.signOut();
    } catch (_) {
      // Ignore cleanup failures; the application session was not created.
    }
  }

  Future<void> _completeLogin(LoginResponse response) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.login(response.accessToken, response.id);
    final e2eeReady = await _ensureE2eeReady(response);
    if (!e2eeReady) {
      await authProvider.logout();
      await _resetGoogleSession();
      if (mounted) {
        _showMessage('Bạn cần hoàn tất mã khôi phục để dùng tài khoản này.');
      }
      return;
    }
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken?.isNotEmpty == true) {
        await _postRegisterDevice(fcmToken!);
      }
    } catch (_) {
      // Login remains valid even when device-token registration is unavailable.
    }
    if (!mounted) return;
    _showMessage('Đăng nhập thành công!');
    context.go(AppRoutes.couple);
  }

  Future<bool> _ensureE2eeReady(LoginResponse response) async {
    if (response.e2eeSetupRequired) {
      final code = await showE2eeRecoveryCodeSheet(
        context: context,
        mode: E2eeRecoveryCodeMode.create,
      );
      if (code == null) return false;
      try {
        await _e2eeManager.setupNewKeys(
          userId: response.id,
          recoveryCode: code,
        );
        return true;
      } catch (error) {
        if (mounted) {
          _showMessage(error.toString().replaceFirst('Exception: ', ''));
        }
        return false;
      }
    }

    if (await _e2eeManager.hasLocalKeys(response.id)) {
      return true;
    }

    if (!mounted) return false;
    final code = await showE2eeRecoveryCodeSheet(
      context: context,
      mode: E2eeRecoveryCodeMode.recover,
    );
    if (code == null) return false;
    try {
      await _e2eeManager.recoverKeys(userId: response.id, recoveryCode: code);
      return true;
    } catch (_) {
      if (mounted) {
        _showMessage('Mã khôi phục không đúng hoặc khóa đã bị hỏng.');
      }
      return false;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              margin: const EdgeInsets.fromLTRB(20, 40, 20, 0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.pink.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      Icons.favorite,
                      size: 30,
                      color: const Color.fromARGB(255, 102, 17, 45),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "LoveSync",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 102, 17, 45),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Chào Mừng Quay Lại",
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Roboto",
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Đăng nhập để tiếp tục giữ lửa tình yêu",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: "Roboto",
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Email"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.email_outlined),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(
                              width: 2,
                              color: Color.fromARGB(255, 247, 166, 193),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
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
                        controller: _passwordController,
                        obscureText: !_isShowPassword,
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
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(
                              width: 2,
                              color: Color.fromARGB(255, 247, 166, 193),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
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
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.push(AppRoutes.forgotPassword);
                      },

                      child: const Text("Quên mật khẩu?"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _onClickLogin();
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
                        "Đăng Nhập",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(thickness: 1, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Hoặc đăng nhập bằng",
                        style: TextStyle(color: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Divider(thickness: 1, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onClickGoogleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
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
                        const FaIcon(FontAwesomeIcons.google, size: 20),

                        const SizedBox(width: 8),
                        const Text(
                          "Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Spacer(),
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
                                context.push(AppRoutes.register);
                              },
                              child: const Text("Đăng ký ngay"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
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
