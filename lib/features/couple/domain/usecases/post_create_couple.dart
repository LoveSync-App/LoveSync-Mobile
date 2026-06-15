import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class PostCreateCouple {
  final CoupleRepository repository;

  PostCreateCouple(this.repository);

  Future<void> call(String code) async {
    await repository.createCouple(code);
  }
}
