import 'package:lovesync_mobile/features/couple/domain/entities/invitation.dart';
import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

class GetInvitationPending {
  final CoupleRepository repository;

  GetInvitationPending(this.repository);

  Future<List<Invitation>> call() {
    return repository.getInvitationsPending();
  }
}