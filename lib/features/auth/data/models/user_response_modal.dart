class UserResponseModal {
  final String id;
  final String name;
  final String email;
  final String avatar;

  UserResponseModal({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
  });

  factory UserResponseModal.fromJson(Map<String, dynamic> json) {
    return UserResponseModal(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String,
    );
  }
}
