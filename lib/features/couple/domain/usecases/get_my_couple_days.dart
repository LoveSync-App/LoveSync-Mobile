import 'package:lovesync_mobile/features/couple/domain/entities/couple_day.dart';
import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class GetMyCoupleDays {
  late final CoupleRepository repository;
  GetMyCoupleDays(this.repository);

  Future<CoupleDay> call() async {
    return await repository.getCoupleDays();
  }
}