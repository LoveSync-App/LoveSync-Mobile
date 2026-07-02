import 'package:lovesync_mobile/features/location/domain/entities/live_location.dart';

class LiveLocationModel {
  const LiveLocationModel._();

  static LiveLocation? fromData(dynamic data) {
    final source = _unwrap(data);
    final latitude = _readDouble(source['latitude']);
    final longitude = _readDouble(source['longitude']);
    final isSharing = source['isSharing'] != false;

    if (latitude == null || longitude == null) {
      return null;
    }

    return LiveLocation(
      userId: (source['userId'] ?? source['user_id'] ?? '').toString(),
      isSharing: isSharing,
      latitude: latitude,
      longitude: longitude,
      accuracy: _readDouble(source['accuracy']),
      heading: _readDouble(source['heading']),
      speed: _readDouble(source['speed']),
      address: source['address']?.toString(),
      capturedAt: _readDate(source['capturedAt']),
      untilStopped: source['untilStopped'] == true,
      sharingExpiresAt: _readDate(source['sharingExpiresAt']),
    );
  }

  static String readUserId(dynamic data) {
    final source = _unwrap(data);
    return (source['userId'] ?? source['user_id'] ?? '').toString();
  }

  static Map<String, dynamic> _unwrap(dynamic data) {
    var source = _asJson(data);
    for (final key in ['data', 'location', 'liveLocation', 'session']) {
      final nested = source[key];
      if (nested is Map) {
        source = _asJson(nested);
        break;
      }
    }
    return source;
  }

  static Map<String, dynamic> _asJson(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _readDate(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
}
