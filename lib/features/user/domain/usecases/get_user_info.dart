import 'package:lovesync_mobile/features/user/domain/entities/user_response.dart';
import 'package:lovesync_mobile/features/user/domain/repositories/user_repository.dart';

class GetUserInfo {
  final UserRepository repository;
  GetUserInfo(this.repository);

  Future<UserResponse> call() async {
    return await repository.getUserInfo();
  }
}
