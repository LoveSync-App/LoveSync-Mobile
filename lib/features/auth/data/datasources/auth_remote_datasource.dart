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
