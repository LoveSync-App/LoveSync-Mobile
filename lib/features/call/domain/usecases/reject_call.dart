import 'package:lovesync_mobile/features/call/domain/repositories/call_repository.dart';

class RejectCall {
  const RejectCall(this.repository);

  final CallRepository repository;

  Future<void> call(String callId) => repository.reject(callId);
}
