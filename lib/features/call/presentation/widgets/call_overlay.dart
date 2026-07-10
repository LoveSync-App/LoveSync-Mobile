import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:lovesync_mobile/features/call/domain/entities/call_session.dart';
import 'package:lovesync_mobile/features/call/presentation/providers/call_provider.dart';
import 'package:provider/provider.dart';

class CallOverlay extends StatefulWidget {
  const CallOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay> {
  Room? _room;
  String? _roomKey;
  String? _lastAttemptedRoomKey;
  bool _isConnectingMedia = false;
  bool _isMicrophoneEnabled = true;
  bool _isSpeakerEnabled = false;
  bool _isCameraEnabled = true;
  bool _isUsingFrontCamera = true;
  String? _mediaError;
  Timer? _durationTimer;
  Duration _duration = Duration.zero;

  @override
  void dispose() {
    _durationTimer?.cancel();
    unawaited(_disposeRoom());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = context.watch<CallProvider>();
    _synchronizeMedia(callProvider);
    _synchronizeTimer(callProvider.phase);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        children: [
          widget.child,
          if (callProvider.isVisible)
            Positioned.fill(child: _buildCallScreen(callProvider)),
        ],
      ),
    );
  }

  void _synchronizeMedia(CallProvider provider) {
    if (!provider.isVisible) {
      _lastAttemptedRoomKey = null;
      if (_room != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_disposeRoom());
        });
      }
      return;
    }

    final credentials = provider.credentials;
    final callId = provider.activeCall?.id;
    if (credentials == null || callId == null) return;
    final isVideo = provider.activeCall?.type == 'video';
    final nextKey = '$callId:${credentials.participantToken}:$isVideo';
    if (_roomKey == nextKey ||
        _lastAttemptedRoomKey == nextKey ||
        _isConnectingMedia) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_connectRoom(nextKey, credentials, isVideo: isVideo));
    });
  }

  void _synchronizeTimer(CallPhase phase) {
    if (phase == CallPhase.ongoing && _durationTimer == null) {
      _duration = Duration.zero;
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _duration += const Duration(seconds: 1));
      });
    } else if (phase != CallPhase.ongoing && _durationTimer != null) {
      _durationTimer?.cancel();
      _durationTimer = null;
      _duration = Duration.zero;
    }
  }

  Future<void> _connectRoom(
    String roomKey,
    LiveKitCredentials credentials, {
    required bool isVideo,
  }) async {
    if (_isConnectingMedia || _roomKey == roomKey) return;
    _lastAttemptedRoomKey = roomKey;
    _isConnectingMedia = true;
    _mediaError = null;
    if (mounted) setState(() {});

    await _disposeRoom();
    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
    room.addListener(_onRoomChanged);
    _room = room;
    try {
      await room.prepareConnection(
        credentials.serverUrl,
        credentials.participantToken,
      );
      await room.connect(credentials.serverUrl, credentials.participantToken);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (isVideo) {
        try {
          await room.localParticipant?.setCameraEnabled(
            true,
            cameraCaptureOptions: const CameraCaptureOptions(
              cameraPosition: CameraPosition.front,
            ),
          );
          _isCameraEnabled = true;
        } catch (_) {
          _isCameraEnabled = false;
          _mediaError =
              'Không mở được camera. Hãy kiểm tra quyền camera trong cài đặt.';
        }
      }
      final speakerEnabled = isVideo || _isSpeakerEnabled;
      await room.setSpeakerOn(speakerEnabled);
      _roomKey = roomKey;
      _isMicrophoneEnabled = true;
      _isSpeakerEnabled = speakerEnabled;
      if (!isVideo) _isCameraEnabled = false;
      _isUsingFrontCamera = true;
    } catch (_) {
      _mediaError = isVideo
          ? 'Không thể kết nối camera hoặc âm thanh. Vui lòng thử lại.'
          : 'Không thể kết nối âm thanh. Vui lòng thử lại.';
      await _disposeRoom();
    } finally {
      _isConnectingMedia = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleMicrophone() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    final nextValue = !_isMicrophoneEnabled;
    await participant.setMicrophoneEnabled(nextValue);
    if (mounted) setState(() => _isMicrophoneEnabled = nextValue);
  }

  Future<void> _toggleSpeaker() async {
    final room = _room;
    if (room == null) return;
    final nextValue = !_isSpeakerEnabled;
    await room.setSpeakerOn(nextValue);
    if (mounted) setState(() => _isSpeakerEnabled = nextValue);
  }

  Future<void> _toggleCamera() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    final nextValue = !_isCameraEnabled;
    await participant.setCameraEnabled(
      nextValue,
      cameraCaptureOptions: CameraCaptureOptions(
        cameraPosition: _isUsingFrontCamera
            ? CameraPosition.front
            : CameraPosition.back,
      ),
    );
    if (mounted) setState(() => _isCameraEnabled = nextValue);
  }

  Future<void> _switchCamera() async {
    final participant = _room?.localParticipant;
    if (participant == null || !_isCameraEnabled) return;
    final publication = participant.getTrackPublicationBySource(
      TrackSource.camera,
    );
    final track = publication?.track;
    if (track is! LocalVideoTrack) return;

    final nextPosition = _isUsingFrontCamera
        ? CameraPosition.back
        : CameraPosition.front;
    await track.setCameraPosition(nextPosition);
    if (mounted) setState(() => _isUsingFrontCamera = !_isUsingFrontCamera);
  }

  void _onRoomChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _disposeRoom() async {
    final room = _room;
    _room = null;
    _roomKey = null;
    if (room == null) return;
    room.removeListener(_onRoomChanged);
    try {
      await room.disconnect();
    } finally {
      await room.dispose();
    }
  }

  Widget _buildCallScreen(CallProvider provider) {
    if (provider.activeCall?.type == 'video') {
      return _buildVideoCallScreen(provider);
    }

    final isIncoming = provider.phase == CallPhase.incoming;
    final isOngoing = provider.phase == CallPhase.ongoing;
    final partnerName = provider.partnerName.isEmpty
        ? 'Người ấy'
        : provider.partnerName;

    return PopScope(
      canPop: false,
      child: Material(
        color: const Color(0xFF2E1320),
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5D263B), Color(0xFF210D16)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(28, 54, 28, 42),
            child: Column(
              children: [
                Text(
                  _statusLabel(provider.phase),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 34),
                CircleAvatar(
                  radius: 68,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  backgroundImage: provider.partnerAvatar.isEmpty
                      ? null
                      : NetworkImage(provider.partnerAvatar),
                  child: provider.partnerAvatar.isEmpty
                      ? const Icon(Icons.person, size: 70, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  partnerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isOngoing ? _formatDuration(_duration) : 'Cuộc gọi thoại',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 16,
                  ),
                ),
                if (_isConnectingMedia) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.white),
                ],
                if (_mediaError != null || provider.errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _mediaError ?? provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFFB4B4)),
                  ),
                ],
                const Spacer(),
                if (isIncoming)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallAction(
                        icon: Icons.call_end,
                        label: 'Từ chối',
                        color: const Color(0xFFE14A55),
                        onPressed: provider.rejectIncomingCall,
                      ),
                      _CallAction(
                        icon: Icons.call,
                        label: 'Trả lời',
                        color: const Color(0xFF44B86A),
                        onPressed: provider.acceptIncomingCall,
                      ),
                    ],
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallAction(
                        icon: _isMicrophoneEnabled ? Icons.mic : Icons.mic_off,
                        label: _isMicrophoneEnabled ? 'Tắt mic' : 'Bật mic',
                        color: Colors.white.withValues(alpha: 0.16),
                        onPressed: _room == null ? null : _toggleMicrophone,
                      ),
                      _CallAction(
                        icon: _isSpeakerEnabled
                            ? Icons.volume_up
                            : Icons.volume_down,
                        label: 'Loa ngoài',
                        color: _isSpeakerEnabled
                            ? const Color(0xFFA03B56)
                            : Colors.white.withValues(alpha: 0.16),
                        onPressed: _room == null ? null : _toggleSpeaker,
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  _CallAction(
                    icon: Icons.call_end,
                    label: provider.phase == CallPhase.outgoing
                        ? 'Hủy'
                        : 'Kết thúc',
                    color: const Color(0xFFE14A55),
                    onPressed: provider.hangUp,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCallScreen(CallProvider provider) {
    final isIncoming = provider.phase == CallPhase.incoming;
    final isOngoing = provider.phase == CallPhase.ongoing;
    final partnerName = provider.partnerName.isEmpty
        ? 'Người ấy'
        : provider.partnerName;
    final remoteTrack = _remoteCameraTrack();
    final localTrack = _localCameraTrack();

    return PopScope(
      canPop: false,
      child: Material(
        color: const Color(0xFF171117),
        child: Stack(
          children: [
            Positioned.fill(
              child: remoteTrack == null
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF5D263B), Color(0xFF170B11)],
                        ),
                      ),
                    )
                  : VideoTrackRenderer(remoteTrack, fit: VideoViewFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.42),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.62),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 34),
                child: Column(
                  children: [
                    Text(
                      _statusLabel(provider.phase),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      partnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isOngoing ? _formatDuration(_duration) : 'Cuộc gọi video',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    if (remoteTrack == null) ...[
                      const Spacer(),
                      CircleAvatar(
                        radius: 58,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        backgroundImage: provider.partnerAvatar.isEmpty
                            ? null
                            : NetworkImage(provider.partnerAvatar),
                        child: provider.partnerAvatar.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 62,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isIncoming
                            ? 'Cuộc gọi video đến'
                            : 'Đang chờ người ấy tham gia…',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (_isConnectingMedia)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    if (_mediaError != null || provider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          _mediaError ?? provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFFFB4B4)),
                        ),
                      ),
                    if (isIncoming)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CallAction(
                            icon: Icons.call_end,
                            label: 'Từ chối',
                            color: const Color(0xFFE14A55),
                            onPressed: provider.rejectIncomingCall,
                          ),
                          _CallAction(
                            icon: Icons.videocam,
                            label: 'Trả lời',
                            color: const Color(0xFF44B86A),
                            onPressed: provider.acceptIncomingCall,
                          ),
                        ],
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CallAction(
                            icon: _isMicrophoneEnabled
                                ? Icons.mic
                                : Icons.mic_off,
                            label: _isMicrophoneEnabled ? 'Tắt mic' : 'Bật mic',
                            color: Colors.white.withValues(alpha: 0.18),
                            onPressed: _room == null ? null : _toggleMicrophone,
                          ),
                          _CallAction(
                            icon: _isCameraEnabled
                                ? Icons.videocam
                                : Icons.videocam_off,
                            label: _isCameraEnabled
                                ? 'Tắt camera'
                                : 'Bật camera',
                            color: Colors.white.withValues(alpha: 0.18),
                            onPressed: _room == null ? null : _toggleCamera,
                          ),
                          _CallAction(
                            icon: Icons.cameraswitch,
                            label: 'Đổi camera',
                            color: Colors.white.withValues(alpha: 0.18),
                            onPressed: _room == null || !_isCameraEnabled
                                ? null
                                : _switchCamera,
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      _CallAction(
                        icon: Icons.call_end,
                        label: provider.phase == CallPhase.outgoing
                            ? 'Hủy'
                            : 'Kết thúc',
                        color: const Color(0xFFE14A55),
                        onPressed: provider.hangUp,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (localTrack != null && !isIncoming)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 112,
                    height: 158,
                    margin: const EdgeInsets.only(top: 104, right: 16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.75),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: VideoTrackRenderer(
                      localTrack,
                      fit: VideoViewFit.cover,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  VideoTrack? _remoteCameraTrack() {
    final room = _room;
    if (room == null) return null;

    for (final participant in room.remoteParticipants.values) {
      final publication = participant.getTrackPublicationBySource(
        TrackSource.camera,
      );
      final track = publication?.track;
      if (publication != null && !publication.muted && track is VideoTrack) {
        return track as VideoTrack;
      }
    }
    return null;
  }

  VideoTrack? _localCameraTrack() {
    if (!_isCameraEnabled) return null;
    final publication = _room?.localParticipant?.getTrackPublicationBySource(
      TrackSource.camera,
    );
    final track = publication?.track;
    return track is VideoTrack ? track as VideoTrack : null;
  }

  String _statusLabel(CallPhase phase) {
    return switch (phase) {
      CallPhase.starting => 'Đang tạo cuộc gọi…',
      CallPhase.incoming => 'Cuộc gọi đến',
      CallPhase.outgoing => 'Đang đổ chuông…',
      CallPhase.ongoing => 'Đã kết nối',
      CallPhase.ending => 'Đang kết thúc…',
      CallPhase.idle => '',
    };
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          onPressed: onPressed == null
              ? null
              : () async {
                  try {
                    await onPressed!();
                  } catch (_) {
                    // The provider exposes an error message in the call UI.
                  }
                },
          style: IconButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
            minimumSize: const Size(66, 66),
          ),
          icon: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 9),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
