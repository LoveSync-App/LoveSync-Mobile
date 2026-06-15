class CoupleModal {
  String coupleId;
  String userId;
  String userName;
  String userAvatar;
  String userEmail;
  String partnerId;
  String partnerName;
  String partnerAvatar;
  String partnerEmail;

  CoupleModal({
    required this.coupleId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userEmail,
    required this.partnerId,
    required this.partnerName,
    required this.partnerAvatar,
    required this.partnerEmail,
  });

  factory CoupleModal.fromJson(Map<String, dynamic> json) {
    return CoupleModal(
      coupleId: json['coupleId'],
      userId: json['userId'],
      userName: json['userName'],
      userAvatar: json['userAvatar'],
      userEmail: json['userEmail'],
      partnerId: json['partnerId'],
      partnerName: json['partnerName'],
      partnerAvatar: json['partnerAvatar'],
      partnerEmail: json['partnerEmail'],
    );
  }
}
