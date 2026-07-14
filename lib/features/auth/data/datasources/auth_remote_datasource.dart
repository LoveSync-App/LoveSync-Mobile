import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/auth/data/models/login_response_model.dart';
import 'package:lovesync_mobile/features/auth/data/models/register_response_model.dart';

class AuthRemoteDatasource {
  final Dio dio;
  AuthRemoteDatasource(this.dio);

  Future<LoginResponseModel> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return LoginResponseModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Mật khẩu hoặc email không đúng');
      } else {
        throw Exception('Lỗi khi kết nối đến server');
      }
    }
  }

  Future<LoginResponseModel> loginWithGoogle({
    required String firebaseIdToken,
    required String name,
    required String avatar,
  }) async {
    try {
      final response = await dio.post(
        '/auth/google',
        data: {
          'firebaseIdToken': firebaseIdToken,
          'name': name,
          'avatar': avatar,
        },
      );
      final root = response.data;
      final data = root is Map ? root['data'] : null;
      if (data is! Map) {
        throw const FormatException('Invalid Google login response');
      }
      return LoginResponseModel.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map
          ? (data['message'] ?? data['error'])?.toString()
          : null;
      throw Exception(message ?? 'Không thể đăng nhập bằng Google');
    }
  }

  Future<void> logout() async {
    await dio.post('/auth/logout');
  }

  Future<int> requestPasswordResetOtp(String email) async {
    try {
      final response = await dio.post(
        '/auth/password/forgot',
        data: {'email': email},
      );
      final data = response.data['data'];
      if (data is Map) {
        return int.tryParse(data['expiresInSeconds']?.toString() ?? '') ?? 300;
      }
      return 300;
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error, 'Khong the gui ma OTP.'));
    }
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      await dio.post(
        '/auth/password/reset',
        data: {
          'email': email,
          'otp': otp,
          'password': password,
          'passwordConfirm': passwordConfirm,
        },
      );
    } on DioException catch (error) {
      throw Exception(
        _readErrorMessage(error, 'OTP khong dung hoac da het han.'),
      );
    }
  }

  Future<void> addPassword({
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      await dio.post(
        '/auth/password',
        data: {'password': password, 'passwordConfirm': passwordConfirm},
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error, 'Khong the cap nhat mat khau.'));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      await dio.post(
        '/auth/password/change',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'newPasswordConfirm': newPasswordConfirm,
        },
      );
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error, 'Không thể đổi mật khẩu.'));
    }
  }

  Future<RegisterResponseModel> register(
    String email,
    String password,
    String passwordConfirm,
    String name,
  ) async {
    final response = await dio.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'passwordConfirm': passwordConfirm,
        'name': name,
      },
    );
    return RegisterResponseModel.fromJson(response.data['data']);
  }

  String _readErrorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }
    return fallback;
  }
}
