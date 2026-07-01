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
  });

  final String? id;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final List<String> attachments;
  final ChatMessageType type;
  final String? entityId;
  final Map<String, dynamic> payload;
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
