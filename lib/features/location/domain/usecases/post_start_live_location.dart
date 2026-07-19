import 'package:geolocator/geolocator.dart';
import 'package:lovesync_mobile/features/location/domain/entities/live_location.dart';
import 'package:lovesync_mobile/features/location/domain/repositories/location_repository.dart';

class PostStartLiveLocation {
  const PostStartLiveLocation(this.repository);

  final LocationRepository repository;

  Future<LiveLocation?> call(
    Position position, {
    required int durationMinutes,
    required bool untilStopped,
  }) {
    return repository.startLive(
      position,
      durationMinutes: durationMinutes,
      untilStopped: untilStopped,
    );
  }
}
