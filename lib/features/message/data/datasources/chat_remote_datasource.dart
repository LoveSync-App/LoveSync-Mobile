import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/message/data/models/chat_message_model.dart';
import 'package:lovesync_mobile/features/message/data/models/partner_presence_model.dart';

class ChatRemoteDatasource {
  const ChatRemoteDatasource(this.dio);

  final Dio dio;

  Future<ChatPageModel> getTimelinePage({
    String? cursor,
    int limit = 20,
  }) async {
    final response = await dio.get(
      '/chat',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return ChatPageModel.fromJson(response.data);
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

  Future<PartnerPresenceModel> getPartnerPresence() async {
    final response = await dio.get('/presence/partner');
    return PartnerPresenceModel.fromData(response.data);
  }
}
