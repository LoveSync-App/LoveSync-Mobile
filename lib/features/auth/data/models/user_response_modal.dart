class UserResponseModal {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final bool e2eeSetupRequired;

  UserResponseModal({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.e2eeSetupRequired,
  });

  factory UserResponseModal.fromJson(Map<String, dynamic> json) {
    return UserResponseModal(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      e2eeSetupRequired: json['e2eeSetupRequired'] == true,
    );
  }
}
