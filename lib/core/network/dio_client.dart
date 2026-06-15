import 'package:dio/dio.dart';
import 'package:lovesync_mobile/core/constants/api_constants.dart';
import 'package:lovesync_mobile/core/storage/impl/shared_preferences_auth_storage.dart';

class DioClient {
  final Dio dio;
  final SharedPreferencesAuthStorage authStorage;

  DioClient(this.authStorage)
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
          final isAuthPage =
              options.path == '/login' ||
              options.path == '/register' ||
              options.path == '/forgot-password';

          if (isAuthPage) {
            return handler.next(options);
          }

          final token = await authStorage.readAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
      ),
    );
  }
}
