import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationMapMarker {
  const LocationMapMarker({
    required this.latitude,
    required this.longitude,
    required this.color,
    required this.icon,
  });

  final double latitude;
  final double longitude;
  final Color color;
  final IconData icon;
}

class LocationMap extends StatefulWidget {
  const LocationMap({
    super.key,
    required this.markers,
    this.zoom = 16,
    this.interactive = true,
  });

  final List<LocationMapMarker> markers;
  final double zoom;
  final bool interactive;

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  final MapController _controller = MapController();

  @override
  void didUpdateWidget(covariant LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_positionsChanged(oldWidget.markers, widget.markers)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMarkers());
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.markers.isEmpty
        ? const LatLng(10.7769, 106.7009)
        : LatLng(widget.markers.first.latitude, widget.markers.first.longitude);

    return IgnorePointer(
      ignoring: !widget.interactive,
      child: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: widget.zoom,
          interactionOptions: InteractionOptions(
            flags: widget.interactive
                ? InteractiveFlag.all
                : InteractiveFlag.none,
          ),
          onMapReady: _fitMarkers,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.dinhphu.lovesync',
          ),
          MarkerLayer(
            markers: widget.markers
                .map(
                  (marker) => Marker(
                    point: LatLng(marker.latitude, marker.longitude),
                    width: 52,
                    height: 52,
                    child: _MapPin(marker: marker),
                  ),
                )
                .toList(),
          ),
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      ),
    );
  }

  void _fitMarkers() {
    if (!mounted || widget.markers.isEmpty) return;
    if (widget.markers.length == 1) {
      _controller.move(
        LatLng(widget.markers.first.latitude, widget.markers.first.longitude),
        widget.zoom,
      );
      return;
    }

    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: widget.markers
            .map((marker) => LatLng(marker.latitude, marker.longitude))
            .toList(),
        padding: const EdgeInsets.all(72),
        maxZoom: widget.zoom,
      ),
    );
  }

  bool _positionsChanged(
    List<LocationMapMarker> oldMarkers,
    List<LocationMapMarker> newMarkers,
  ) {
    if (oldMarkers.length != newMarkers.length) return true;
    for (var index = 0; index < oldMarkers.length; index++) {
      final oldMarker = oldMarkers[index];
      final newMarker = newMarkers[index];
      if (oldMarker.latitude != newMarker.latitude ||
          oldMarker.longitude != newMarker.longitude) {
        return true;
      }
    }
    return false;
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.marker});

  final LocationMapMarker marker;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: marker.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Icon(marker.icon, color: Colors.white, size: 25),
    );
  }
}
