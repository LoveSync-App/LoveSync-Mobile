import 'package:lovesync_mobile/features/auth/domain/entities/login_response.dart';
import 'package:lovesync_mobile/features/auth/domain/repositories/auth_repository.dart';

class PostGoogleLogin {
  const PostGoogleLogin(this.authRepository);

  final AuthRepository authRepository;

  Future<LoginResponse> call({
    required String firebaseIdToken,
    required String name,
    required String avatar,
  }) {
    return authRepository.loginWithGoogle(
      firebaseIdToken: firebaseIdToken,
      name: name,
      avatar: avatar,
    );
  }
}
