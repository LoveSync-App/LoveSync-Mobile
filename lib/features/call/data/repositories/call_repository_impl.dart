import 'package:lovesync_mobile/features/call/data/datasources/call_remote_datasource.dart';
import 'package:lovesync_mobile/features/call/domain/entities/call_session.dart';
import 'package:lovesync_mobile/features/call/domain/repositories/call_repository.dart';

class CallRepositoryImpl implements CallRepository {
  const CallRepositoryImpl(this.remoteDatasource);

  final CallRemoteDatasource remoteDatasource;

  @override
  Future<CallConnection> accept(String callId) async {
    return (await remoteDatasource.accept(callId)).toEntity();
  }

  @override
  Future<void> cancel(String callId) => remoteDatasource.cancel(callId);

  @override
  Future<CallConnection> createAudioCall() async {
    return (await remoteDatasource.createAudioCall()).toEntity();
  }

  @override
  Future<CallConnection> createVideoCall() async {
    return (await remoteDatasource.createVideoCall()).toEntity();
  }

  @override
  Future<void> end(String callId) => remoteDatasource.end(callId);

  @override
  Future<CallConnection?> getActiveCall() async {
    return (await remoteDatasource.getActiveCall())?.toEntity();
  }

  @override
  Future<CallConnection> getCall(String callId) async {
    return (await remoteDatasource.getCall(callId)).toEntity();
  }

  @override
  Future<CallConnection> issueToken(String callId) async {
    return (await remoteDatasource.issueToken(callId)).toEntity();
  }

  @override
  Future<void> reject(String callId) => remoteDatasource.reject(callId);
}
