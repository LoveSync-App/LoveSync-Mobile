import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:lovesync_mobile/core/constants/api_constants.dart';
import 'package:lovesync_mobile/features/location/data/models/live_location_model.dart';
import 'package:lovesync_mobile/features/location/domain/entities/live_location.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

enum LocationSocketEventType { started, updated, stopped, expired, error }

class LocationSocketEvent {
  const LocationSocketEvent({
    required this.type,
    this.location,
    this.userId = '',
  });

  final LocationSocketEventType type;
  final LiveLocation? location;
  final String userId;
}

class LocationSocketDatasource {
  LocationSocketDatasource({required this.token});

  final String token;
  final StreamController<LocationSocketEvent> _events =
      StreamController<LocationSocketEvent>.broadcast();
  io.Socket? _socket;
  bool _ackUpdatesEnabled = true;

  Stream<LocationSocketEvent> get events => _events.stream;
  bool get isConnected => _socket?.connected == true;

  void connect() {
    disconnect();
    _ackUpdatesEnabled = true;
    final socket = io.io(
      '${ApiConstants.socketOrigin}/locations',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;

    socket.on(
      'location:sharing-started',
      (data) => _emitLocation(LocationSocketEventType.started, data),
    );
    socket.on(
      'location:updated',
      (data) => _emitLocation(LocationSocketEventType.updated, data),
    );
    socket.on(
      'location:sharing-stopped',
      (data) => _emitStopped(LocationSocketEventType.stopped, data),
    );
    socket.on(
      'location:sharing-expired',
      (data) => _emitStopped(LocationSocketEventType.expired, data),
    );
    socket.on(
      'locations:error',
      (_) =>
          _add(const LocationSocketEvent(type: LocationSocketEventType.error)),
    );
    socket.connect();
  }

  Future<LiveLocation?> updateLive(Position position) async {
    final socket = _socket;
    if (socket == null || !socket.connected || !_ackUpdatesEnabled) {
      throw const LocationSocketUpdateException(
        'Socket cập nhật vị trí chưa sẵn sàng.',
        allowRestFallback: true,
      );
    }

    final completer = Completer<LiveLocation?>();
    final timeout = Timer(const Duration(seconds: 5), () {
      _ackUpdatesEnabled = false;
      if (!completer.isCompleted) {
        completer.completeError(
          const LocationSocketUpdateException(
            'Server không phản hồi location:update.',
            allowRestFallback: true,
          ),
        );
      }
    });

    socket.emitWithAck(
      'location:update',
      _positionData(position),
      ack: (data) {
        if (completer.isCompleted) return;
        timeout.cancel();
        final json = _asJson(data);
        if (json['ok'] == false) {
          completer.completeError(
            LocationSocketUpdateException(
              (json['message'] ?? json['error'] ?? 'Cập nhật thất bại.')
                  .toString(),
            ),
          );
          return;
        }
        completer.complete(LiveLocationModel.fromData(data));
      },
    );

    return completer.future;
  }

  void disconnect() {
    final socket = _socket;
    if (socket == null) return;
    socket.dispose();
    _socket = null;
  }

  Future<void> dispose() async {
    disconnect();
    await _events.close();
  }

  void _emitLocation(LocationSocketEventType type, dynamic data) {
    final location = LiveLocationModel.fromData(data);
    if (location == null) return;
    _add(
      LocationSocketEvent(
        type: type,
        location: location,
        userId: location.userId,
      ),
    );
  }

  void _emitStopped(LocationSocketEventType type, dynamic data) {
    _add(
      LocationSocketEvent(
        type: type,
        userId: LiveLocationModel.readUserId(data),
      ),
    );
  }

  void _add(LocationSocketEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  Map<String, dynamic> _asJson(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  Map<String, dynamic> _positionData(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      if (position.heading >= 0) 'heading': position.heading,
      if (position.speed >= 0) 'speed': position.speed,
      'capturedAt': position.timestamp.toUtc().toIso8601String(),
    };
  }
}

class LocationSocketUpdateException implements Exception {
  const LocationSocketUpdateException(
    this.message, {
    this.allowRestFallback = false,
  });

  final String message;
  final bool allowRestFallback;

  @override
  String toString() => message;
}
