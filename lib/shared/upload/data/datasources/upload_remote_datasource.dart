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
}
