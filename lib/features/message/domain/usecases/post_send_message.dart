import 'package:lovesync_mobile/features/e2ee/domain/entities/e2ee_message_encryption.dart';
import 'package:lovesync_mobile/features/message/domain/repositories/chat_repository.dart';

class PostSendMessage {
  const PostSendMessage(this.repository);

  final ChatRepository repository;

  Future<void> call({
    String? message,
    E2eeMessageEncryption? encryption,
    List<String> attachments = const [],
    List<String> attachmentUrls = const [],
  }) async {
    return await repository.sendMessage(
      message: message,
      encryption: encryption,
      attachments: attachments,
      attachmentUrls: attachmentUrls,
    );
  }
}
