import 'package:lovesync_mobile/features/user/domain/entities/user_response.dart';
import 'package:lovesync_mobile/features/user/domain/repositories/user_repository.dart';

class PatchUpdateMe {
  const PatchUpdateMe(this.repository);

  final UserRepository repository;

  Future<UserResponse> call({
    required String name,
    required String phone,
    required String avatar,
  }) async {
    return await repository.updateMe(name: name, phone: phone, avatar: avatar);
  }
}
