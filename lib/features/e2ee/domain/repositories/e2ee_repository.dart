import 'package:lovesync_mobile/features/e2ee/domain/entities/e2ee_key_bundle.dart';

abstract class E2eeRepository {
  Future<E2eeKeyBundle> setupKeys({
    required E2eePublicKey publicKey,
    required EncryptedPrivateKeyBackup encryptedPrivateKey,
  });

  Future<E2eeKeyBundle> getMyKeys();

  Future<E2eeKeyBundle> getPartnerKeys();

  Future<void> saveLocalKeys({
    required String userId,
    required String privateKeyJson,
    required String publicKeyJson,
    required int keyVersion,
  });

  Future<String?> readPrivateKeyJson(String userId);

  Future<String?> readPublicKeyJson(String userId);

  Future<int?> readKeyVersion(String userId);

  Future<void> clearLocalKeys(String userId);
}
