import 'package:flutter_test/flutter_test.dart';
import 'package:lovesync_mobile/features/message/data/models/chat_message_model.dart';
import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';

void main() {
  test('parses encrypted message envelope', () {
    final message = ChatMessageModel.fromJson({
      '_id': 'timeline-3',
      'sender': 'user-1',
      'type': 'TEXT',
      'content': '',
      'encryption': {
        'algorithm': 'RSA-OAEP-256+A256GCM',
        'ciphertext': 'cipher',
        'iv': 'iv',
        'authTag': 'tag',
        'senderEncryptedKey': 'sender-key',
        'recipientEncryptedKey': 'recipient-key',
        'senderKeyVersion': 1,
        'recipientKeyVersion': 2,
      },
      'createdAt': '2026-07-01T10:30:00.000Z',
    });

    expect(message.encryption, isNotNull);
    expect(message.encryption!.senderKeyVersion, 1);
    expect(message.encryption!.recipientKeyVersion, 2);
  });

  test('parses cursor timeline page and call payload', () {
    final page = ChatPageModel.fromJson({
      'items': [
        {
          '_id': 'timeline-1',
          'sender': 'user-1',
          'type': 'CALL',
          'entityId': 'call-1',
          'content': '',
          'payload': {
            'callType': 'audio',
            'status': 'ended',
            'result': 'completed',
            'durationSeconds': 125,
          },
          'attachments': [],
          'createdAt': '2026-07-01T10:30:00.000Z',
        },
      ],
      'pageInfo': {'hasMore': true, 'nextCursor': 'cursor-2'},
    });

    expect(page.hasMore, isTrue);
    expect(page.nextCursor, 'cursor-2');
    expect(page.items, hasLength(1));
    expect(page.items.first.type, ChatMessageType.call);
    expect(page.items.first.entityId, 'call-1');
    expect(page.items.first.payload['result'], 'completed');
  });

  test('parses location payload', () {
    final message = ChatMessageModel.fromJson({
      '_id': 'timeline-2',
      'sender': {'_id': 'user-2'},
      'type': 'LOCATION',
      'payload': {
        'latitude': 10.7769,
        'longitude': 106.7009,
        'address': 'Quận 1, TP.HCM',
      },
      'createdAt': '2026-07-01T10:30:00.000Z',
    });

    expect(message.senderId, 'user-2');
    expect(message.type, ChatMessageType.location);
    expect(message.payload['address'], 'Quận 1, TP.HCM');
  });
}
