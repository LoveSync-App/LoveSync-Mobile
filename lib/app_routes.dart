class AppRoutePaths {
  const AppRoutePaths._();

  static const loading = '/loading';

  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authForgotPassword = '/auth/forgot-password';

  static const coupleHome = '/couple';
  static const coupleCode = '/couple/code';
  static const coupleScan = '/couple/scan';
  static const couplePartnerInfo = '/couple/partner-info';
  static const coupleInvitations = '/couple/invitations';

  static const memoryList = '/memories';
  static const memoryCreate = '/memories/create';

  static const calendar = '/calendar';
  static const profile = '/profile';

  static const chat = '/chat';
  static const chatVideoViewer = '/chat/video-viewer';

  static const locationSnapshotPreview = '/locations/snapshot-preview';
  static const locationLiveMap = '/locations/live';
  static const locationSnapshotViewer = '/locations/snapshot';
}

class LegacyAppRoutePaths {
  const LegacyAppRoutePaths._();

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const coupleConfirmation = '/couple/confirmation';
  static const memoryCreate = '/memory/create';
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
