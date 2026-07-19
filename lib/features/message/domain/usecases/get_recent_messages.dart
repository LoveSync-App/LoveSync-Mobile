import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';
import 'package:lovesync_mobile/features/message/domain/repositories/chat_repository.dart';

class GetRecentMessages {
  const GetRecentMessages(this.repository);

  final ChatRepository repository;

  Future<ChatTimelinePage> call(
    String currentUserId, {
    String? cursor,
    int limit = 20,
  }) async {
    return await repository.getTimelinePage(
      currentUserId,
      cursor: cursor,
      limit: limit,
    );
  }
}
