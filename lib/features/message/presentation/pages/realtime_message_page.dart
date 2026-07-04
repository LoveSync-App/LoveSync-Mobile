import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/call/presentation/providers/call_provider.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_my_couple.dart';
import 'package:lovesync_mobile/features/e2ee/data/repositories/e2ee_repository_impl.dart';
import 'package:lovesync_mobile/features/e2ee/domain/usecases/e2ee_manager.dart';
import 'package:lovesync_mobile/features/message/data/datasources/chat_remote_datasource.dart';
import 'package:lovesync_mobile/features/message/data/datasources/chat_socket_datasource.dart';
import 'package:lovesync_mobile/features/message/data/models/partner_presence_model.dart';
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
  late final ChatRemoteDatasource _chatRemoteDatasource;
  late final E2eeManager _e2eeManager;
  final ImagePicker _imagePicker = ImagePicker();
  ChatSocketDatasource? _chatSocketDatasource;
  StreamSubscription<ChatSocketEvent>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<PartnerPresenceModel>? _presenceSubscription;

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
  PartnerPresenceModel? _partnerPresence;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  String? _nextCursor;

  @override
  void initState() {
    super.initState();

    _chatRemoteDatasource = ChatRemoteDatasource(context.read<DioClient>().dio);
    _e2eeManager = E2eeManager(
      repository: E2eeRepositoryImpl.fromDio(context.read<DioClient>().dio),
    );
    final chatRepository = ChatRepositoryImpl(_chatRemoteDatasource);
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
    _loadPartnerPresence();
    _connectSocket();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _presenceSubscription?.cancel();
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

    _messageSubscription = datasource.messages.listen(
      (event) => unawaited(_handleIncomingMessage(event)),
    );
    _connectionSubscription = datasource.connectionChanges.listen((connected) {
      if (!mounted) return;
      setState(() => _isSocketConnected = connected);
    });
    _presenceSubscription = datasource.partnerPresence.listen((presence) {
      if (!mounted) return;
      setState(() => _partnerPresence = presence);
    });

    datasource.connect();
  }

  Future<void> _loadPartnerPresence() async {
    try {
      final presence = await _chatRemoteDatasource.getPartnerPresence();
      if (!mounted) return;
      setState(() => _partnerPresence = presence);
    } on DioException {
      // Presence API may not be available while the backend is being upgraded.
    }
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
    } catch (_) {
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
      final sortedMessages = await Future.wait(
        page.items.reversed.map(_decryptMessageIfNeeded),
      );
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMessages = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tải được tin nhắn gần đây.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<ChatMessage> _decryptMessageIfNeeded(ChatMessage message) async {
    if (message.encryption == null || _currentUserId.isEmpty) {
      return message;
    }
    final decryptedText = await _e2eeManager.tryDecryptText(
      userId: _currentUserId,
      isMine: message.isMine,
      encryption: message.encryption,
    );
    if (decryptedText == null || decryptedText.isEmpty) {
      return message;
    }
    return message.copyWith(text: decryptedText);
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
      final olderMessages = await Future.wait(
        page.items.reversed
            .where(
              (message) =>
                  message.id == null || !_messageIds.contains(message.id),
            )
            .map(_decryptMessageIfNeeded),
      );
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

    ChatMessage? optimisticMessage;
    setState(() => _isSending = true);

    try {
      final uploadedUrls = attachments.isEmpty
          ? <String>[]
          : await Future.wait(attachments.map(_uploadFile.call));

      var encryption = text.isEmpty
          ? null
          : await _e2eeManager.encryptText(
              userId: _currentUserId,
              plaintext: text,
            );

      if (attachments.isEmpty && text.isNotEmpty && mounted) {
        optimisticMessage = ChatMessage(
          text: text,
          sentAt: DateTime.now(),
          isMine: true,
        );
        setState(() {
          _messages.add(optimisticMessage!);
          _recentlySentMessages[text] = DateTime.now();
          _messageController.clear();
        });
        _scrollToBottom();
      }

      try {
        await _postSendMessage(
          encryption: encryption,
          attachments: uploadedUrls,
        );
      } on DioException catch (error) {
        if (error.response?.statusCode == 409 && text.isNotEmpty) {
          encryption = await _e2eeManager.encryptText(
            userId: _currentUserId,
            plaintext: text,
            forceRefreshPartnerKey: true,
          );
          await _postSendMessage(
            encryption: encryption,
            attachments: uploadedUrls,
          );
        } else {
          rethrow;
        }
      }

      if (mounted) {
        setState(() {
          _selectedAttachments.clear();
          if (attachments.isNotEmpty) {
            _messageController.clear();
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      final pendingMessage = optimisticMessage;
      if (pendingMessage != null) {
        setState(() {
          _messages.remove(pendingMessage);
          _recentlySentMessages.remove(text);
          if (_messageController.text.trim().isEmpty) {
            _messageController.text = text;
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

  Future<void> _showLocationActions() async {
    if (_isSending) return;

    final action = await showModalBottomSheet<_LocationAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chia sẻ vị trí',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chọn gửi một vị trí cố định hoặc chia sẻ trực tiếp.',
                style: TextStyle(color: Color(0xFF70757A)),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE7ED),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFA03B56),
                  ),
                ),
                title: const Text('Gửi vị trí hiện tại'),
                subtitle: const Text('Gửi một vị trí cố định vào tin nhắn'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.of(context).pop(_LocationAction.snapshot),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F0FF),
                  child: Icon(Icons.near_me_rounded, color: Color(0xFF4C79C6)),
                ),
                title: const Text('Chia sẻ vị trí trực tiếp'),
                subtitle: const Text(
                  'Người ấy theo dõi vị trí mới nhất trên map',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pop(_LocationAction.live),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == _LocationAction.snapshot) {
      final sent = await context.push<bool>(
        AppRoutePaths.locationSnapshotPreview,
      );
      if (sent == true && mounted) {
        await _loadRecentMessages();
      }
      return;
    }
    await _openLiveLocation();
  }

  Future<void> _openLiveLocation() {
    return context.push<void>(AppRoutePaths.locationLiveMap);
  }

  void _removeAttachment(File attachment) {
    if (_isSending) return;
    setState(() => _selectedAttachments.remove(attachment));
  }

  Future<void> _handleIncomingMessage(ChatSocketEvent event) async {
    final message = event.message;
    final hasMessageBody =
        message.text.isNotEmpty ||
        message.encryption != null ||
        message.attachments.isNotEmpty ||
        message.type == ChatMessageType.call ||
        message.type == ChatMessageType.location;
    if (!hasMessageBody) return;

    final isMine = message.senderId == _currentUserId;
    final entity = await _decryptMessageIfNeeded(
      message.toEntity(isMine: isMine),
    );
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
        _isEchoFromRecentSend(entity.text)) {
      final optimisticIndex = _messages.lastIndexWhere(
        (item) => item.id == null && item.isMine && item.text == entity.text,
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
              isPartnerOnline: _partnerPresence?.isOnline,
              partnerName: _partnerName,
              partnerAvatar: _partnerAvatar,
              onAudioCall: _startAudioCall,
              onVideoCall: _startVideoCall,
              onLocation: _openLiveLocation,
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
              onLocation: _showLocationActions,
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

enum _LocationAction { snapshot, live }

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
