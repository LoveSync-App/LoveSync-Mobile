import 'dart:async';

import 'package:lovesync_mobile/core/constants/api_constants.dart';
import 'package:lovesync_mobile/features/message/data/models/chat_message_model.dart';
import 'package:lovesync_mobile/features/message/data/models/partner_presence_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketEvent {
  const ChatSocketEvent({required this.message, required this.isUpdate});

  final ChatMessageModel message;
  final bool isUpdate;
}

class ChatSocketDatasource {
  ChatSocketDatasource({required this.token});

  static const String _newMessageEvent = 'message:new';
  static const String _updatedMessageEvent = 'message:updated';

  final String token;
  final StreamController<ChatSocketEvent> _messageController =
      StreamController<ChatSocketEvent>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<PartnerPresenceModel> _presenceController =
      StreamController<PartnerPresenceModel>.broadcast();

  io.Socket? _socket;

  Stream<ChatSocketEvent> get messages => _messageController.stream;
  Stream<bool> get connectionChanges => _connectionController.stream;
  Stream<PartnerPresenceModel> get partnerPresence =>
      _presenceController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    disconnect();

    _socket = io.io(
      '${ApiConstants.socketOrigin}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket?.on(
      _newMessageEvent,
      (data) => _handleMessage(data, isUpdate: false),
    );
    _socket?.on(
      _updatedMessageEvent,
      (data) => _handleMessage(data, isUpdate: true),
    );
    _socket?.on('chat:error', (_) => _setConnected(false));
    _socket?.on(
      'presence:partner-updated',
      (data) => _emitPartnerPresence(data),
    );
    _socket?.on('chat:ready', (data) => _emitPartnerPresence(data));
    _socket?.onConnect((_) => _setConnected(true));
    _socket?.onDisconnect((_) => _setConnected(false));
    _socket?.onConnectError((_) => _setConnected(false));
    _socket?.onError((_) => _setConnected(false));
    _socket?.connect();
  }

  void disconnect() {
    final socket = _socket;
    if (socket == null) return;

    socket.off(_newMessageEvent);
    socket.off(_updatedMessageEvent);
    socket.off('chat:error');
    socket.off('presence:partner-updated');
    socket.off('chat:ready');

    socket.dispose();
    _socket = null;
    _setConnected(false);
  }

  Future<void> dispose() async {
    disconnect();
    await _messageController.close();
    await _connectionController.close();
    await _presenceController.close();
  }

  void _handleMessage(dynamic data, {required bool isUpdate}) {
    if (_messageController.isClosed) return;
    _messageController.add(
      ChatSocketEvent(
        message: ChatMessageModel.fromSocket(data),
        isUpdate: isUpdate,
      ),
    );
  }

  void _setConnected(bool value) {
    if (_connectionController.isClosed) return;
    _connectionController.add(value);
  }

  void _emitPartnerPresence(dynamic data) {
    if (_presenceController.isClosed) return;
    _presenceController.add(PartnerPresenceModel.fromData(data));
  }
}
