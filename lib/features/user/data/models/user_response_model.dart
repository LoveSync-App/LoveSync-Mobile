class UserResponseModel {
  final String id;
  final String email;
  final String name;
  final String avatar;

  UserResponseModel({
    required this.id,
    required this.email,
    required this.name,
    required this.avatar,
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatar: json['avatar'],
    );
  }
}
