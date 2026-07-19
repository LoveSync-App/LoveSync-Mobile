import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lovesync_mobile/features/location/presentation/providers/location_sharing_provider.dart';
import 'package:lovesync_mobile/features/location/presentation/widgets/location_map.dart';
import 'package:provider/provider.dart';

class LocationPreviewPage extends StatefulWidget {
  const LocationPreviewPage({super.key});

  @override
  State<LocationPreviewPage> createState() => _LocationPreviewPageState();
}

class _LocationPreviewPageState extends State<LocationPreviewPage> {
  Position? _position;
  String? _error;
  bool _isLoading = true;
  bool _isSending = false;
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _permanentlyDenied = false;
    });
    try {
      final position = await context
          .read<LocationSharingProvider>()
          .getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = position);
    } on LocationPermissionException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _permanentlyDenied = error.permanentlyDenied;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Không thể xác định vị trí hiện tại.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendLocation() async {
    final position = _position;
    if (position == null || _isSending) return;

    setState(() => _isSending = true);
    try {
      await context.read<LocationSharingProvider>().sendSnapshot(position);
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final message = data is Map
          ? (data['message'] ?? data['error'])?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Không gửi được vị trí. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi vị trí hiện tại'),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : position == null
          ? _LocationError(
              message: _error ?? 'Không thể xác định vị trí.',
              onRetry: _loadPosition,
              onOpenSettings: () {
                context.read<LocationSharingProvider>().openLocationSettings(
                  appSettings: _permanentlyDenied,
                );
              },
            )
          : Column(
              children: [
                Expanded(
                  child: LocationMap(
                    markers: [
                      LocationMapMarker(
                        latitude: position.latitude,
                        longitude: position.longitude,
                        color: const Color(0xFFA03B56),
                        icon: Icons.my_location_rounded,
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vị trí của bạn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Độ chính xác khoảng '
                          '${position.accuracy.round()} m · Đây là vị trí cố định',
                          style: const TextStyle(color: Color(0xFF70757A)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _isSending ? null : _sendLocation,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFA03B56),
                            ),
                            icon: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              _isSending ? 'Đang gửi...' : 'Gửi vị trí này',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LocationError extends StatelessWidget {
  const _LocationError({
    required this.message,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 56,
              color: Color(0xFFA03B56),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            TextButton(
              onPressed: onOpenSettings,
              child: const Text('Mở cài đặt vị trí'),
            ),
          ],
        ),
      ),
    );
  }
}
