import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lovesync_mobile/features/location/data/datasources/location_socket_datasource.dart';
import 'package:lovesync_mobile/features/location/domain/entities/live_location.dart';
import 'package:lovesync_mobile/features/location/domain/usecases/get_live_locations.dart';
import 'package:lovesync_mobile/features/location/domain/usecases/post_send_location_snapshot.dart';
import 'package:lovesync_mobile/features/location/domain/usecases/post_start_live_location.dart';
import 'package:lovesync_mobile/features/location/domain/usecases/post_stop_live_location.dart';
import 'package:lovesync_mobile/features/location/domain/usecases/put_update_live_location.dart';

class LocationPermissionException implements Exception {
  const LocationPermissionException(
    this.message, {
    this.permanentlyDenied = false,
  });

  final String message;
  final bool permanentlyDenied;

  @override
  String toString() => message;
}

class LocationSharingProvider extends ChangeNotifier {
  LocationSharingProvider({
    required GetLiveLocations getLiveLocations,
    required PostSendLocationSnapshot postSendLocationSnapshot,
    required PostStartLiveLocation postStartLiveLocation,
    required PostStopLiveLocation postStopLiveLocation,
    required PutUpdateLiveLocation putUpdateLiveLocation,
  }) : _getLiveLocations = getLiveLocations,
       _postSendLocationSnapshot = postSendLocationSnapshot,
       _postStartLiveLocation = postStartLiveLocation,
       _postStopLiveLocation = postStopLiveLocation,
       _putUpdateLiveLocation = putUpdateLiveLocation;

  final GetLiveLocations _getLiveLocations;
  final PostSendLocationSnapshot _postSendLocationSnapshot;
  final PostStartLiveLocation _postStartLiveLocation;
  final PostStopLiveLocation _postStopLiveLocation;
  final PutUpdateLiveLocation _putUpdateLiveLocation;

  String _token = '';
  String _userId = '';
  bool _isLoading = false;
  String? _errorMessage;
  LiveLocation? _myLocation;
  LiveLocation? _partnerLocation;
  LocationSocketDatasource? _socket;
  StreamSubscription<LocationSocketEvent>? _socketSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _expiryTimer;
  DateTime? _lastUploadAt;
  bool _uploadingPosition = false;
  int _authGeneration = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LiveLocation? get myLocation => _validLocation(_myLocation);
  LiveLocation? get partnerLocation => _validLocation(_partnerLocation);
  bool get isSharing => myLocation?.isSharing == true;
  bool get shareUntilStopped => myLocation?.untilStopped == true;

