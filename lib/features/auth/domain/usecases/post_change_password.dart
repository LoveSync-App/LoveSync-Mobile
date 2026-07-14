import 'package:lovesync_mobile/features/auth/domain/repositories/auth_repository.dart';

class PostChangePassword {
  final AuthRepository authRepository;

  PostChangePassword(this.authRepository);

  Future<void> call({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) {
    return authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      newPasswordConfirm: newPasswordConfirm,
    );
  }
}
