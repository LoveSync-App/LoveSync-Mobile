import 'package:flutter_test/flutter_test.dart';
import 'package:lovesync_mobile/features/location/data/models/live_location_model.dart';

void main() {
  group('LiveLocationModel', () {
    test('parses a realtime location payload', () {
      final location = LiveLocationModel.fromData({
        'userId': 'partner-id',
        'isSharing': true,
        'latitude': 10.7775,
        'longitude': 106.7015,
        'accuracy': 6,
        'heading': 125,
        'speed': 1.5,
        'untilStopped': true,
        'capturedAt': '2026-07-01T10:30:10.000Z',
        'sharingExpiresAt': null,
      });

      expect(location, isNotNull);
      expect(location!.userId, 'partner-id');
      expect(location.isSharing, isTrue);
      expect(location.latitude, 10.7775);
      expect(location.longitude, 106.7015);
      expect(location.accuracy, 6);
      expect(location.untilStopped, isTrue);
      expect(location.sharingExpiresAt, isNull);
    });

    test('returns null when a stopped payload has no coordinates', () {
      final location = LiveLocationModel.fromData({
        'userId': 'partner-id',
        'isSharing': false,
      });

      expect(location, isNull);
      expect(
        LiveLocationModel.readUserId({'userId': 'partner-id'}),
        'partner-id',
      );
    });
  });
}
