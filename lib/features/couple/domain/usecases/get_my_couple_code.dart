import 'package:lovesync_mobile/features/couple/domain/entities/couple_code.dart';
import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class GetMyCoupleCode {
  final CoupleRepository repository;

  GetMyCoupleCode(this.repository);

  Future<CoupleCode> call() {
    return repository.getMyCoupleCode();
  }
}