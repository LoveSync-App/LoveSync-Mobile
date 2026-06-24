import 'package:lovesync_mobile/features/memory/domain/repositories/memory_repository.dart';

class PostCreateMemory {
  final MemoryRepository repository;
  PostCreateMemory(this.repository);

  Future<void> call(
    String fileUrl,
    String title,
    String description,
    String emotion,
    DateTime time,
  ) async {
    return await repository.createMemory(
      fileUrl: fileUrl,
      title: title,
      description: description,
      emotion: emotion,
      time: time,
    );
  }
}
