import 'dart:async';

import 'package:lovesync_mobile/features/message/data/models/chat_message_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketDatasource {
  ChatSocketDatasource({required this.token});

  static const String _socketUrl =
      'https://bilateral-misunderstandingly-veola.ngrok-free.dev/chat';
  static const String _newMessageEvent = 'message:new';

  final String token;
  final StreamController<ChatMessageModel> _messageController =
      StreamController<ChatMessageModel>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  io.Socket? _socket;

  Stream<ChatMessageModel> get messages => _messageController.stream;
  Stream<bool> get connectionChanges => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    disconnect();

    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket?.on(_newMessageEvent, _handleMessage);
    _socket?.on('chat:error', (_) => _setConnected(false));
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
    socket.off('chat:error');

    socket.dispose();
    _socket = null;
    _setConnected(false);
  }

  Future<void> dispose() async {
    disconnect();
    await _messageController.close();
    await _connectionController.close();
  }

  void _handleMessage(dynamic data) {
    if (_messageController.isClosed) return;
    _messageController.add(ChatMessageModel.fromSocket(data));
  }

  void _setConnected(bool value) {
    if (_connectionController.isClosed) return;
    _connectionController.add(value);
  }
}
