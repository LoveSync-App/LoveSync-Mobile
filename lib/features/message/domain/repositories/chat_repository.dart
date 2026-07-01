import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Future<ChatTimelinePage> getTimelinePage(
    String currentUserId, {
    String? cursor,
    int limit = 20,
  });
  Future<void> sendMessage({
    String? message,
    List<String> attachments = const [],
    List<String> attachmentUrls = const [],
  });
}
