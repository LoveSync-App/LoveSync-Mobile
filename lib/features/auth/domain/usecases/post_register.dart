import 'package:lovesync_mobile/features/auth/domain/entities/register_response.dart';
import 'package:lovesync_mobile/features/auth/domain/repositories/auth_repository.dart';

class PostRegister {
  final AuthRepository authRepository;

  PostRegister(this.authRepository);

  Future<RegisterResponse> call(
    String email,
    String password,
    String passwordConfirm,
    String name,
  ) async {
    return await authRepository.register(
      email,
      password,
      passwordConfirm,
      name,
    );
  }
}
