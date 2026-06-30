import 'package:lovesync_mobile/features/user/domain/entities/user_response.dart';
import 'package:lovesync_mobile/features/user/domain/repositories/user_repository.dart';

class DeleteMe {
  const DeleteMe(this.repository);

  final UserRepository repository;

  Future<UserResponse> call() async {
    return await repository.deleteMe();
  }
}
