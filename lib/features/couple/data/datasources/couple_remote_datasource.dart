import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_code_modal.dart';

class CoupleRemoteDatasource {
  final Dio dio;
  CoupleRemoteDatasource(this.dio);

  Future<CoupleCodeModal> getMyCoupleCode() async {
    try {
      final response = await dio.get('/couple/code');
      return CoupleCodeModal.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load couple code: $e');
    }
  }
}
