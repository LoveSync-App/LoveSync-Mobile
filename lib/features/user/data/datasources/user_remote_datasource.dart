import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/user/data/models/user_response_model.dart';

class UserRemoteDatasource {
  final Dio dio;
  UserRemoteDatasource(this.dio);

  Future<UserResponseModel> getUserInfo() async {
    final response = await dio.get('/users/me');
    return UserResponseModel.fromJson(response.data['data']);
  }

  Future<UserResponseModel> updateMe({
    required String name,
    required String phone,
    required String avatar,
  }) async {
    final response = await dio.patch(
      '/users/me',
      data: {'name': name, 'phone': phone, 'avatar': avatar},
    );
    return UserResponseModel.fromJson(response.data['data']);
  }

  Future<UserResponseModel> deleteMe() async {
    final response = await dio.delete('/users/me');
    return UserResponseModel.fromJson(response.data['data']);
  }

  Future<void> postRegisterToken(String token) async {
    await dio.post('/device', data: {'token': token});
  }
}
