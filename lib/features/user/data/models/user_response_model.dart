class UserResponseModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String status;
  final String avatar;

  UserResponseModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.status,
    required this.avatar,
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
    );
  }
}
