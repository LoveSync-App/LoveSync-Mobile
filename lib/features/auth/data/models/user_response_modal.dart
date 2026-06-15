class UserResponseModal {
  final String id;
  final String name;
  final String email;

  UserResponseModal({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserResponseModal.fromJson(Map<String, dynamic> json) {
    return UserResponseModal(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}
