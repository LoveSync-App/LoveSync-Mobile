import 'package:geolocator/geolocator.dart';
import 'package:lovesync_mobile/features/location/domain/entities/live_location.dart';
import 'package:lovesync_mobile/features/location/domain/repositories/location_repository.dart';

class PutUpdateLiveLocation {
  const PutUpdateLiveLocation(this.repository);

  final LocationRepository repository;

  Future<LiveLocation?> call(Position position) {
    return repository.updateLive(position);
  }
}
