import 'package:lovesync_mobile/features/call/domain/entities/call_session.dart';
import 'package:lovesync_mobile/features/call/domain/repositories/call_repository.dart';

class StartCall {
  const StartCall(this.repository);

  final CallRepository repository;

  Future<CallConnection> call({required bool isVideo}) {
    return isVideo
        ? repository.createVideoCall()
        : repository.createAudioCall();
  }
}
