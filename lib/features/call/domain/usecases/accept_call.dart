import 'package:lovesync_mobile/features/call/domain/entities/call_session.dart';
import 'package:lovesync_mobile/features/call/domain/repositories/call_repository.dart';

class AcceptCall {
  const AcceptCall(this.repository);

  final CallRepository repository;

  Future<CallConnection> call(String callId) => repository.accept(callId);
}
