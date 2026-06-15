class RegisterResponseModel {
  final String id;
  final String email;
  final String name;
  final String avatar;

  RegisterResponseModel({
    required this.id,
    required this.email,
    required this.name,
    required this.avatar,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatar: json['avatar'] ?? '',
    );
  }
}
