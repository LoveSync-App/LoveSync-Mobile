class LoginResponse {
  final String accessToken;
  final String refreshToken;

  final String id;
  final String email;
  final String name;
  final String avatar;
  final bool e2eeSetupRequired;

  LoginResponse({
    required this.id,
    required this.email,
    required this.name,
    required this.accessToken,
    required this.refreshToken,
    required this.avatar,
    required this.e2eeSetupRequired,
  });
}
