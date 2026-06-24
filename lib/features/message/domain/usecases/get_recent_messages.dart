import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';
import 'package:lovesync_mobile/features/message/domain/repositories/chat_repository.dart';

class GetRecentMessages {
  const GetRecentMessages(this.repository);

  final ChatRepository repository;

  Future<List<ChatMessage>> call(String currentUserId) async {
    return await repository.getRecentMessages(currentUserId);
  }
}
