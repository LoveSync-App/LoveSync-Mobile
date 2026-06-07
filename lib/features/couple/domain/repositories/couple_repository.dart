import 'package:lovesync_mobile/features/couple/domain/entities/couple_code.dart';

abstract class CoupleRepository {
  Future<CoupleCode> getMyCoupleCode();
}