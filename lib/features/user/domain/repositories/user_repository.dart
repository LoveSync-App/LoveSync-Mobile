import 'package:lovesync_mobile/features/user/domain/entities/user_response.dart';

abstract class UserRepository {
  Future<UserResponse> getUserInfo();
  Future<UserResponse> updateMe({
    required String name,
    required String phone,
    required String avatar,
  });
  Future<UserResponse> deleteMe();
  Future<void> postRegisterToken(String token);
}
