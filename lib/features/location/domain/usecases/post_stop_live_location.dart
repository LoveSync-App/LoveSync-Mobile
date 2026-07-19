import 'package:lovesync_mobile/features/location/domain/repositories/location_repository.dart';

class PostStopLiveLocation {
  const PostStopLiveLocation(this.repository);

  final LocationRepository repository;

  Future<void> call() {
    return repository.stopLive();
  }
}
