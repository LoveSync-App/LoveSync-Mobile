import 'package:lovesync_mobile/features/auth/domain/entities/login_response.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(String email, String password);
}
