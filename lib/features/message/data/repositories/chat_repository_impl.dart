import 'package:lovesync_mobile/features/message/data/datasources/chat_remote_datasource.dart';
import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';
import 'package:lovesync_mobile/features/message/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl extends ChatRepository {
  ChatRepositoryImpl(this.chatRemoteDatasource);

  final ChatRemoteDatasource chatRemoteDatasource;

  @override
  Future<List<ChatMessage>> getRecentMessages(String currentUserId) async {
    final messages = await chatRemoteDatasource.getRecentMessages();
    return messages
        .map(
          (message) =>
              message.toEntity(isMine: message.senderId == currentUserId),
        )
        .toList();
  }

  @override
  Future<void> sendMessage({
    String? message,
    List<String> attachments = const [],
    List<String> attachmentUrls = const [],
  }) async {
    return await chatRemoteDatasource.sendMessage(
      message: message,
      attachments: attachments,
      attachmentUrls: attachmentUrls,
    );
  }
}
