import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> getRecentMessages(String currentUserId);
  Future<void> sendMessage(String message);
}
