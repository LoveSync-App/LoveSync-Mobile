import 'package:lovesync_mobile/features/auth/domain/entities/login_response.dart';
import 'package:lovesync_mobile/features/auth/domain/repositories/auth_repository.dart';

class PostLogin {
  final AuthRepository authRepository;

  PostLogin(this.authRepository);

  Future<LoginResponse> call(String email, String password) async {
    return await authRepository.login(email, password);
  }
}
