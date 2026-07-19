import 'package:lovesync_mobile/features/call/domain/entities/call_session.dart';

class CallModel {
  const CallModel({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.roomName,
    required this.type,
    required this.status,
  });

  final String id;
  final String callerId;
  final String calleeId;
  final String roomName;
  final String type;
  final String status;

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: _readId(json['_id'] ?? json['id'] ?? json['callId']),
      callerId: _readId(json['caller'] ?? json['callerId']),
      calleeId: _readId(json['callee'] ?? json['calleeId']),
      roomName: json['roomName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  CallSession toEntity() {
    return CallSession(
      id: id,
      callerId: callerId,
      calleeId: calleeId,
      roomName: roomName,
      type: type,
      status: CallStatus.fromValue(status),
    );
  }

  static String _readId(dynamic value) {
    if (value is Map) {
      return (value['_id'] ?? value['id'])?.toString() ?? '';
    }
    return value?.toString() ?? '';
  }
}

class CallConnectionModel {
  const CallConnectionModel({required this.call, this.liveKit});

  final CallModel call;
  final LiveKitCredentials? liveKit;

  factory CallConnectionModel.fromJson(dynamic data) {
    final json = _asJson(data);
    final callJson = _extractCallJson(json);
    final dataJson = _asJson(json['data']);
    final liveKitJson = _asJson(json['livekit'] ?? dataJson['livekit']);
    final serverUrl = liveKitJson['serverUrl']?.toString() ?? '';
    final token = liveKitJson['participantToken']?.toString() ?? '';

    return CallConnectionModel(
      call: CallModel.fromJson(callJson),
      liveKit: serverUrl.isNotEmpty && token.isNotEmpty
          ? LiveKitCredentials(serverUrl: serverUrl, participantToken: token)
          : null,
    );
  }

  CallConnection toEntity() {
    return CallConnection(call: call.toEntity(), liveKit: liveKit);
  }

  static Map<String, dynamic> _asJson(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const {};
  }

  static Map<String, dynamic> _extractCallJson(Map<String, dynamic> original) {
    var current = original;
    for (var depth = 0; depth < 3; depth++) {
      final nested =
          current['call'] ?? current['activeCall'] ?? current['data'];
      final nestedJson = _asJson(nested);
      if (nestedJson.isEmpty) break;
      current = nestedJson;
    }
    return current;
  }
}
