import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/message/data/datasources/chat_remote_datasource.dart';
import 'package:lovesync_mobile/features/message/data/datasources/chat_socket_datasource.dart';
import 'package:lovesync_mobile/features/message/data/models/chat_message_model.dart';
import 'package:lovesync_mobile/features/message/data/repositories/chat_repository_impl.dart';
import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';
import 'package:lovesync_mobile/features/message/domain/usecases/get_recent_messages.dart';
import 'package:lovesync_mobile/features/message/domain/usecases/post_send_message.dart';
import 'package:lovesync_mobile/features/message/presentation/widgets/message_bubble.dart';
import 'package:lovesync_mobile/features/message/presentation/widgets/message_composer.dart';
import 'package:lovesync_mobile/features/message/presentation/widgets/partner_chat_header.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RealtimeMessagePage extends StatefulWidget {
  const RealtimeMessagePage({super.key});

  @override
  State<RealtimeMessagePage> createState() => _RealtimeMessagePageState();
}

class _RealtimeMessagePageState extends State<RealtimeMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final PostSendMessage _postSendMessage;
  late final GetRecentMessages _getRecentMessages;
  ChatSocketDatasource? _chatSocketDatasource;
  StreamSubscription<ChatMessageModel>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  final List<ChatMessage> _messages = [];
  final Set<String> _messageIds = {};
  final Map<String, DateTime> _recentlySentMessages = {};

  String _currentUserId = '';
  bool _isLoadingMessages = true;
  bool _isSending = false;
  bool _isSocketConnected = false;

  @override
  void initState() {
    super.initState();

    final chatRepository = ChatRepositoryImpl(
      ChatRemoteDatasource(context.read<DioClient>().dio),
    );
    _postSendMessage = PostSendMessage(chatRepository);
    _getRecentMessages = GetRecentMessages(chatRepository);

    _currentUserId = context.read<AuthProvider>().userId;
    _loadRecentMessages();
    _connectSocket();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _chatSocketDatasource?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectSocket() {
    final token = context.read<AuthProvider>().accessToken;
    if (token.isEmpty) return;

    final datasource = ChatSocketDatasource(token: token);
    _chatSocketDatasource = datasource;

    _messageSubscription = datasource.messages.listen(_handleIncomingMessage);
    _connectionSubscription = datasource.connectionChanges.listen((connected) {
      if (!mounted) return;
      setState(() => _isSocketConnected = connected);
    });

    datasource.connect();
  }

  Future<void> _loadRecentMessages() async {
    if (_currentUserId.isEmpty) {
      setState(() => _isLoadingMessages = false);
      return;
    }

    try {
      final messages = await _getRecentMessages(_currentUserId);
      if (!mounted) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _messageIds
          ..clear()
          ..addAll(messages.map((message) => message.id).whereType<String>());
        _isLoadingMessages = false;
      });
      _scrollToBottom();
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMessages = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tải được tin nhắn gần đây.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(
        ChatMessage(text: text, sentAt: DateTime.now(), isMine: true),
      );
      _recentlySentMessages[text] = DateTime.now();
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      await _postSendMessage(text);
    } on DioException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không gửi được tin nhắn. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _handleIncomingMessage(ChatMessageModel message) {
    if (message.text.isEmpty || _isDuplicateMessage(message)) return;

    final isMine = message.senderId == _currentUserId;
    if (isMine && _isEchoFromRecentSend(message.text)) return;

    setState(() {
      final messageId = message.id;
      if (messageId != null) {
        _messageIds.add(messageId);
      }
      _messages.add(message.toEntity(isMine: isMine));
    });
    _scrollToBottom();
  }

  bool _isDuplicateMessage(ChatMessageModel message) {
    final messageId = message.id;
    return messageId != null && _messageIds.contains(messageId);
  }

  bool _isEchoFromRecentSend(String text) {
    final sentAt = _recentlySentMessages[text];
    if (sentAt == null) return false;

    final isRecent = DateTime.now().difference(sentAt).inSeconds <= 8;
    if (!isRecent) {
      _recentlySentMessages.remove(text);
    }
    return isRecent;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9),
      body: SafeArea(
        child: Column(
          children: [
            PartnerChatHeader(isConnected: _isSocketConnected),
            Expanded(
              child: _isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                  ? const _EmptyChatPlaceholder()
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                      itemCount: _messages.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final showAvatar =
                            !message.isMine &&
                            (index == _messages.length - 1 ||
                                _messages[index + 1].isMine);

                        return MessageBubble(
                          message: message,
                          showPartnerAvatar: showAvatar,
                        );
                      },
                    ),
            ),
            MessageComposer(
              controller: _messageController,
              onSend: _sendMessage,
              isSending: _isSending,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatPlaceholder extends StatelessWidget {
  const _EmptyChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Hãy gửi tin nhắn đầu tiên cho người ấy.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF8A8F96)),
        ),
      ),
    );
  }
}
