class LiveLocation {
  const LiveLocation({
    required this.userId,
    required this.isSharing,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    this.address,
    this.capturedAt,
    this.untilStopped = false,
    this.sharingExpiresAt,
  });

  final String userId;
  final bool isSharing;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final String? address;
  final DateTime? capturedAt;
  final bool untilStopped;
  final DateTime? sharingExpiresAt;

  bool get isExpired =>
      sharingExpiresAt != null && !sharingExpiresAt!.isAfter(DateTime.now());
}
