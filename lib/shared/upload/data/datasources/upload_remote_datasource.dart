import 'package:dio/dio.dart';

class UploadRemoteDatasource {
  final Dio dio;
  UploadRemoteDatasource(this.dio);

  Future<String> uploadFile(String filePath) async {
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    var response = await dio.post('/upload/image', data: formData);
    return response.data['data']['url'] as String;
  }

  Future<String> uploadAttachmentFile(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await dio.post('/upload/file', data: formData);
    return response.data['data']['url'] as String;
  }
}
