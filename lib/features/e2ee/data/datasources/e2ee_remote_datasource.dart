import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/e2ee/domain/entities/e2ee_key_bundle.dart';

class E2eeRemoteDatasource {
  const E2eeRemoteDatasource(this.dio);

  final Dio dio;

  Future<E2eeKeyBundle> setupKeys({
    required E2eePublicKey publicKey,
    required EncryptedPrivateKeyBackup encryptedPrivateKey,
  }) async {
    final response = await dio.post(
      '/e2ee/keys',
      data: {
        'publicKey': publicKey.toJson(),
        'encryptedPrivateKey': encryptedPrivateKey.toJson(),
      },
    );
    return E2eeKeyBundle.fromJson(response.data);
  }

  Future<E2eeKeyBundle> getMyKeys() async {
    final response = await dio.get('/e2ee/keys/me');
    return E2eeKeyBundle.fromJson(response.data);
  }

  Future<E2eeKeyBundle> getPartnerKeys() async {
    final response = await dio.get('/e2ee/keys/partner');
    return E2eeKeyBundle.fromJson(response.data);
  }
}
