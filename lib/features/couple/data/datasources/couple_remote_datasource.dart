import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_code_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_day_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/partner_modal.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/couple.dart';

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

  Future<CoupleModal> getMyCouple() async {
    try {
      final response = await dio.get('/couples/me');
      return CoupleModal.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to load couple: $e');
    }
  }

  Future<CoupleDayModal> getCoupleDays() async {
    try {
      final response = await dio.get('/couples/me/love-days');
      return CoupleDayModal.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to load couple days: $e');
    }
  }
}
