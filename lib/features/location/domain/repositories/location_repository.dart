import 'package:geolocator/geolocator.dart';
import 'package:lovesync_mobile/features/location/domain/entities/live_location.dart';

abstract class LocationRepository {
  Future<void> sendSnapshot(Position position);

  Future<LiveLocation?> startLive(
    Position position, {
    required int durationMinutes,
    required bool untilStopped,
  });

  Future<LiveLocation?> updateLive(Position position);

  Future<void> stopLive();

  Future<LiveLocation?> getMyLive();

  Future<LiveLocation?> getPartnerLive();
}
