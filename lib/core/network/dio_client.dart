import 'package:dio/dio.dart';
import 'package:lovesync_mobile/core/constants/api_constants.dart';

class DioClient {
  final Dio dio;

  static DioClient? _instance;

  static DioClient get instance {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  // _internal là
  DioClient._internal()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          // baseUrl:
          // "https://bilateral-misunderstandingly-veola.ngrok-free.dev/api",
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ) {}
}
