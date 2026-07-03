import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:lovesync_mobile/features/call/data/datasources/call_socket_datasource.dart';
import 'package:lovesync_mobile/features/call/domain/entities/call_session.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/accept_call.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/cancel_call.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/end_call.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/get_active_call.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/issue_call_token.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/reject_call.dart';
import 'package:lovesync_mobile/features/call/domain/usecases/start_call.dart';

enum CallPhase { idle, starting, incoming, outgoing, ongoing, ending }

class CallProvider extends ChangeNotifier with WidgetsBindingObserver {
  CallProvider({
    required StartCall startCall,
    required AcceptCall acceptCall,
    required RejectCall rejectCall,
    required CancelCall cancelCall,
    required EndCall endCall,
    required GetActiveCall getActiveCall,
    required IssueCallToken issueCallToken,
    this.onSessionRevoked,
  }) : _startCallUsecase = startCall,
       _acceptCall = acceptCall,
       _rejectCall = rejectCall,
       _cancelCall = cancelCall,
       _endCall = endCall,
       _getActiveCall = getActiveCall,
       _issueCallToken = issueCallToken {
    WidgetsBinding.instance.addObserver(this);
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handlePushMessage,
    );
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handlePushMessage,
    );
    unawaited(_readInitialMessage());
  }

  final StartCall _startCallUsecase;
  final AcceptCall _acceptCall;
  final RejectCall _rejectCall;
  final CancelCall _cancelCall;
  final EndCall _endCall;
  final GetActiveCall _getActiveCall;
  final IssueCallToken _issueCallToken;
  final Future<void> Function(String message)? onSessionRevoked;

  String _token = '';
  String _userId = '';
  String _partnerName = '';
  String _partnerAvatar = '';
  CallPhase _phase = CallPhase.idle;
  CallSession? _activeCall;
  LiveKitCredentials? _credentials;
  String? _errorMessage;
  bool _isSocketConnected = false;

  CallSocketDatasource? _socketDatasource;
  StreamSubscription<CallSignalEvent>? _signalSubscription;
  StreamSubscription<bool>? _socketConnectionSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;

  CallPhase get phase => _phase;
  CallSession? get activeCall => _activeCall;
  LiveKitCredentials? get credentials => _credentials;
  String get partnerName => _partnerName;
  String get partnerAvatar => _partnerAvatar;
  String? get errorMessage => _errorMessage;
  bool get isSocketConnected => _isSocketConnected;
  bool get isVisible => _phase != CallPhase.idle;
  bool get isIncoming => _phase == CallPhase.incoming;

  void updateAuth({required String token, required String userId}) {
    if (_token == token && _userId == userId) return;
    _token = token;
    _userId = userId;

    if (token.isEmpty) {
      _disconnectSocket();
      _reset();
      return;
    }

    _connectSocket();
    unawaited(refreshActiveCall());
  }

  Future<void> startAudioCall({
    required String partnerName,
    required String partnerAvatar,
  }) {
    return _startCall(
      partnerName: partnerName,
      partnerAvatar: partnerAvatar,
      isVideo: false,
    );
  }

  Future<void> startVideoCall({
    required String partnerName,
    required String partnerAvatar,
  }) {
    return _startCall(
      partnerName: partnerName,
      partnerAvatar: partnerAvatar,
      isVideo: true,
    );
  }

  Future<void> _startCall({
    required String partnerName,
    required String partnerAvatar,
    required bool isVideo,
  }) async {
    if (_phase != CallPhase.idle) return;
    _partnerName = partnerName;
    _partnerAvatar = partnerAvatar;
    _errorMessage = null;
    _phase = CallPhase.starting;
    notifyListeners();

    try {
      final response = await _startCallUsecase(isVideo: isVideo);
      _applyConnection(response);
      _phase = CallPhase.outgoing;
      notifyListeners();
    } catch (error) {
      _reset();
      rethrow;
    }
  }

  Future<void> acceptIncomingCall() async {
    final call = _activeCall;
    if (call == null || _phase != CallPhase.incoming) return;
    _errorMessage = null;
    try {
      final response = await _acceptCall(call.id);
      _applyConnection(response);
      _phase = CallPhase.ongoing;
      notifyListeners();
    } catch (error) {
      _errorMessage = _messageFor(error, 'Không thể nhận cuộc gọi.');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rejectIncomingCall() async {
    final call = _activeCall;
    if (call == null) return;
    _phase = CallPhase.ending;
    notifyListeners();
    try {
      await _rejectCall(call.id);
    } finally {
      _reset();
    }
  }

  Future<void> hangUp() async {
    final call = _activeCall;
    if (call == null) {
      _reset();
      return;
    }

    final previousPhase = _phase;
    _phase = CallPhase.ending;
    notifyListeners();
    try {
      if (previousPhase == CallPhase.outgoing ||
          call.status == CallStatus.ringing) {
        await _cancelCall(call.id);
      } else {
        await _endCall(call.id);
      }
    } finally {
      _reset();
    }
  }

  Future<void> refreshActiveCall() async {
    if (_token.isEmpty) return;
    try {
      final activeConnection = await _getActiveCall();
      if (activeConnection == null) {
        if (_activeCall != null) _reset();
        return;
      }

      var connection = activeConnection;
      final call = connection.call;
      final canRequestToken =
          call.status == CallStatus.ongoing ||
          (call.status == CallStatus.ringing && call.isCaller(_userId));
      if (connection.liveKit == null && canRequestToken) {
        connection = await _issueCallToken(call.id);
      }
      _applyConnection(connection);
      _derivePhase(_activeCall!);
      notifyListeners();
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        _errorMessage = _messageFor(
          error,
          'Không thể đồng bộ trạng thái cuộc gọi.',
        );
        notifyListeners();
      }
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _token.isNotEmpty) {
      unawaited(refreshActiveCall());
    }
  }

  void _connectSocket() {
    _disconnectSocket();
    final datasource = CallSocketDatasource(token: _token);
    _socketDatasource = datasource;
    _signalSubscription = datasource.events.listen(_handleSignal);
    _socketConnectionSubscription = datasource.connectionChanges.listen((
      connected,
    ) {
      _isSocketConnected = connected;
      notifyListeners();
      if (connected) unawaited(refreshActiveCall());
    });
    datasource.connect();
  }

  void _disconnectSocket() {
    unawaited(_signalSubscription?.cancel());
    unawaited(_socketConnectionSubscription?.cancel());
    _signalSubscription = null;
    _socketConnectionSubscription = null;
    unawaited(_socketDatasource?.dispose());
    _socketDatasource = null;
    _isSocketConnected = false;
  }

  void _handleSignal(CallSignalEvent event) {
    if (event.name == 'auth:session-revoked') {
      _disconnectSocket();
      _reset();
      unawaited(
        onSessionRevoked?.call(
              'Tài khoản đã được đăng nhập trên một thiết bị khác.',
            ) ??
            Future<void>.value(),
      );
      return;
    }

    final terminalEvents = {
      'call:rejected',
      'call:canceled',
      'call:missed',
      'call:ended',
    };
    if (terminalEvents.contains(event.name)) {
      final eventCallId = event.connection?.call.id;
      if (eventCallId == null ||
          eventCallId.isEmpty ||
          eventCallId == _activeCall?.id) {
        _reset();
      }
      return;
    }

    if (event.name == 'calls:error') {
      _errorMessage = 'Kết nối tín hiệu cuộc gọi gặp lỗi.';
      notifyListeners();
      return;
    }

    if (event.name == 'call:media-updated') {
      return;
    }

    final connection = event.connection?.toEntity();
    if (connection == null) {
      unawaited(refreshActiveCall());
      return;
    }

    _applyConnection(connection);
    if (event.name == 'call:incoming') {
      _phase = connection.call.isCaller(_userId)
          ? CallPhase.outgoing
          : CallPhase.incoming;
    } else if (event.name == 'call:accepted') {
      _phase = CallPhase.ongoing;
    } else {
      _derivePhase(_activeCall!);
    }
    notifyListeners();
  }

  void _applyConnection(CallConnection connection) {
    final previous = _activeCall;
    final incoming = connection.call;
    if (previous != null &&
        (incoming.id.isEmpty || incoming.id == previous.id)) {
      _activeCall = CallSession(
        id: incoming.id.isEmpty ? previous.id : incoming.id,
        callerId: incoming.callerId.isEmpty
            ? previous.callerId
            : incoming.callerId,
        calleeId: incoming.calleeId.isEmpty
            ? previous.calleeId
            : incoming.calleeId,
        roomName: incoming.roomName.isEmpty
            ? previous.roomName
            : incoming.roomName,
        type: incoming.type.isEmpty ? previous.type : incoming.type,
        status: incoming.status == CallStatus.unknown
            ? previous.status
            : incoming.status,
      );
    } else {
      _activeCall = incoming;
    }
    if (connection.liveKit != null) _credentials = connection.liveKit;
  }

  void _derivePhase(CallSession call) {
    _phase = switch (call.status) {
      CallStatus.ringing =>
        call.isCaller(_userId) ? CallPhase.outgoing : CallPhase.incoming,
      CallStatus.ongoing => CallPhase.ongoing,
      _ => CallPhase.idle,
    };
  }

  Future<void> _readInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _handlePushMessage(message);
  }

  void _handlePushMessage(RemoteMessage message) {
    final type = message.data['type']?.toString();
    if (type == 'incoming_call') {
      unawaited(refreshActiveCall());
    }
  }

  String _messageFor(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message != null && message.toString().isNotEmpty) {
          return message.toString();
        }
      }
    }
    return fallback;
  }

  void _reset() {
    _activeCall = null;
    _credentials = null;
    _phase = CallPhase.idle;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectSocket();
    unawaited(_foregroundMessageSubscription?.cancel());
    unawaited(_openedMessageSubscription?.cancel());
    super.dispose();
  }
}
