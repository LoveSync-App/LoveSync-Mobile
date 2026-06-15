import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/auth/data/models/user_response_modal.dart';

class UserRemoteDatasource {
  final Dio dio;
  UserRemoteDatasource(this.dio);

  Future<UserResponseModal> getUserInfo() async {
    final response = await dio.get('/users/me');
    return UserResponseModal.fromJson(response.data['data']);
  }
}
