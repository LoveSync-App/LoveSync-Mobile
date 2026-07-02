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
}
