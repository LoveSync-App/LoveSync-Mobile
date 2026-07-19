import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class PatchRejectInvitation {
  final CoupleRepository repository;
  PatchRejectInvitation(this.repository);

  Future<void> call(String invitationId) {
    return repository.rejectInvitation(invitationId);
  }
}
