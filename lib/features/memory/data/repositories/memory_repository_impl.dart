import 'package:lovesync_mobile/features/memory/data/datasources/memory_remote_datasource.dart';
import 'package:lovesync_mobile/features/memory/domain/entities/memory_response.dart';
import 'package:lovesync_mobile/features/memory/domain/repositories/memory_repository.dart';

class MemoryRepositoryImpl extends MemoryRepository {
  final MemoryRemoteDatasource memoryRemoteDatasource;
  MemoryRepositoryImpl(this.memoryRemoteDatasource);

  @override
  Future<List<MemoryResponse>> getAllMemories() async {
    final memoryResponseModals = await memoryRemoteDatasource.getAllMemories();
    final memoryResponses = memoryResponseModals
        .map(
          (memoryResponseModal) => MemoryResponse(
            id: memoryResponseModal.id,
            fileUrl: memoryResponseModal.fileUrl,
            description: memoryResponseModal.description,
            time: memoryResponseModal.time,
          ),
        )
        .toList();
    return memoryResponses;
  }

  @override
  Future<void> createMemory({
    required String fileUrl,
    required String description,
    required DateTime time,
  }) async {
    return await memoryRemoteDatasource.createMemory(
      fileUrl: fileUrl,
      description: description,
      time: time,
    );
  }

  @override
  Future<void> deleteMemory({required String memoryId}) async {
    return await memoryRemoteDatasource.deleteMemory(memoryId);
  }
}
