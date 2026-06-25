import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lovesync_mobile/features/message/domain/entities/chat_message.dart';
import 'package:video_player/video_player.dart';

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
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => _VideoViewerPage(url: url)));
  }
}

class _VideoViewerPage extends StatefulWidget {
  const _VideoViewerPage({required this.url});

  final String url;

  @override
  State<_VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<_VideoViewerPage> {
  late final VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {});
            _controller.play();
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() => _hasError = true);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _hasError
                  ? const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 48,
                    )
                  : isReady
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (isReady && !_hasError)
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFFA03B56),
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    IconButton.filled(
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
