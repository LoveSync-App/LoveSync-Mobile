import 'package:lovesync_mobile/features/memory/domain/entities/memory_response.dart';

abstract class MemoryRepository {
  Future<List<MemoryResponse>> getAllMemories();
  Future<void> createMemory({
    required String fileUrl,
    required String title,
    required String description,
    required String emotion,
    required DateTime time,
  });
}
