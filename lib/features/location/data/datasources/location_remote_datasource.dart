import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lovesync_mobile/features/location/data/models/live_location_model.dart';
import 'package:lovesync_mobile/features/location/domain/entities/live_location.dart';

class LocationRemoteDatasource {
  const LocationRemoteDatasource(this.dio);

  final Dio dio;

  Future<void> sendSnapshot(Position position) async {
    await dio.post(
      '/chat/location',
      data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'label': 'Vị trí hiện tại',
        'capturedAt': position.timestamp.toUtc().toIso8601String(),
      },
    );
  }

  Future<LiveLocation?> startLive(
    Position position, {
    required int durationMinutes,
    required bool untilStopped,
  }) async {
    final response = await dio.post(
      '/locations/live/start',
      data: {
        ..._positionData(position),
        'untilStopped': untilStopped,
        if (!untilStopped) 'durationMinutes': durationMinutes,
      },
    );
    return LiveLocationModel.fromData(response.data);
  }

  Future<LiveLocation?> updateLive(Position position) async {
    final response = await dio.put(
      '/locations/live',
      data: _positionData(position),
    );
    return LiveLocationModel.fromData(response.data);
  }

  Future<void> stopLive() async {
    await dio.post('/locations/live/stop');
  }

  Future<LiveLocation?> getMyLive() async {
    try {
      final response = await dio.get('/locations/live/me');
      return LiveLocationModel.fromData(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<LiveLocation?> getPartnerLive() async {
    try {
      final response = await dio.get('/locations/live/partner');
      return LiveLocationModel.fromData(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Map<String, dynamic> _positionData(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'heading': position.heading,
      'speed': position.speed,
      'capturedAt': position.timestamp.toUtc().toIso8601String(),
    };
  }
}
