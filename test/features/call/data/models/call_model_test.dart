import 'package:flutter_test/flutter_test.dart';
import 'package:lovesync_mobile/features/call/data/models/call_model.dart';
import 'package:lovesync_mobile/features/call/domain/entities/call_session.dart';

void main() {
  test('parses create and accept response with LiveKit credentials', () {
    final connection = CallConnectionModel.fromJson({
      'call': {
        '_id': 'call-1',
        'caller': 'user-1',
        'callee': 'user-2',
        'roomName': 'call_room_1',
        'type': 'audio',
        'status': 'ringing',
      },
      'livekit': {
        'serverUrl': 'wss://example.livekit.cloud',
        'participantToken': 'participant-token',
      },
    }).toEntity();

    expect(connection.call.id, 'call-1');
    expect(connection.call.status, CallStatus.ringing);
    expect(connection.call.isCaller('user-1'), isTrue);
    expect(connection.liveKit?.serverUrl, 'wss://example.livekit.cloud');
    expect(connection.liveKit?.participantToken, 'participant-token');
  });

  test('parses nested socket payload and populated participant ids', () {
    final connection = CallConnectionModel.fromJson({
      'data': {
        'call': {
          'id': 'call-2',
          'caller': {'_id': 'user-1'},
          'callee': {'id': 'user-2'},
          'roomName': 'call_room_2',
          'type': 'video',
          'status': 'ongoing',
        },
      },
    }).toEntity();

    expect(connection.call.id, 'call-2');
    expect(connection.call.callerId, 'user-1');
    expect(connection.call.calleeId, 'user-2');
    expect(connection.call.type, 'video');
    expect(connection.call.status, CallStatus.ongoing);
  });
}
