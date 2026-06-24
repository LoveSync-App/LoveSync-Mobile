import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';

class ChatMessageModel {
  const ChatMessageModel({
    this.id,
    required this.text,
    required this.sentAt,
    this.senderId,
  });

  final String? id;
  final String text;
  final DateTime sentAt;
  final String? senderId;

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
    );
  }

  ChatMessage toEntity({required bool isMine}) {
    return ChatMessage(id: id, text: text, sentAt: sentAt, isMine: isMine);
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
}
