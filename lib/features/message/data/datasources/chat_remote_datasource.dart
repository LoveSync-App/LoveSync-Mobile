import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/message/data/models/chat_message_model.dart';

class ChatRemoteDatasource {
  const ChatRemoteDatasource(this.dio);

  final Dio dio;

  Future<List<ChatMessageModel>> getRecentMessages() async {
    final response = await dio.get('/chat');
    final responseData = response.data;
    final rawMessages = responseData is Map<String, dynamic>
        ? responseData['data']
        : responseData;

    if (rawMessages is! List) return [];

    return rawMessages
        .map((message) => ChatMessageModel.fromSocket(message))
        .toList();
  }

  Future<void> sendMessage({
    String? message,
    List<String> attachments = const [],
    List<String> attachmentUrls = const [],
  }) async {
    await dio.post(
      '/chat/send-message',
      data: {
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        if (attachments.isNotEmpty) 'attachments': attachments,
        if (attachmentUrls.isNotEmpty) 'attachmentUrls': attachmentUrls,
      },
    );
  }
}
