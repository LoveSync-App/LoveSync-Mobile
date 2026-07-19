import 'package:dio/dio.dart';
import 'package:lovesync_mobile/core/constants/api_constants.dart';
import 'package:lovesync_mobile/core/storage/impl/shared_preferences_auth_storage.dart';

class DioClient {
  final Dio dio;
  final SharedPreferencesAuthStorage authStorage;
  final Future<void> Function()? onUnauthorized;
  final Future<void> Function({
    required String accessToken,
    required String refreshToken,
  })?
  onTokenRefreshed;
  bool _isHandlingUnauthorized = false;
  Future<_TokenPair?>? _refreshTokenFuture;

  DioClient(this.authStorage, {this.onUnauthorized, this.onTokenRefreshed})
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
            options.extra['accessTokenUsed'] = token;
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshRequest = _isRefreshPath(error.requestOptions.path);
          final isAuthRequest = _isAuthPath(error.requestOptions.path);
          final shouldTryRefresh =
              isUnauthorized &&
              !isAuthRequest &&
              !isRefreshRequest &&
              error.requestOptions.extra['retriedAfterRefresh'] != true;

          if (shouldTryRefresh && await _retryWithLatestToken(error, handler)) {
            return;
          }

          if (shouldTryRefresh) {
            _TokenPair? tokenPair;
            try {
              tokenPair = await _refreshToken();
            } on DioException {
              tokenPair = null;
            }
            if (tokenPair != null) {
              final requestOptions = error.requestOptions;
              requestOptions.extra['retriedAfterRefresh'] = true;
              requestOptions.headers['Authorization'] =
                  'Bearer ${tokenPair.accessToken}';
              try {
                final response = await dio.fetch<dynamic>(requestOptions);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                if (retryError.response?.statusCode != 401) {
                  return handler.next(retryError);
                }
              }
            }
          }

          if (isUnauthorized && !isAuthRequest) {
            await _handleUnauthorizedOnce();
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _retryWithLatestToken(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final tokenUsed = error.requestOptions.extra['accessTokenUsed']?.toString();
    final latestToken = await authStorage.readAccessToken();
    if (latestToken == null ||
        latestToken.isEmpty ||
        latestToken == tokenUsed) {
      return false;
    }

    final requestOptions = error.requestOptions;
    requestOptions.extra['retriedAfterRefresh'] = true;
    requestOptions.extra['accessTokenUsed'] = latestToken;
    requestOptions.headers['Authorization'] = 'Bearer $latestToken';
    try {
      final response = await dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
      return true;
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode != 401) {
        handler.next(retryError);
        return true;
      }
      return false;
    }
  }

  Future<_TokenPair?> _refreshToken() async {
    final activeRefresh = _refreshTokenFuture;
    if (activeRefresh != null) return activeRefresh;

    final future = _requestNewTokenPair();
    _refreshTokenFuture = future;
    try {
      return await future;
    } finally {
      _refreshTokenFuture = null;
    }
  }

  Future<_TokenPair?> _requestNewTokenPair() async {
    final refreshToken = await authStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final response = await dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final root = response.data;
      final data = root is Map ? root['data'] : null;
      if (data is! Map) return null;

      final nextAccessToken = data['accessToken']?.toString() ?? '';
      final nextRefreshToken = data['refreshToken']?.toString() ?? '';
      if (nextAccessToken.isEmpty || nextRefreshToken.isEmpty) return null;

      await authStorage.saveAccessToken(nextAccessToken);
      await authStorage.saveRefreshToken(nextRefreshToken);
      await onTokenRefreshed?.call(
        accessToken: nextAccessToken,
        refreshToken: nextRefreshToken,
      );

      return _TokenPair(
        accessToken: nextAccessToken,
        refreshToken: nextRefreshToken,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> _handleUnauthorizedOnce() async {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;
    try {
      final callback = onUnauthorized;
      if (callback != null) {
        await callback();
      } else {
        await authStorage.deleteAccessToken();
        await authStorage.deleteRefreshToken();
        await authStorage.deleteUserId();
      }
    } finally {
      _isHandlingUnauthorized = false;
    }
  }

  static bool _isAuthPath(String path) {
    return path == '/auth/login' ||
        path == '/auth/google' ||
        path == '/auth/register' ||
        path == '/auth/refresh' ||
        path == '/auth/password/forgot' ||
        path == '/auth/password/reset';
  }

  static bool _isRefreshPath(String path) {
    return path == '/auth/refresh';
  }
}

class _TokenPair {
  const _TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}
