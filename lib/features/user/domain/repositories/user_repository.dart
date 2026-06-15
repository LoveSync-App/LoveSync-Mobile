import 'package:lovesync_mobile/features/user/domain/entities/user_response.dart';

abstract class UserRepository {
  Future<UserResponse> getUserInfo();
  Future<void> postRegisterToken(String token);
}