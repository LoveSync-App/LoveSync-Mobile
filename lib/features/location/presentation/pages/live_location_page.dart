import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lovesync_mobile/features/location/domain/entities/live_location.dart';
import 'package:lovesync_mobile/features/location/presentation/providers/location_sharing_provider.dart';
import 'package:lovesync_mobile/features/location/presentation/widgets/location_map.dart';
import 'package:provider/provider.dart';

class LiveLocationPage extends StatefulWidget {
  const LiveLocationPage({super.key});

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  Position? _currentPosition;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationSharingProvider>().refresh();
      _locateMe();
    });
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await context
          .read<LocationSharingProvider>()
          .getCurrentPosition();
      if (mounted) setState(() => _currentPosition = position);
    } on LocationPermissionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _chooseDuration() async {
    final option = await showModalBottomSheet<_ShareDurationOption>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _DurationSheet(),
    );
    if (option == null || !mounted) return;

    try {
      await context.read<LocationSharingProvider>().startSharing(
        durationMinutes: option.durationMinutes,
        untilStopped: option.untilStopped,
        initialPosition: _currentPosition,
      );
    } catch (_) {
      if (!mounted) return;
      final provider = context.read<LocationSharingProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Không thể bắt đầu chia sẻ vị trí.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopSharing() async {
    try {
      await context.read<LocationSharingProvider>().stopSharing();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể dừng chia sẻ vị trí.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationSharingProvider>(
      builder: (context, provider, _) {
        final myLocation = provider.myLocation;
        final partnerLocation = provider.partnerLocation;
        final markers = <LocationMapMarker>[
          if (myLocation != null)
            LocationMapMarker(
              latitude: myLocation.latitude,
              longitude: myLocation.longitude,
              color: const Color(0xFFA03B56),
              icon: Icons.person_rounded,
            )
          else if (_currentPosition != null)
            LocationMapMarker(
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
              color: const Color(0xFFA03B56),
              icon: Icons.person_rounded,
            ),
          if (partnerLocation != null)
            LocationMapMarker(
              latitude: partnerLocation.latitude,
              longitude: partnerLocation.longitude,
              color: const Color(0xFF4C79C6),
              icon: Icons.favorite_rounded,
            ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chia sẻ vị trí trực tiếp'),
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: provider.isLoading ? null : provider.refresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Làm mới',
              ),
            ],
          ),
          body: Stack(
            children: [
              LocationMap(markers: markers),
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: _MapLegend(
                  hasMyLocation: myLocation != null,
                  hasPartnerLocation: partnerLocation != null,
                ),
              ),
              Positioned(
                right: 16,
                bottom: 230,
                child: FloatingActionButton.small(
                  heroTag: 'locate-me',
                  onPressed: _locating ? null : _locateMe,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFA03B56),
                  child: _locating
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _LiveControlPanel(
                  provider: provider,
                  myLocation: myLocation,
                  partnerLocation: partnerLocation,
                  onStart: _chooseDuration,
                  onStop: _stopSharing,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({
    required this.hasMyLocation,
    required this.hasPartnerLocation,
  });

  final bool hasMyLocation;
  final bool hasPartnerLocation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendDot(
              color: const Color(0xFFA03B56),
              label: hasMyLocation ? 'Bạn' : 'Bạn chưa chia sẻ',
            ),
            const SizedBox(width: 14),
            _LegendDot(
              color: const Color(0xFF4C79C6),
              label: hasPartnerLocation ? 'Người ấy' : 'Người ấy chưa chia sẻ',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _LiveControlPanel extends StatelessWidget {
  const _LiveControlPanel({
    required this.provider,
    required this.myLocation,
    required this.partnerLocation,
    required this.onStart,
    required this.onStop,
  });

  final LocationSharingProvider provider;
  final LiveLocation? myLocation;
  final LiveLocation? partnerLocation;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 18,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              myLocation != null
                  ? 'Bạn đang chia sẻ vị trí'
                  : 'Chia sẻ hành trình của bạn',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              myLocation != null
                  ? provider.shareUntilStopped
                        ? 'Tiếp tục chia sẻ đến khi bạn tự tắt.'
                        : _expiryLabel(myLocation!.sharingExpiresAt)
                  : partnerLocation != null
                  ? 'Người ấy đang chia sẻ vị trí với bạn.'
                  : 'Chỉ người ấy có thể xem. LoveSync không lưu hành trình.',
              style: const TextStyle(color: Color(0xFF70757A)),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: myLocation != null
                  ? OutlinedButton.icon(
                      onPressed: provider.isLoading ? null : onStop,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Dừng chia sẻ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD84A5B),
                        side: const BorderSide(color: Color(0xFFD84A5B)),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: provider.isLoading ? null : onStart,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.near_me_rounded),
                      label: const Text('Bắt đầu chia sẻ trực tiếp'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA03B56),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _expiryLabel(DateTime? expiresAt) {
    if (expiresAt == null) return 'Phiên chia sẻ đang hoạt động.';
    return 'Tự động dừng lúc ${DateFormat('HH:mm').format(expiresAt)}.';
  }
}

class _DurationSheet extends StatelessWidget {
  const _DurationSheet();

  @override
  Widget build(BuildContext context) {
    const options = [
      _ShareDurationOption(15, '15 phút'),
      _ShareDurationOption(60, '1 giờ'),
      _ShareDurationOption(480, '8 giờ'),
      _ShareDurationOption(1440, '24 giờ'),
      _ShareDurationOption(1440, 'Đến khi bạn tắt', untilStopped: true),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chia sẻ trong bao lâu?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn có thể dừng bất cứ lúc nào.',
                style: TextStyle(color: Color(0xFF70757A)),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (option) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFFFE7ED),
                    child: Icon(
                      option.untilStopped
                          ? Icons.all_inclusive_rounded
                          : Icons.schedule,
                      color: const Color(0xFFA03B56),
                    ),
                  ),
                  title: Text(option.label),
                  subtitle: option.untilStopped
                      ? const Text('Chỉ dừng khi bạn chủ động tắt chia sẻ')
                      : null,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(option),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareDurationOption {
  const _ShareDurationOption(
    this.durationMinutes,
    this.label, {
    this.untilStopped = false,
  });

  final int durationMinutes;
  final String label;
  final bool untilStopped;
}
