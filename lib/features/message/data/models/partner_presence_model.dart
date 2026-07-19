class PartnerPresenceModel {
  const PartnerPresenceModel({
    required this.userId,
    required this.isOnline,
    this.connectedAt,
    this.lastSeenAt,
  });

  final String userId;
  final bool isOnline;
  final DateTime? connectedAt;
  final DateTime? lastSeenAt;

  factory PartnerPresenceModel.fromData(dynamic data) {
    var json = _asJson(data);
    final nestedData = json['data'];
    if (nestedData is Map) json = _asJson(nestedData);
    final partnerPresence = json['partnerPresence'];
    if (partnerPresence is Map) json = _asJson(partnerPresence);

    return PartnerPresenceModel(
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      isOnline: json['isOnline'] == true,
      connectedAt: _readDate(json['connectedAt']),
      lastSeenAt: _readDate(json['lastSeenAt']),
    );
  }

  static Map<String, dynamic> _asJson(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static DateTime? _readDate(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
}
