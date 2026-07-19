import 'package:lovesync_mobile/features/auth/domain/repositories/auth_repository.dart';

class PostAddPassword {
  final AuthRepository authRepository;

  PostAddPassword(this.authRepository);

  Future<void> call({
    required String password,
    required String passwordConfirm,
  }) {
    return authRepository.addPassword(
      password: password,
      passwordConfirm: passwordConfirm,
    );
  }
}
