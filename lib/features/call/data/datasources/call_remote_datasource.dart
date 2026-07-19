import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/call/data/models/call_model.dart';

class CallRemoteDatasource {
  const CallRemoteDatasource(this.dio);

  final Dio dio;

  Future<CallConnectionModel> createAudioCall() async {
    final response = await dio.post('/calls', data: {'type': 'audio'});
    return CallConnectionModel.fromJson(response.data);
  }

  Future<CallConnectionModel> createVideoCall() async {
    final response = await dio.post('/calls/video');
    return CallConnectionModel.fromJson(response.data);
  }

  Future<CallConnectionModel?> getActiveCall() async {
    try {
      final response = await dio.get('/calls/active');
      if (response.data == null) return null;
      final model = CallConnectionModel.fromJson(response.data);
      return model.call.id.isEmpty ? null : model;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<CallConnectionModel> getCall(String callId) async {
    final response = await dio.get('/calls/$callId');
    return CallConnectionModel.fromJson(response.data);
  }

  Future<CallConnectionModel> accept(String callId) async {
    final response = await dio.post('/calls/$callId/accept');
    return CallConnectionModel.fromJson(response.data);
  }

  Future<void> reject(String callId) async {
    await dio.post('/calls/$callId/reject');
  }

  Future<void> cancel(String callId) async {
    await dio.post('/calls/$callId/cancel');
  }

  Future<void> end(String callId) async {
    await dio.post('/calls/$callId/end');
  }

  Future<CallConnectionModel> issueToken(String callId) async {
    final response = await dio.post('/calls/$callId/token');
    return CallConnectionModel.fromJson(response.data);
  }
}
