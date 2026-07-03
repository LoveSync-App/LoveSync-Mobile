import 'package:lovesync_mobile/features/call/domain/repositories/call_repository.dart';

class CancelCall {
  const CancelCall(this.repository);

  final CallRepository repository;

  Future<void> call(String callId) => repository.cancel(callId);
}
