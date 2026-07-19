import 'package:lovesync_mobile/features/e2ee/domain/entities/e2ee_message_encryption.dart';

enum ChatMessageType { text, image, video, call, location }

class ChatMessage {
  const ChatMessage({
    this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.attachments = const [],
    this.type = ChatMessageType.text,
    this.entityId,
    this.payload = const {},
    this.encryption,
  });

  final String? id;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final List<String> attachments;
  final ChatMessageType type;
  final String? entityId;
  final Map<String, dynamic> payload;
  final E2eeMessageEncryption? encryption;

  ChatMessage copyWith({
    String? text,
    List<String>? attachments,
    E2eeMessageEncryption? encryption,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      sentAt: sentAt,
      isMine: isMine,
      attachments: attachments ?? this.attachments,
      type: type,
      entityId: entityId,
      payload: payload,
      encryption: encryption ?? this.encryption,
    );
  }
}

class ChatTimelinePage {
  const ChatTimelinePage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<ChatMessage> items;
  final bool hasMore;
  final String? nextCursor;
}
