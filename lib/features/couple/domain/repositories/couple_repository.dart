import 'package:lovesync_mobile/features/couple/domain/entities/couple.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/couple_code.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/couple_day.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/partner.dart';

abstract class CoupleRepository {
  Future<CoupleCode> getMyCoupleCode();
  Future<Partner> getPartnerByCode(String code);
  Future<Couple> getMyCouple();
  Future<CoupleDay> getCoupleDays();
}