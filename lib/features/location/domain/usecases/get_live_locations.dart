import 'package:lovesync_mobile/features/location/domain/entities/live_location.dart';
import 'package:lovesync_mobile/features/location/domain/repositories/location_repository.dart';

class LiveLocations {
  const LiveLocations({this.mine, this.partner});

  final LiveLocation? mine;
  final LiveLocation? partner;
}

class GetLiveLocations {
  const GetLiveLocations(this.repository);

  final LocationRepository repository;

  Future<LiveLocations> call() async {
    final results = await Future.wait([
      repository.getMyLive(),
      repository.getPartnerLive(),
    ]);
    return LiveLocations(mine: results[0], partner: results[1]);
  }
}
