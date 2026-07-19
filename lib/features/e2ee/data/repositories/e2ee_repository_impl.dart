import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/e2ee/data/datasources/e2ee_local_storage.dart';
import 'package:lovesync_mobile/features/e2ee/data/datasources/e2ee_remote_datasource.dart';
import 'package:lovesync_mobile/features/e2ee/domain/entities/e2ee_key_bundle.dart';
import 'package:lovesync_mobile/features/e2ee/domain/repositories/e2ee_repository.dart';

class E2eeRepositoryImpl implements E2eeRepository {
  E2eeRepositoryImpl({
    required E2eeRemoteDatasource remoteDatasource,
    E2eeLocalStorage? localStorage,
  }) : _remoteDatasource = remoteDatasource,
       _localStorage = localStorage ?? E2eeLocalStorage();

  E2eeRepositoryImpl.fromDio(Dio dio)
    : _remoteDatasource = E2eeRemoteDatasource(dio),
      _localStorage = E2eeLocalStorage();

  final E2eeRemoteDatasource _remoteDatasource;
  final E2eeLocalStorage _localStorage;

  @override
  Future<void> clearLocalKeys(String userId) {
    return _localStorage.clearLocalKeys(userId);
  }

  @override
  Future<E2eeKeyBundle> getMyKeys() {
    return _remoteDatasource.getMyKeys();
  }

  @override
  Future<E2eeKeyBundle> getPartnerKeys() {
    return _remoteDatasource.getPartnerKeys();
  }

  @override
  Future<int?> readKeyVersion(String userId) {
    return _localStorage.readKeyVersion(userId);
  }

  @override
  Future<String?> readPrivateKeyJson(String userId) {
    return _localStorage.readPrivateKeyJson(userId);
  }

  @override
  Future<String?> readPublicKeyJson(String userId) {
    return _localStorage.readPublicKeyJson(userId);
  }

  @override
  Future<void> saveLocalKeys({
    required String userId,
    required String privateKeyJson,
    required String publicKeyJson,
    required int keyVersion,
  }) {
    return _localStorage.saveLocalKeys(
      userId: userId,
      privateKeyJson: privateKeyJson,
      publicKeyJson: publicKeyJson,
      keyVersion: keyVersion,
    );
  }

  @override
  Future<E2eeKeyBundle> setupKeys({
    required E2eePublicKey publicKey,
    required EncryptedPrivateKeyBackup encryptedPrivateKey,
  }) {
    return _remoteDatasource.setupKeys(
      publicKey: publicKey,
      encryptedPrivateKey: encryptedPrivateKey,
    );
  }
}
