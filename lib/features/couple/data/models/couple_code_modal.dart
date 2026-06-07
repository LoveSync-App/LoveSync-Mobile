class CoupleCodeModal {
  final String code;

  CoupleCodeModal({required this.code});

  factory CoupleCodeModal.fromJson(Map<String, dynamic> json) {
    return CoupleCodeModal(code: json['code'] as String);
  }
}
