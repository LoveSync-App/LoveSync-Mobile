import 'package:geolocator/geolocator.dart';
import 'package:lovesync_mobile/features/location/data/datasources/location_remote_datasource.dart';
import 'package:lovesync_mobile/features/location/domain/entities/live_location.dart';
import 'package:lovesync_mobile/features/location/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this.remoteDatasource);

  final LocationRemoteDatasource remoteDatasource;

  @override
  Future<LiveLocation?> getMyLive() => remoteDatasource.getMyLive();

  @override
  Future<LiveLocation?> getPartnerLive() => remoteDatasource.getPartnerLive();

  @override
  Future<void> sendSnapshot(Position position) {
    return remoteDatasource.sendSnapshot(position);
  }

  @override
  Future<LiveLocation?> startLive(
    Position position, {
    required int durationMinutes,
    required bool untilStopped,
  }) {
    return remoteDatasource.startLive(
      position,
      durationMinutes: durationMinutes,
      untilStopped: untilStopped,
    );
  }

  @override
  Future<void> stopLive() => remoteDatasource.stopLive();

  @override
  Future<LiveLocation?> updateLive(Position position) {
    return remoteDatasource.updateLive(position);
  }
}
