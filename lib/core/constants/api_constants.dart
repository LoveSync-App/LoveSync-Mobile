class ApiConstants {
  static const String baseUrl =
      'https://prereformatory-latrina-misleading.ngrok-free.dev/api';
  // 'http://10.0.2.2:8080/api';

  static String get socketOrigin => baseUrl.endsWith('/api')
      ? baseUrl.substring(0, baseUrl.length - 4)
      : baseUrl;
}
