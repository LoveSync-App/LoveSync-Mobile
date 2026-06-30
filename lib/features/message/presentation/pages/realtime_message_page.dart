import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/call/presentation/providers/call_provider.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_my_couple.dart';
import 'package:lovesync_mobile/features/message/data/datasources/chat_remote_datasource.dart';
import 'package:lovesync_mobile/features/message/data/datasources/chat_socket_datasource.dart';
import 'package:lovesync_mobile/features/message/data/models/chat_message_model.dart';
import 'package:lovesync_mobile/features/message/data/repositories/chat_repository_impl.dart';
import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';
import 'package:lovesync_mobile/features/message/domain/usecases/get_recent_messages.dart';
import 'package:lovesync_mobile/features/message/domain/usecases/post_send_message.dart';
import 'package:lovesync_mobile/features/message/presentation/widgets/empty_chat_placeholder.dart';
import 'package:lovesync_mobile/features/message/presentation/widgets/message_bubble.dart';
import 'package:lovesync_mobile/features/message/presentation/widgets/message_composer.dart';
import 'package:lovesync_mobile/features/message/presentation/widgets/partner_chat_header.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';
import 'package:lovesync_mobile/shared/upload/data/datasources/upload_remote_datasource.dart';
import 'package:lovesync_mobile/shared/upload/data/repositories/upload_repositoty_impl.dart';
import 'package:lovesync_mobile/shared/upload/domain/usecases/upload_file.dart';
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
  late final GetMyCouple _getMyCouple;
  late final UploadFile _uploadFile;
  final ImagePicker _imagePicker = ImagePicker();
  ChatSocketDatasource? _chatSocketDatasource;
  StreamSubscription<ChatMessageModel>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  final List<ChatMessage> _messages = [];
  final List<File> _selectedAttachments = [];
  final Set<String> _messageIds = {};
  final Map<String, DateTime> _recentlySentMessages = {};

  String _currentUserId = '';
  String _partnerName = '';
  String _partnerAvatar = '';
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
    _getMyCouple = GetMyCouple(
      CoupleRepositoryImpl(
        CoupleRemoteDatasource(context.read<DioClient>().dio),
      ),
    );
    _uploadFile = UploadFile(
      UploadRepositotyImpl(
        UploadRemoteDatasource(context.read<DioClient>().dio),
      ),
    );

    _currentUserId = context.read<AuthProvider>().userId;
    _loadCoupleInfo();
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

  Future<void> _loadCoupleInfo() async {
    try {
      final couple = await _getMyCouple();
      if (!mounted) return;

      setState(() {
        _partnerName = couple.partnerName;
        _partnerAvatar = couple.partnerAvatar;
        _currentUserId = couple.userId;
      });
    } on DioException catch (_) {
      // Chat can still work without partner profile details.
    }
  }

  Future<void> _loadRecentMessages() async {
    if (_currentUserId.isEmpty) {
      setState(() => _isLoadingMessages = false);
      return;
    }

    try {
      final messages = await _getRecentMessages(_currentUserId);
      final sortedMessages = List<ChatMessage>.from(messages)
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      if (!mounted) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(sortedMessages);
        _messageIds
          ..clear()
          ..addAll(
            sortedMessages.map((message) => message.id).whereType<String>(),
          );
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

  Future<void> _startAudioCall() async {
    await _startCall(isVideo: false);
  }

  Future<void> _startVideoCall() async {
    await _startCall(isVideo: true);
  }

  Future<void> _startCall({required bool isVideo}) async {
    try {
      final callProvider = context.read<CallProvider>();
      if (isVideo) {
        await callProvider.startVideoCall(
          partnerName: _partnerName,
          partnerAvatar: _partnerAvatar,
        );
      } else {
        await callProvider.startAudioCall(
          partnerName: _partnerName,
          partnerAvatar: _partnerAvatar,
        );
      }
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final message = data is Map
          ? (data['message'] ?? data['error'])?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ??
                (isVideo
                    ? 'Không thể bắt đầu cuộc gọi video.'
                    : 'Không thể bắt đầu cuộc gọi thoại.'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final attachments = List<File>.from(_selectedAttachments);
    if ((text.isEmpty && attachments.isEmpty) || _isSending) return;

    setState(() {
      _isSending = true;
      if (attachments.isEmpty) {
        _messages.add(
          ChatMessage(text: text, sentAt: DateTime.now(), isMine: true),
        );
        _recentlySentMessages[text] = DateTime.now();
      }
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final uploadedUrls = attachments.isEmpty
          ? <String>[]
          : await Future.wait(attachments.map(_uploadFile.call));

      await _postSendMessage(
        message: text.isEmpty ? null : text,
        attachments: uploadedUrls,
      );

      if (mounted) {
        setState(() => _selectedAttachments.clear());
      }
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

  Future<void> _pickFileAttachment() async {
    if (_isSending) return;

    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result == null || !mounted) return;

    final files = result.paths.whereType<String>().map(File.new).toList();
    if (files.isEmpty) return;

    setState(() {
      _selectedAttachments.addAll(files);
    });
  }

  Future<void> _pickImageAttachment() async {
    if (_isSending) return;

    final images = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty || !mounted) return;

    setState(() {
      _selectedAttachments.addAll(images.map((image) => File(image.path)));
    });
  }

  void _removeAttachment(File attachment) {
    if (_isSending) return;
    setState(() => _selectedAttachments.remove(attachment));
  }

  void _handleIncomingMessage(ChatMessageModel message) {
    final hasMessageBody =
        message.text.isNotEmpty || message.attachments.isNotEmpty;
    if (!hasMessageBody || _isDuplicateMessage(message)) return;

    final isMine = message.senderId == _currentUserId;
    if (isMine &&
        message.attachments.isEmpty &&
        _isEchoFromRecentSend(message.text)) {
      return;
    }

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

  List<_ChatTimelineItem> _buildTimelineItems() {
    final items = <_ChatTimelineItem>[];
    DateTime? currentDate;

    for (var index = 0; index < _messages.length; index++) {
      final message = _messages[index];
      final messageDate = DateTime(
        message.sentAt.year,
        message.sentAt.month,
        message.sentAt.day,
      );

      if (currentDate == null || !_isSameDate(currentDate, messageDate)) {
        items.add(_DateDividerTimelineItem(messageDate));
        currentDate = messageDate;
      }

      items.add(_MessageTimelineItem(message: message, messageIndex: index));
    }

    return items;
  }

  bool _shouldShowPartnerAvatar(int messageIndex) {
    final message = _messages[messageIndex];
    if (message.isMine) return false;
    if (messageIndex == _messages.length - 1) return true;

    final nextMessage = _messages[messageIndex + 1];
    return nextMessage.isMine ||
        !_isSameDate(message.sentAt, nextMessage.sentAt);
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
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
    final timelineItems = _buildTimelineItems();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9),
      body: SafeArea(
        child: Column(
          children: [
            PartnerChatHeader(
              isConnected: _isSocketConnected,
              partnerName: _partnerName,
              partnerAvatar: _partnerAvatar,
              onAudioCall: _startAudioCall,
              onVideoCall: _startVideoCall,
            ),
            Expanded(
              child: _isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                  ? const EmptyChatPlaceholder()
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                      itemCount: timelineItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = timelineItems[index];

                        if (item is _DateDividerTimelineItem) {
                          return _DateDivider(date: item.date);
                        }

                        final messageItem = item as _MessageTimelineItem;
                        return MessageBubble(
                          message: messageItem.message,
                          partnerAvatar: _partnerAvatar,
                          showPartnerAvatar: _shouldShowPartnerAvatar(
                            messageItem.messageIndex,
                          ),
                        );
                      },
                    ),
            ),
            MessageComposer(
              controller: _messageController,
              onSend: _sendMessage,
              onPickFile: _pickFileAttachment,
              onPickImage: _pickImageAttachment,
              selectedAttachments: _selectedAttachments,
              onRemoveAttachment: _removeAttachment,
              isSending: _isSending,
            ),
          ],
        ),
      ),
    );
  }
}

sealed class _ChatTimelineItem {
  const _ChatTimelineItem();
}

class _DateDividerTimelineItem extends _ChatTimelineItem {
  const _DateDividerTimelineItem(this.date);

  final DateTime date;
}

class _MessageTimelineItem extends _ChatTimelineItem {
  const _MessageTimelineItem({
    required this.message,
    required this.messageIndex,
  });

  final ChatMessage message;
  final int messageIndex;
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          _formatDateLabel(date),
          style: const TextStyle(
            color: Color(0xFF8A8F96),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) return 'Hôm nay';
    if (targetDate == yesterday) return 'Hôm qua';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
