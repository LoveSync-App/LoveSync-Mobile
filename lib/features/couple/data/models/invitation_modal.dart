class InvitationModal {
  final String invitationId;
  final String partnerName;
  final String partnerAvatar;

  InvitationModal({
    required this.invitationId,
    required this.partnerName,
    required this.partnerAvatar,
  });

  factory InvitationModal.fromJson(Map<String, dynamic> json) {
    return InvitationModal(
      invitationId: json['id'],
      partnerName: json['partnerName'],
      partnerAvatar: json['partnerAvatar'],
    );
  }
}
