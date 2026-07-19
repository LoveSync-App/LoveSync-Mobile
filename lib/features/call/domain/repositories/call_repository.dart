import 'package:lovesync_mobile/features/call/domain/entities/call_session.dart';

abstract class CallRepository {
  Future<CallConnection> createAudioCall();

  Future<CallConnection> createVideoCall();

  Future<CallConnection?> getActiveCall();

  Future<CallConnection> getCall(String callId);

  Future<CallConnection> accept(String callId);

  Future<void> reject(String callId);

  Future<void> cancel(String callId);

  Future<void> end(String callId);

  Future<CallConnection> issueToken(String callId);
}
