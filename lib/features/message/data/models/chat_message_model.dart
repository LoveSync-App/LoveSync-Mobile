import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';

class ChatMessageModel {
  const ChatMessageModel({
    this.id,
    required this.text,
    required this.sentAt,
    this.senderId,
    this.attachments = const [],
    this.type = ChatMessageType.text,
  });

  final String? id;
  final String text;
  final DateTime sentAt;
  final String? senderId;
  final List<String> attachments;
  final ChatMessageType type;

  factory ChatMessageModel.fromSocket(dynamic data) {
    final json = _asJson(data);
    return ChatMessageModel.fromJson(json);
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final nestedData = json['data'];
    if (nestedData is Map<String, dynamic>) {
      return ChatMessageModel.fromJson(nestedData);
    }

    return ChatMessageModel(
      id: _readString(json, ['id', '_id', 'messageId']),
      text: _readString(json, ['message', 'text', 'content']) ?? '',
      sentAt: _readDateTime(json, [
        'createdAt',
        'created_at',
        'sentAt',
        'timestamp',
        'time',
      ]),
      senderId: _readString(json, [
        'sender',
        'senderId',
        'sender_id',
        'userId',
        'from',
      ]),
      attachments: _readAttachments(json),
      type: _readType(json),
    );
  }

  ChatMessage toEntity({required bool isMine}) {
    return ChatMessage(
      id: id,
      text: text,
      sentAt: sentAt,
      isMine: isMine,
      attachments: attachments,
      type: type,
    );
  }

  static Map<String, dynamic> _asJson(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return {'message': data?.toString() ?? ''};
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return null;
  }

  static DateTime _readDateTime(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed.toLocal();
      }
    }
    return DateTime.now();
  }

  static List<String> _readAttachments(Map<String, dynamic> json) {
    final rawAttachments =
        json['attachments'] ??
        json['attachmentUrls'] ??
        json['attachment_urls'];

    if (rawAttachments is! List) return [];

    return rawAttachments
        .map((attachment) {
          if (attachment is String) return attachment;
          if (attachment is Map<String, dynamic>) {
            return _readString(attachment, ['file_url', 'fileUrl', 'url']);
          }
          if (attachment is Map) {
            final normalized = attachment.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            return _readString(normalized, ['file_url', 'fileUrl', 'url']);
          }
          return null;
        })
        .whereType<String>()
        .where((url) => url.trim().isNotEmpty)
        .toList();
  }

  static ChatMessageType _readType(Map<String, dynamic> json) {
    final rawType = _readString(json, ['type', 'messageType', 'message_type']);
    switch (rawType?.toUpperCase()) {
      case 'IMAGE':
        return ChatMessageType.image;
      case 'VIDEO':
        return ChatMessageType.video;
      case 'TEXT':
      default:
        return ChatMessageType.text;
    }
  }
}
