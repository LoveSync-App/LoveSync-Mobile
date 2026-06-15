import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/auth/data/models/login_response_model.dart';

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
}
