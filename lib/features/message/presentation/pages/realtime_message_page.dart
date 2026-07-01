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
  StreamSubscription<ChatSocketEvent>? _messageSubscription;
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
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  String? _nextCursor;

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
    _scrollController.addListener(_handleScroll);
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
      final page = await _getRecentMessages(_currentUserId);
      final sortedMessages = List<ChatMessage>.from(page.items.reversed);
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
        _hasMoreMessages = page.hasMore;
        _nextCursor = page.nextCursor;
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

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.pixels > 120) {
      return;
    }
    _loadOlderMessages();
  }

  Future<void> _loadOlderMessages() async {
    final cursor = _nextCursor;
    if (_isLoadingMore ||
        !_hasMoreMessages ||
        cursor == null ||
        cursor.isEmpty ||
        _currentUserId.isEmpty) {
      return;
    }

    _isLoadingMore = true;
    if (mounted) setState(() {});
    final previousMaxExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    try {
      final page = await _getRecentMessages(_currentUserId, cursor: cursor);
      final olderMessages = page.items.reversed
          .where(
            (message) =>
                message.id == null || !_messageIds.contains(message.id),
          )
          .toList();
      if (!mounted) return;

      setState(() {
        _messages.insertAll(0, olderMessages);
        _messageIds.addAll(
          olderMessages.map((message) => message.id).whereType<String>(),
        );
        _hasMoreMessages = page.hasMore;
        _nextCursor = page.nextCursor;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final addedExtent =
            _scrollController.position.maxScrollExtent - previousMaxExtent;
        _scrollController.jumpTo(
          (_scrollController.position.pixels + addedExtent).clamp(
            0,
            _scrollController.position.maxScrollExtent,
          ),
        );
      });
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tải được tin nhắn cũ hơn.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isLoadingMore = false;
      if (mounted) setState(() {});
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

  void _handleIncomingMessage(ChatSocketEvent event) {
    final message = event.message;
    final hasMessageBody =
        message.text.isNotEmpty ||
        message.attachments.isNotEmpty ||
        message.type == ChatMessageType.call ||
        message.type == ChatMessageType.location;
    if (!hasMessageBody) return;

    final isMine = message.senderId == _currentUserId;
    final entity = message.toEntity(isMine: isMine);
    final messageId = message.id;
    final existingIndex = messageId == null
        ? -1
        : _messages.indexWhere((item) => item.id == messageId);

    if (event.isUpdate || existingIndex >= 0) {
      if (existingIndex < 0) return;
      setState(() => _messages[existingIndex] = entity);
      return;
    }

    if (isMine &&
        message.attachments.isEmpty &&
        _isEchoFromRecentSend(message.text)) {
      final optimisticIndex = _messages.lastIndexWhere(
        (item) => item.id == null && item.isMine && item.text == message.text,
      );
      if (optimisticIndex >= 0) {
        setState(() {
          _messages[optimisticIndex] = entity;
          if (messageId != null) _messageIds.add(messageId);
        });
      }
      return;
    }

    setState(() {
      if (messageId != null) {
        _messageIds.add(messageId);
      }
      _messages.add(entity);
    });
    _scrollToBottom();
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
                      itemCount:
                          timelineItems.length + (_isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (_isLoadingMore && index == 0) {
                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final timelineIndex = index - (_isLoadingMore ? 1 : 0);
                        final item = timelineItems[timelineIndex];

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
