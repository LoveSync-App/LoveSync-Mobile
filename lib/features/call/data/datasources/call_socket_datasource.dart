import 'dart:async';

import 'package:lovesync_mobile/core/constants/api_constants.dart';
import 'package:lovesync_mobile/features/call/data/models/call_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class CallSignalEvent {
  const CallSignalEvent({required this.name, this.connection});

  final String name;
  final CallConnectionModel? connection;
}

class CallSocketDatasource {
  CallSocketDatasource({required this.token});

  static const _eventNames = <String>[
    'call:incoming',
    'call:ringing',
    'call:accepted',
    'call:rejected',
    'call:canceled',
    'call:missed',
    'call:ended',
    'call:media-updated',
    'calls:ready',
    'calls:error',
  ];

  final String token;
  final _events = StreamController<CallSignalEvent>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  io.Socket? _socket;

  Stream<CallSignalEvent> get events => _events.stream;
  Stream<bool> get connectionChanges => _connections.stream;

  void connect() {
    disconnect();
    _socket = io.io(
      '${ApiConstants.socketOrigin}/calls',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    for (final name in _eventNames) {
      _socket?.on(name, (data) => _emit(name, data));
    }
    _socket?.onConnect((_) => _setConnected(true));
    _socket?.onDisconnect((_) => _setConnected(false));
    _socket?.onConnectError((_) => _setConnected(false));
    _socket?.onError((_) => _setConnected(false));
    _socket?.connect();
  }

  void disconnect() {
    final socket = _socket;
    if (socket == null) return;
    for (final name in _eventNames) {
      socket.off(name);
    }
    socket.dispose();
    _socket = null;
    _setConnected(false);
  }

  Future<void> dispose() async {
    disconnect();
    await _events.close();
    await _connections.close();
  }

  void _emit(String name, dynamic data) {
    if (_events.isClosed) return;
    CallConnectionModel? connection;
    try {
      connection = CallConnectionModel.fromJson(data);
      if (connection.call.id.isEmpty) connection = null;
    } catch (_) {
      connection = null;
    }
    _events.add(CallSignalEvent(name: name, connection: connection));
  }

  void _setConnected(bool connected) {
    if (!_connections.isClosed) _connections.add(connected);
  }
}
