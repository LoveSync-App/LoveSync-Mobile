import 'package:lovesync_mobile/features/couple/domain/entities/couple_day.dart';
import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class UpdateCoupleStartDate {
  const UpdateCoupleStartDate(this.repository);

  final CoupleRepository repository;

  Future<CoupleDay> call(DateTime startDate) {
    return repository.updateStartDate(startDate);
  }
}
