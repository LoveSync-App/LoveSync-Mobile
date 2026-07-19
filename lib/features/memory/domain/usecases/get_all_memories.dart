import 'package:lovesync_mobile/features/memory/domain/entities/memory_response.dart';
import 'package:lovesync_mobile/features/memory/domain/repositories/memory_repository.dart';

class GetAllMemories {
  final MemoryRepository repository;
  GetAllMemories(this.repository);

  Future<List<MemoryResponse>> call() async {
    return await repository.getAllMemories();
  }
}
