import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class E2eeLocalStorage {
  E2eeLocalStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const _privateKeyPrefix = 'e2ee_private_key_json_';
  static const _publicKeyPrefix = 'e2ee_public_key_json_';
  static const _keyVersionPrefix = 'e2ee_key_version_';

  Future<void> saveLocalKeys({
    required String userId,
    required String privateKeyJson,
    required String publicKeyJson,
    required int keyVersion,
  }) async {
    await _secureStorage.write(
      key: '$_privateKeyPrefix$userId',
      value: privateKeyJson,
    );
    await _secureStorage.write(
      key: '$_publicKeyPrefix$userId',
      value: publicKeyJson,
    );
    await _secureStorage.write(
      key: '$_keyVersionPrefix$userId',
      value: keyVersion.toString(),
    );
  }

  Future<String?> readPrivateKeyJson(String userId) {
    return _secureStorage.read(key: '$_privateKeyPrefix$userId');
  }

  Future<String?> readPublicKeyJson(String userId) {
    return _secureStorage.read(key: '$_publicKeyPrefix$userId');
  }

  Future<int?> readKeyVersion(String userId) async {
    final raw = await _secureStorage.read(key: '$_keyVersionPrefix$userId');
    return int.tryParse(raw ?? '');
  }

  Future<void> clearLocalKeys(String userId) async {
    await _secureStorage.delete(key: '$_privateKeyPrefix$userId');
    await _secureStorage.delete(key: '$_publicKeyPrefix$userId');
    await _secureStorage.delete(key: '$_keyVersionPrefix$userId');
  }
}
