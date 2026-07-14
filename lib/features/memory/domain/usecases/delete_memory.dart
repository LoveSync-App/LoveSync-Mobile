import 'package:lovesync_mobile/features/memory/domain/repositories/memory_repository.dart';

class DeleteMemory {
  final MemoryRepository repository;
  DeleteMemory(this.repository);

  Future<void> call({required String memoryId}) async {
    return await repository.deleteMemory(memoryId: memoryId);
  }
}
