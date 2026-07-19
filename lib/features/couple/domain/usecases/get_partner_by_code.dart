import 'package:lovesync_mobile/features/couple/domain/entities/partner.dart';
import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class GetPartnerByCode {
  final CoupleRepository repository;

  GetPartnerByCode(this.repository);

  Future<Partner> call(String code) async {
    return await repository.getPartnerByCode(code);
  }
}
