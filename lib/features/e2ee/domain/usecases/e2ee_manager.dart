import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/e2ee/domain/entities/e2ee_key_bundle.dart';
import 'package:lovesync_mobile/features/e2ee/domain/entities/e2ee_message_encryption.dart';
import 'package:lovesync_mobile/features/e2ee/domain/repositories/e2ee_repository.dart';
import 'package:lovesync_mobile/features/e2ee/domain/services/e2ee_crypto_service.dart';

class E2eeManager {
  E2eeManager({
    required E2eeRepository repository,
    E2eeCryptoService? cryptoService,
  }) : _repository = repository,
       _cryptoService = cryptoService ?? E2eeCryptoService();

  final E2eeRepository _repository;
  final E2eeCryptoService _cryptoService;

  E2eeKeyBundle? _partnerKeyCache;

  Future<bool> hasLocalKeys(String userId) async {
    final privateKey = await _repository.readPrivateKeyJson(userId);
    final publicKey = await _repository.readPublicKeyJson(userId);
    final version = await _repository.readKeyVersion(userId);
    return privateKey != null &&
        privateKey.isNotEmpty &&
        publicKey != null &&
        publicKey.isNotEmpty &&
        version != null;
  }

  Future<void> setupNewKeys({
    required String userId,
    required String recoveryCode,
  }) async {
    final generated = _cryptoService.generateAndProtectKeys(
      recoveryCode: recoveryCode,
    );
    final serverBundle = await _repository.setupKeys(
      publicKey: generated.publicKey,
      encryptedPrivateKey: generated.encryptedPrivateKey,
    );
    await _repository.saveLocalKeys(
      userId: userId,
      privateKeyJson: generated.privateKeyJson,
      publicKeyJson: jsonEncode(serverBundle.publicKey.toJson()),
      keyVersion: serverBundle.keyVersion,
    );
  }

  Future<void> recoverKeys({
    required String userId,
    required String recoveryCode,
  }) async {
    final serverBundle = await _repository.getMyKeys();
    final backup = serverBundle.encryptedPrivateKey;
    if (backup == null) {
      throw StateError('Không tìm thấy gói khôi phục khóa.');
    }
    final privateKeyJson = _cryptoService.recoverPrivateKeyJson(
      backup: backup,
      recoveryCode: recoveryCode,
    );
    await _repository.saveLocalKeys(
      userId: userId,
      privateKeyJson: privateKeyJson,
      publicKeyJson: jsonEncode(serverBundle.publicKey.toJson()),
      keyVersion: serverBundle.keyVersion,
    );
  }

  Future<E2eeMessageEncryption?> tryEncryptText({
    required String userId,
    required String plaintext,
  }) async {
    if (plaintext.trim().isEmpty) return null;
    final localKeys = await _readLocalKeys(userId);
    if (localKeys == null) return null;

    final partnerKeys = await _getPartnerKeysOrNull();
    if (partnerKeys == null) return null;

    return _cryptoService.encryptMessage(
      plaintext: plaintext,
      senderKeys: localKeys,
      partnerKeys: partnerKeys,
    );
  }

  Future<E2eeMessageEncryption> encryptText({
    required String userId,
    required String plaintext,
    bool forceRefreshPartnerKey = false,
  }) async {
    final normalizedPlaintext = plaintext.trim();
    if (normalizedPlaintext.isEmpty) {
      throw ArgumentError('Nội dung tin nhắn không được để trống.');
    }

    final localKeys = await _readLocalKeys(userId);
    if (localKeys == null) {
      throw StateError(
        'Thiết bị này chưa có khóa mã hóa. Vui lòng đăng nhập lại và nhập mã khôi phục.',
      );
    }

    if (forceRefreshPartnerKey) {
      _partnerKeyCache = null;
    }
    final partnerKeys = await _getPartnerKeysOrNull();
    if (partnerKeys == null) {
      throw StateError(
        'Người ấy chưa thiết lập khóa mã hóa. Hãy yêu cầu người ấy đăng nhập và tạo mã khôi phục trước.',
      );
    }

    return _cryptoService.encryptMessage(
      plaintext: normalizedPlaintext,
      senderKeys: localKeys,
      partnerKeys: partnerKeys,
    );
  }

  Future<String?> tryDecryptText({
    required String userId,
    required bool isMine,
    required E2eeMessageEncryption? encryption,
  }) async {
    if (encryption == null) return null;
    final privateKeyJson = await _repository.readPrivateKeyJson(userId);
    if (privateKeyJson == null || privateKeyJson.isEmpty) {
      return 'Tin nhắn đã mã hóa. Vui lòng nhập mã khôi phục để đọc.';
    }
    try {
      return _cryptoService.decryptMessage(
        encryption: encryption,
        privateKeyJson: privateKeyJson,
        isMine: isMine,
      );
    } catch (_) {
      return 'Không thể giải mã tin nhắn này.';
    }
  }

  Future<E2eeKeyBundle?> _getPartnerKeysOrNull() async {
    final cached = _partnerKeyCache;
    if (cached != null) return cached;
    try {
      final partnerKeys = await _repository.getPartnerKeys();
      _partnerKeyCache = partnerKeys;
      return partnerKeys;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<LocalE2eeKeys?> _readLocalKeys(String userId) async {
    final privateKeyJson = await _repository.readPrivateKeyJson(userId);
    final publicKeyJson = await _repository.readPublicKeyJson(userId);
    final keyVersion = await _repository.readKeyVersion(userId);
    if (privateKeyJson == null || publicKeyJson == null || keyVersion == null) {
      return null;
    }
    return LocalE2eeKeys(
      publicKey: _cryptoService.publicKeyFromJson(publicKeyJson),
      privateKeyJson: privateKeyJson,
      keyVersion: keyVersion,
    );
  }
}
