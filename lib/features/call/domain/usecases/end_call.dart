import 'package:lovesync_mobile/features/call/domain/repositories/call_repository.dart';

class EndCall {
  const EndCall(this.repository);

  final CallRepository repository;

  Future<void> call(String callId) => repository.end(callId);
}
