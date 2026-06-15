class LoginResponse {
  final String accessToken;

  final String id;
  final String email;
  final String name;

  LoginResponse({required this.id, required this.email, required this.name, required this.accessToken});
}
