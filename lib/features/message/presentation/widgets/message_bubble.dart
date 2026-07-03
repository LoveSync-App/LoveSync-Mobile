import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/features/location/presentation/widgets/location_map.dart';
import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.showPartnerAvatar,
    required this.partnerAvatar,
  });

  final ChatMessage message;
  final bool showPartnerAvatar;
  final String partnerAvatar;

  @override
  Widget build(BuildContext context) {
    if (message.type == ChatMessageType.call) {
      return _CallTimelineCard(message: message);
    }
    if (message.type == ChatMessageType.location) {
      return _LocationTimelineCard(message: message);
    }

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
                ? CircleAvatar(
                    radius: 14,
                    backgroundImage: partnerAvatar.isEmpty
                        ? null
                        : NetworkImage(partnerAvatar),
                    child: partnerAvatar.isEmpty
                        ? const Icon(Icons.person, size: 16)
                        : null,
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
                if (message.attachments.isNotEmpty) ...[
                  ...message.attachments.map(
                    (url) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AttachmentPreview(
                        url: url,
                        type: message.type,
                        isMine: message.isMine,
                      ),
                    ),
                  ),
                ],
                if (message.text.isNotEmpty) ...[
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
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

class _CallTimelineCard extends StatelessWidget {
  const _CallTimelineCard({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final payload = message.payload;
    final callType = payload['callType']?.toString().toLowerCase();
    final result =
        payload['result']?.toString().toLowerCase() ??
        payload['status']?.toString().toLowerCase() ??
        '';
    final duration = _readInt(payload['durationSeconds']);
    final isVideo = callType == 'video';
    final isFailed = {'missed', 'rejected', 'canceled'}.contains(result);
    final color = isFailed
        ? const Color(0xFFD84A5B)
        : result == 'completed'
        ? const Color(0xFF3C9B68)
        : const Color(0xFFA03B56);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideo ? Icons.videocam_outlined : Icons.call_outlined,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.isMine
                        ? (isVideo ? 'Bạn đã gọi video' : 'Bạn đã gọi thoại')
                        : (isVideo ? 'Cuộc gọi video đến' : 'Cuộc gọi đến'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _callResultLabel(result, duration),
                    style: TextStyle(color: color, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              DateFormat('HH:mm').format(message.sentAt),
              style: const TextStyle(fontSize: 10, color: Color(0xFF8A8F96)),
            ),
          ],
        ),
      ),
    );
  }

  static String _callResultLabel(String result, int duration) {
    return switch (result) {
      'completed' =>
        duration > 0
            ? 'Đã kết thúc · ${_formatDuration(duration)}'
            : 'Đã kết thúc',
      'missed' => 'Cuộc gọi nhỡ',
      'rejected' => 'Đã từ chối',
      'canceled' => 'Đã hủy',
      'ongoing' => 'Đang diễn ra',
      'ringing' => 'Đang đổ chuông',
      _ => 'Cuộc gọi',
    };
  }

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _LocationTimelineCard extends StatelessWidget {
  const _LocationTimelineCard({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final payload = message.payload;
    final address = payload['address']?.toString();
    final label = payload['label']?.toString();
    final latitude = _readDouble(payload['latitude']);
    final longitude = _readDouble(payload['longitude']);

    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: latitude == null || longitude == null
            ? null
            : () {
                context.push(
                  AppRoutes.locationSnapshot,
                  extra: LocationSnapshotRouteExtra(
                    latitude: latitude,
                    longitude: longitude,
                    address: address,
                    label: label,
                  ),
                );
              },
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            color: message.isMine ? const Color(0xFFA03B56) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (latitude != null && longitude != null)
                SizedBox(
                  height: 130,
                  child: LocationMap(
                    interactive: false,
                    zoom: 15,
                    markers: [
                      LocationMapMarker(
                        latitude: latitude,
                        longitude: longitude,
                        color: const Color(0xFFA03B56),
                        icon: Icons.favorite_rounded,
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 30,
                      color: message.isMine
                          ? Colors.white
                          : const Color(0xFFA03B56),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address == null || address.isEmpty
                                ? (label == null || label.isEmpty
                                      ? 'Vị trí đã chia sẻ'
                                      : label)
                                : address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: message.isMine
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Nhấn để xem bản đồ',
                            style: TextStyle(
                              fontSize: 11,
                              color: message.isMine
                                  ? Colors.white70
                                  : const Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(message.sentAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: message.isMine
                            ? Colors.white70
                            : const Color(0xFF8A8F96),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    required this.url,
    required this.type,
    required this.isMine,
  });

  final String url;
  final ChatMessageType type;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final child = type == ChatMessageType.video
        ? _buildVideoPreview(context)
        : _buildImagePreview(context);

    return GestureDetector(
      onTap: () => type == ChatMessageType.video
          ? _openVideoViewer(context)
          : _openImageViewer(context),
      child: child,
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    return Container(
      width: 220,
      height: 124,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.play_circle_fill_rounded,
        size: 42,
        color: isMine ? Colors.white : const Color(0xFFA03B56),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 220,
          height: 124,
          alignment: Alignment.center,
          color: Colors.black.withValues(alpha: 0.08),
          child: Icon(
            Icons.broken_image_outlined,
            color: isMine ? Colors.white : const Color(0xFFA03B56),
          ),
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoViewer(BuildContext context) {
    context.push(AppRoutes.messageVideoViewer, extra: {'url': url});
  }
}
