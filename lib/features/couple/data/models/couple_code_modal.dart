class CoupleCodeModal {
  final String userId;
  final String code;

  CoupleCodeModal({required this.userId, required this.code});

  factory CoupleCodeModal.fromJson(Map<String, dynamic> json) {
    return CoupleCodeModal(
      userId: json['userId'] as String,
      code: json['code'] as String,
    );
  }
}
