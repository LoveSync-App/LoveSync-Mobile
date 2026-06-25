enum ChatMessageType { text, image, video }

class ChatMessage {
  const ChatMessage({
    this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.attachments = const [],
    this.type = ChatMessageType.text,
  });

  final String? id;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final List<String> attachments;
  final ChatMessageType type;
}
