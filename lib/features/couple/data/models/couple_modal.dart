class CoupleModal {
  String coupleId;
  String userId;
  String userName;
  String userAvatar;
  String userEmail;
  String userPhone;
  String partnerId;
  String partnerName;
  String partnerAvatar;
  String partnerEmail;
  String partnerPhone;
  DateTime startDate;

  CoupleModal({
    required this.coupleId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userEmail,
    required this.userPhone,
    required this.partnerId,
    required this.partnerName,
    required this.partnerAvatar,
    required this.partnerEmail,
    required this.partnerPhone,
    required this.startDate,
  });

  factory CoupleModal.fromJson(Map<String, dynamic> json) {
    return CoupleModal(
      coupleId: json['coupleId'],
      userId: json['userId'],
      userName: json['userName'],
      userAvatar: json['userAvatar'],
      userEmail: json['userEmail'],
      userPhone: json['userPhone'],
      partnerId: json['partnerId'],
      partnerName: json['partnerName'],
      partnerAvatar: json['partnerAvatar'],
      partnerEmail: json['partnerEmail'],
      partnerPhone: json['partnerPhone'],
      startDate: DateTime.parse(json['startDate']),
    );
  }
}
