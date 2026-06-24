import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/memory/data/models/memory_response_model.dart';

class MemoryRemoteDatasource {
  final Dio dio;
  MemoryRemoteDatasource(this.dio);

  Future<List<MemoryResponseModel>> getAllMemories() async {
    final response = await dio.get('/memories');
    List<MemoryResponseModel> memories = (response.data['data'] as List)
        .map((memory) => MemoryResponseModel.fromJson(memory))
        .toList();
    return memories;
  }

  Future<void> createMemory({
    required String fileUrl,
    required String title,
    required String description,
    required String emotion,
    required DateTime time,
  }) async {
    await dio.post(
      '/memories',
      data: {
        'file_url': fileUrl,
        'title': title,
        'description': description,
        'emotion': emotion,
        // 'time': time.toIso8601String(),
      },
    );
  }
}
