import 'package:geolocator/geolocator.dart';
import 'package:lovesync_mobile/features/location/domain/repositories/location_repository.dart';

class PostSendLocationSnapshot {
  const PostSendLocationSnapshot(this.repository);

  final LocationRepository repository;

  Future<void> call(Position position) {
    return repository.sendSnapshot(position);
  }
}
