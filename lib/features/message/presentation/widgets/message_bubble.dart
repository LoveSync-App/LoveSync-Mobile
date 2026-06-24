import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.showPartnerAvatar,
  });

  final ChatMessage message;
  final bool showPartnerAvatar;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isMine ? const Color(0xFFA03B56) : Colors.white;
    final textColor = message.isMine ? Colors.white : const Color(0xFF24272A);
    final timeColor = message.isMine
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF8A8F96);

    return Row(
      mainAxisAlignment: message.isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!message.isMine) ...[
          SizedBox(
            width: 32,
            child: showPartnerAvatar
                ? const CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=5',
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.isMine ? 18 : 6),
                bottomRight: Radius.circular(message.isMine ? 6 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('HH:mm').format(message.sentAt),
                  style: TextStyle(fontSize: 10, color: timeColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
