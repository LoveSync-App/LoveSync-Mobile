import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_code_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/partner_modal.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/couple_code.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/partner.dart';
import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class CoupleRepositoryImpl implements CoupleRepository {
  final CoupleRemoteDatasource remoteDatasource;

  CoupleRepositoryImpl(this.remoteDatasource);

  @override
  Future<CoupleCode> getMyCoupleCode() async {
    CoupleCodeModal result = await remoteDatasource.getMyCoupleCode();
    return CoupleCode(userId: result.userId, code: result.code);
  }

  @override
  Future<Partner> getPartnerByCode(String code) async {
    PartnerModal result = await remoteDatasource.getPartnerByCode(code);
    return Partner(
      id: result.partnerId,
      name: result.partnerName,
      avatar: result.partnerAvatar,
      email: result.partnerEmail,
      phone: result.partnerPhone,
    );
  }
}
