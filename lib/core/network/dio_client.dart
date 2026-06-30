import 'package:dio/dio.dart';
import 'package:lovesync_mobile/core/constants/api_constants.dart';
import 'package:lovesync_mobile/core/storage/impl/shared_preferences_auth_storage.dart';

class DioClient {
  final Dio dio;
  final SharedPreferencesAuthStorage authStorage;
  final Future<void> Function()? onUnauthorized;
  bool _isHandlingUnauthorized = false;

  DioClient(this.authStorage, {this.onUnauthorized})
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_isAuthPath(options.path)) {
            return handler.next(options);
          }

          final token = await authStorage.readAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isAuthRequest = _isAuthPath(error.requestOptions.path);

          if (isUnauthorized && !isAuthRequest && !_isHandlingUnauthorized) {
            _isHandlingUnauthorized = true;
            try {
              final callback = onUnauthorized;
              if (callback != null) {
                await callback();
              } else {
                await authStorage.deleteAccessToken();
                await authStorage.deleteUserId();
              }
            } finally {
              _isHandlingUnauthorized = false;
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  static bool _isAuthPath(String path) {
    return path == '/auth/login' ||
        path == '/auth/register' ||
        path == '/auth/forgot-password';
  }
}
