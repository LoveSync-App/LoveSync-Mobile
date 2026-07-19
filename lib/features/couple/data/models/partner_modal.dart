class PartnerModal {
  final String partnerId;
  final String partnerName;
  final String partnerAvatar;
  final String partnerEmail;
  final String partnerPhone;

  PartnerModal({
    required this.partnerId,
    required this.partnerName,
    required this.partnerAvatar,
    required this.partnerEmail,
    required this.partnerPhone,
  });

  factory PartnerModal.fromJson(Map<String, dynamic> json) {
    return PartnerModal(
      partnerId: json['partnerId'] as String,
      partnerName: json['partnerName'] as String,
      partnerAvatar: json['partnerAvatar'] as String,
      partnerEmail: json['partnerEmail'] as String,
      partnerPhone: json['partnerPhone'] as String,
    );
  }
}
