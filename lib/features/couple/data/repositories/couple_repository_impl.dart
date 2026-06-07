import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_code_modal.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/couple_code.dart';
import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class CoupleRepositoryImpl implements CoupleRepository {
  final CoupleRemoteDatasource remoteDatasource;

  CoupleRepositoryImpl(this.remoteDatasource);

  @override
  Future<CoupleCode> getMyCoupleCode() async {
    CoupleCodeModal result = await remoteDatasource.getMyCoupleCode();
    return CoupleCode(code: result.code);
  }
}
