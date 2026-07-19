enum CallStatus {
  ringing,
  ongoing,
  ended,
  rejected,
  canceled,
  missed,
  unknown;

  static CallStatus fromValue(String? value) {
    return switch (value?.toLowerCase()) {
      'ringing' => CallStatus.ringing,
      'ongoing' => CallStatus.ongoing,
      'ended' => CallStatus.ended,
      'rejected' => CallStatus.rejected,
      'canceled' || 'cancelled' => CallStatus.canceled,
      'missed' => CallStatus.missed,
      _ => CallStatus.unknown,
    };
  }
}

class CallSession {
  const CallSession({
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
  final CallStatus status;

  bool isCaller(String userId) => callerId == userId;
}

class LiveKitCredentials {
  const LiveKitCredentials({
    required this.serverUrl,
    required this.participantToken,
  });

  final String serverUrl;
  final String participantToken;
}

class CallConnection {
  const CallConnection({required this.call, this.liveKit});

  final CallSession call;
  final LiveKitCredentials? liveKit;
}
