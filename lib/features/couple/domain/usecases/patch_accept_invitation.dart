import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class PatchAcceptInvitation {
  final CoupleRepository repository;

  PatchAcceptInvitation(this.repository);

  Future<void> call(String invitationId) {
    return repository.acceptInvitation(invitationId);
  }
}