import 'package:lovesync_mobile/features/auth/domain/repositories/auth_repository.dart';

class PostRequestPasswordResetOtp {
  final AuthRepository authRepository;

  PostRequestPasswordResetOtp(this.authRepository);

  Future<int> call(String email) {
    return authRepository.requestPasswordResetOtp(email);
  }
}
