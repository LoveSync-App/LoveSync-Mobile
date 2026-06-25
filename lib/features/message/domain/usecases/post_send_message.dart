import 'package:lovesync_mobile/features/message/domain/repositories/chat_repository.dart';

class PostSendMessage {
  const PostSendMessage(this.repository);

  final ChatRepository repository;

  Future<void> call({
    String? message,
    List<String> attachments = const [],
    List<String> attachmentUrls = const [],
  }) async {
    return await repository.sendMessage(
      message: message,
      attachments: attachments,
      attachmentUrls: attachmentUrls,
    );
  }
}
