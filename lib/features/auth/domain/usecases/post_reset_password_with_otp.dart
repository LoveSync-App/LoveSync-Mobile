import 'package:lovesync_mobile/features/auth/domain/repositories/auth_repository.dart';

class PostResetPasswordWithOtp {
  final AuthRepository authRepository;

  PostResetPasswordWithOtp(this.authRepository);

  Future<void> call({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirm,
  }) {
    return authRepository.resetPasswordWithOtp(
      email: email,
      otp: otp,
      password: password,
      passwordConfirm: passwordConfirm,
    );
  }
}
