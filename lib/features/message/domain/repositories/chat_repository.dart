import 'package:lovesync_mobile/features/e2ee/domain/entities/e2ee_message_encryption.dart';
import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Future<ChatTimelinePage> getTimelinePage(
    String currentUserId, {
    String? cursor,
    int limit = 20,
  });
  Future<void> sendMessage({
    String? message,
    E2eeMessageEncryption? encryption,
    List<String> attachments = const [],
    List<String> attachmentUrls = const [],
  });
}
