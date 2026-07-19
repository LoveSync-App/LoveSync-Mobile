import 'package:lovesync_mobile/features/couple/domain/entities/couple.dart';
import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class GetMyCouple {
  late final CoupleRepository repository;
  GetMyCouple(this.repository);
  Future<Couple> call() async {
    return await repository.getMyCouple();
  }
}