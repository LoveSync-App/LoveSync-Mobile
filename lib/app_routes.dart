class AppRoutes {
  const AppRoutes._();

  static const loading = '/loading';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const couple = '/couple';
  static const coupleCode = '/couple/code';
  static const coupleScan = '/couple/scan';
  static const couplePartnerInfo = '/couple/partner-info';
  static const coupleConfirmation = '/couple/confirmation';
  static const memoryCreate = '/memory/create';
  static const memories = '/memories';
  static const anniversaries = '/anniversaries';
  static const settings = '/settings';
  static const message = '/message';
  static const locationPreview = '/location/preview';
  static const locationLive = '/location/live';
  static const locationSnapshot = '/location/snapshot';
  static const messageVideoViewer = '/message/video-viewer';
}

class LocationSnapshotRouteExtra {
  const LocationSnapshotRouteExtra({
    required this.latitude,
    required this.longitude,
    this.address,
    this.label,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final String? label;
}
