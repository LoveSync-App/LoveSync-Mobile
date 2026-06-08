import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_code_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/partner_modal.dart';

class CoupleRemoteDatasource {
  final Dio dio;
  CoupleRemoteDatasource(this.dio);

  Future<CoupleCodeModal> getMyCoupleCode() async {
    try {
      final response = await dio.get('/couples/code/me');
      return CoupleCodeModal.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to load couple code: $e');
    }
  }

  Future<PartnerModal> getPartnerByCode(String code) async {
    try {
      final response = await dio.get('/couples/code/$code');
      return PartnerModal.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to load partner: $e');
    }
  }
}
