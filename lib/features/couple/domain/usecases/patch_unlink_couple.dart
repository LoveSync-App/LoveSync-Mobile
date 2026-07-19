import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class PatchUnlinkCouple {
  const PatchUnlinkCouple(this._repository);

  final CoupleRepository _repository;

  Future<void> call() => _repository.unlinkCouple();
}