  Future<void> updateAuth({
    required String token,
    required String userId,
  }) async {
    if (_token == token && _userId == userId) return;

    _token = token;
    _userId = userId;
    final generation = ++_authGeneration;
    await _disconnect();

    if (token.isEmpty) {
      _myLocation = null;
      _partnerLocation = null;
      notifyListeners();
      return;
    }

    final socket = LocationSocketDatasource(token: token);
    _socket = socket;
    _socketSubscription = socket.events.listen(_handleSocketEvent);
    socket.connect();
    await refresh(silent: true);

    if (generation != _authGeneration) return;
    if (isSharing) {
      await _resumePositionUpdatesIfPermitted();
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (_token.isEmpty || _isLoading) return;
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final locations = await _getLiveLocations();
      _myLocation = locations.mine;
      _partnerLocation = locations.partner;
      _scheduleExpiry();
    } catch (_) {
      if (!silent) {
        _errorMessage = 'Không thể tải trạng thái chia sẻ vị trí.';
      }
    } finally {
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationPermissionException(
        'Dịch vụ vị trí đang tắt. Hãy bật GPS để tiếp tục.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException(
        'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật lại trong Cài đặt.',
        permanentlyDenied: true,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationPermissionException(
        'LoveSync cần quyền vị trí để sử dụng tính năng này.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<void> sendSnapshot(Position position) {
    return _postSendLocationSnapshot(position);
  }

  Future<void> startSharing({
    required int durationMinutes,
    bool untilStopped = false,
    Position? initialPosition,
  }) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      final position = initialPosition ?? await getCurrentPosition();
      final response = await _postStartLiveLocation(
        position,
        durationMinutes: durationMinutes,
        untilStopped: untilStopped,
      );
      _myLocation =
          response ??
          _locationFromPosition(
            position,
            untilStopped: untilStopped,
            sharingExpiresAt: untilStopped
                ? null
                : DateTime.now().add(Duration(minutes: durationMinutes)),
          );
      _scheduleExpiry();
      await _startPositionUpdates();
    } catch (error) {
      _errorMessage = _messageFor(error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> stopSharing() async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      await _postStopLiveLocation();
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _myLocation = null;
      _expiryTimer?.cancel();
    } catch (error) {
      _errorMessage = _messageFor(error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> openLocationSettings({bool appSettings = false}) {
    return appSettings
        ? Geolocator.openAppSettings()
        : Geolocator.openLocationSettings();
  }

  Future<void> _resumePositionUpdatesIfPermitted() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await _startPositionUpdates();
    }
  }

  Future<void> _startPositionUpdates() async {
    await _positionSubscription?.cancel();
    final LocationSettings settings;

    if (!kIsWeb && Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'LoveSync đang chia sẻ vị trí',
          notificationText:
              'Vị trí của bạn đang được chia sẻ trực tiếp với người ấy.',
          enableWakeLock: true,
        ),
      );
    } else if (!kIsWeb && Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        activityType: ActivityType.other,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(_uploadPosition, onError: (_) {});
  }

  Future<void> _uploadPosition(Position position) async {
    if (!isSharing || _uploadingPosition) return;
    final now = DateTime.now();
    if (_lastUploadAt != null &&
        now.difference(_lastUploadAt!) < const Duration(seconds: 8)) {
      return;
    }

    _uploadingPosition = true;
    try {
      LiveLocation? response;
      try {
        response = await _socket?.updateLive(position);
        if (response == null) {
          throw const LocationSocketUpdateException(
            'Socket không trả về vị trí đã lưu.',
            allowRestFallback: true,
          );
        }
      } on LocationSocketUpdateException catch (error) {
        if (!error.allowRestFallback) rethrow;
        response = await _putUpdateLiveLocation(position);
      }
      _lastUploadAt = now;
      _myLocation =
          response ??
          _locationFromPosition(
            position,
            untilStopped: _myLocation?.untilStopped == true,
            sharingExpiresAt: _myLocation?.sharingExpiresAt,
          );
      notifyListeners();
    } catch (_) {
      // Keep the stream alive; the next significant movement retries the update.
    } finally {
      _uploadingPosition = false;
    }
  }

  void _handleSocketEvent(LocationSocketEvent event) {
    if (event.type == LocationSocketEventType.error) return;
    final belongsToMe = event.userId.isNotEmpty && event.userId == _userId;

    if (event.type == LocationSocketEventType.stopped ||
        event.type == LocationSocketEventType.expired) {
      if (belongsToMe) {
        _myLocation = null;
        _positionSubscription?.cancel();
        _positionSubscription = null;
      } else {
        _partnerLocation = null;
      }
      notifyListeners();
      return;
    }

    final location = event.location;
    if (location == null) return;
    if (belongsToMe) {
      _myLocation = location;
    } else {
      _partnerLocation = location;
    }
    _scheduleExpiry();
    notifyListeners();
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final expiries = [
      _myLocation?.sharingExpiresAt,
      _partnerLocation?.sharingExpiresAt,
    ].whereType<DateTime>().toList();
    if (expiries.isEmpty) return;
    expiries.sort();
    final delay = expiries.first.difference(DateTime.now());
    _expiryTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (_myLocation?.isExpired == true) {
        _myLocation = null;
        _positionSubscription?.cancel();
        _positionSubscription = null;
      }
      if (_partnerLocation?.isExpired == true) {
        _partnerLocation = null;
      }
      notifyListeners();
      _scheduleExpiry();
    });
  }

  LiveLocation _locationFromPosition(
    Position position, {
    required bool untilStopped,
    DateTime? sharingExpiresAt,
  }) {
    return LiveLocation(
      userId: _userId,
      isSharing: true,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      heading: position.heading,
      speed: position.speed,
      capturedAt: position.timestamp,
      untilStopped: untilStopped,
      sharingExpiresAt: sharingExpiresAt,
    );
  }

  LiveLocation? _validLocation(LiveLocation? location) {
    if (location == null || !location.isSharing || location.isExpired) {
      return null;
    }
    return location;
  }

  String _messageFor(Object error) {
    if (error is LocationPermissionException) return error.message;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message != null && message.toString().isNotEmpty) {
          return message.toString();
        }
      }
    }
    return 'Không thể cập nhật vị trí. Vui lòng thử lại.';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  Future<void> _disconnect() async {
    _expiryTimer?.cancel();
    await _positionSubscription?.cancel();
    await _socketSubscription?.cancel();
    await _socket?.dispose();
    _positionSubscription = null;
    _socketSubscription = null;
    _socket = null;
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }
}
