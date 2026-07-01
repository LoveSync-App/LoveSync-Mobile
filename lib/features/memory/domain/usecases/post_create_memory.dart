import 'package:lovesync_mobile/features/memory/domain/repositories/memory_repository.dart';

class PostCreateMemory {
  final MemoryRepository repository;
  PostCreateMemory(this.repository);

  Future<void> call({
    required String fileUrl,
    required String description,
    required DateTime time,
  }) async {
    return await repository.createMemory(
      fileUrl: fileUrl,
      description: description,
      time: time,
    );
  }
}
