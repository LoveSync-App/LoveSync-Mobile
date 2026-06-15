import 'package:lovesync_mobile/features/auth/domain/entities/login_response.dart';
import 'package:lovesync_mobile/features/auth/domain/entities/register_response.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(String email, String password);
  Future<RegisterResponse> register(
    String email,
    String password,
    String passwordConfirm,
    String name,
  );
}
