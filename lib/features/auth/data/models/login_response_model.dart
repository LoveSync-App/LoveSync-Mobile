import 'package:lovesync_mobile/features/auth/data/models/user_response_modal.dart';

class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserResponseModal user;

  LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserResponseModal.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
