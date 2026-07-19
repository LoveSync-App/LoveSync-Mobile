import 'package:lovesync_mobile/features/user/domain/repositories/user_repository.dart';

class PostRegisterDevice {
  final UserRepository repository;

  PostRegisterDevice(this.repository);

  Future<void> call(String token) async {
    await repository.postRegisterToken(token);
  }
}
