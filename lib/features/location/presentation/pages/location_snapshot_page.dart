import 'package:flutter/material.dart';
import 'package:lovesync_mobile/features/location/presentation/widgets/location_map.dart';

class LocationSnapshotPage extends StatelessWidget {
  const LocationSnapshotPage({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    this.label,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(label?.trim().isNotEmpty == true ? label! : 'Vị trí'),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          LocationMap(
            markers: [
              LocationMapMarker(
                latitude: latitude,
                longitude: longitude,
                color: const Color(0xFFA03B56),
                icon: Icons.favorite_rounded,
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFA03B56),
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address?.trim().isNotEmpty == true
                                ? address!
                                : 'Vị trí đã chia sẻ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${latitude.toStringAsFixed(6)}, '
                            '${longitude.toStringAsFixed(6)}',
                            style: const TextStyle(color: Color(0xFF70757A)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
