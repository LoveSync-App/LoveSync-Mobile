import 'package:flutter/material.dart';
import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';
import 'package:lovesync_mobile/features/message/presentation/widgets/message_bubble.dart';
import 'package:lovesync_mobile/features/message/presentation/widgets/message_composer.dart';
import 'package:lovesync_mobile/features/message/presentation/widgets/partner_chat_header.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hôm nay anh nhớ em nhiều lắm.',
      sentAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 12)),
      isMine: false,
    ),
    ChatMessage(
      text: 'Em cũng vậy. Tối nay mình gọi nhau nha?',
      sentAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 5)),
      isMine: true,
    ),
    ChatMessage(
      text: 'Ừ, để anh kể em nghe một chuyện vui ở công ty.',
      sentAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 58)),
      isMine: false,
    ),
    ChatMessage(
      text: 'Vậy em đợi. Nhớ ăn tối trước đó nha.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 42)),
      isMine: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, sentAt: DateTime.now(), isMine: true),
      );
      _messageController.clear();
    });

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
            PartnerChatHeader(isConnected: false),
            Expanded(
              child: ListView.separated(
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
            ),
          ],
        ),
      ),
    );
  }
}
