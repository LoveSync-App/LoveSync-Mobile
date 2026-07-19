import 'package:lovesync_mobile/features/auth/domain/entities/login_response.dart';
import 'package:lovesync_mobile/features/auth/domain/entities/register_response.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(String email, String password);
  Future<LoginResponse> loginWithGoogle({
    required String firebaseIdToken,
    required String name,
    required String avatar,
  });
  Future<RegisterResponse> register(
    String email,
    String password,
    String passwordConfirm,
    String name,
  );
  Future<int> requestPasswordResetOtp(String email);
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirm,
  });
  Future<void> addPassword({
    required String password,
    required String passwordConfirm,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  });
}
