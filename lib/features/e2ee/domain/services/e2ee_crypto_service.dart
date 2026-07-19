import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:lovesync_mobile/features/e2ee/domain/entities/e2ee_key_bundle.dart';
import 'package:lovesync_mobile/features/e2ee/domain/entities/e2ee_message_encryption.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/random/fortuna_random.dart';

class GeneratedE2eeKeys {
  const GeneratedE2eeKeys({
    required this.publicKey,
    required this.privateKeyJson,
    required this.encryptedPrivateKey,
  });

  final E2eePublicKey publicKey;
  final String privateKeyJson;
  final EncryptedPrivateKeyBackup encryptedPrivateKey;
}

class LocalE2eeKeys {
  const LocalE2eeKeys({
    required this.publicKey,
    required this.privateKeyJson,
    required this.keyVersion,
  });

  final E2eePublicKey publicKey;
  final String privateKeyJson;
  final int keyVersion;
}

class E2eeCryptoService {
  E2eeCryptoService({Random? random}) : _random = random ?? Random.secure();

  static const int recommendedIterations = 600000;
  static const int _aesKeyBytes = 32;
  static const int _aesGcmIvBytes = 12;
  static const int _aesGcmTagBytes = 16;

  final Random _random;

  GeneratedE2eeKeys generateAndProtectKeys({
    required String recoveryCode,
    int iterations = recommendedIterations,
  }) {
    _validateRecoveryCode(recoveryCode);

    final keyPair = _generateRsaKeyPair();
    final publicKey = keyPair.publicKey;
    final privateKey = keyPair.privateKey;
    final privateKeyJson = _privateKeyToJson(privateKey);

    final salt = randomBytes(16);
    final iv = randomBytes(_aesGcmIvBytes);
    final derivedKey = _deriveRecoveryKey(
      recoveryCode: recoveryCode,
      salt: salt,
      iterations: iterations,
    );
    final encrypted = _aesGcmEncrypt(
      key: derivedKey,
      iv: iv,
      plaintext: Uint8List.fromList(utf8.encode(privateKeyJson)),
    );

    return GeneratedE2eeKeys(
      publicKey: _publicKeyToJwk(publicKey),
      privateKeyJson: privateKeyJson,
      encryptedPrivateKey: EncryptedPrivateKeyBackup(
        algorithm: 'AES-256-GCM',
        kdf: 'PBKDF2-HMAC-SHA256',
        iterations: iterations,
        salt: base64Encode(salt),
        iv: base64Encode(iv),
        authTag: base64Encode(encrypted.authTag),
        ciphertext: base64Encode(encrypted.ciphertext),
      ),
    );
  }

  String recoverPrivateKeyJson({
    required EncryptedPrivateKeyBackup backup,
    required String recoveryCode,
  }) {
    _validateRecoveryCode(recoveryCode);
    final key = _deriveRecoveryKey(
      recoveryCode: recoveryCode,
      salt: base64Decode(backup.salt),
      iterations: backup.iterations,
    );
    final plaintext = _aesGcmDecrypt(
      key: key,
      iv: base64Decode(backup.iv),
      ciphertext: base64Decode(backup.ciphertext),
      authTag: base64Decode(backup.authTag),
    );
    return utf8.decode(plaintext);
  }

  E2eeMessageEncryption encryptMessage({
    required String plaintext,
    required LocalE2eeKeys senderKeys,
    required E2eeKeyBundle partnerKeys,
  }) {
    final messageKey = randomBytes(_aesKeyBytes);
    final iv = randomBytes(_aesGcmIvBytes);
    final encryptedContent = _aesGcmEncrypt(
      key: messageKey,
      iv: iv,
      plaintext: Uint8List.fromList(utf8.encode(plaintext)),
    );

    final senderPublicKey = publicKeyFromJwk(senderKeys.publicKey);
    final recipientPublicKey = publicKeyFromJwk(partnerKeys.publicKey);

    return E2eeMessageEncryption(
      algorithm: 'RSA-OAEP-256+A256GCM',
      ciphertext: base64Encode(encryptedContent.ciphertext),
      iv: base64Encode(iv),
      authTag: base64Encode(encryptedContent.authTag),
      senderEncryptedKey: base64Encode(
        _rsaOaepEncrypt(senderPublicKey, messageKey),
      ),
      recipientEncryptedKey: base64Encode(
        _rsaOaepEncrypt(recipientPublicKey, messageKey),
      ),
      senderKeyVersion: senderKeys.keyVersion,
      recipientKeyVersion: partnerKeys.keyVersion,
    );
  }

  String decryptMessage({
    required E2eeMessageEncryption encryption,
    required String privateKeyJson,
    required bool isMine,
  }) {
    final privateKey = privateKeyFromJson(privateKeyJson);
    final encryptedMessageKey = isMine
        ? encryption.senderEncryptedKey
        : encryption.recipientEncryptedKey;
    final messageKey = _rsaOaepDecrypt(
      privateKey,
      base64Decode(encryptedMessageKey),
    );
    final plaintext = _aesGcmDecrypt(
      key: messageKey,
      iv: base64Decode(encryption.iv),
      ciphertext: base64Decode(encryption.ciphertext),
      authTag: base64Decode(encryption.authTag),
    );
    return utf8.decode(plaintext);
  }

  RSAPublicKey publicKeyFromJwk(E2eePublicKey jwk) {
    return RSAPublicKey(
      _decodeBase64UrlBigInt(jwk.n),
      _decodeBase64UrlBigInt(jwk.e),
    );
  }

  RSAPrivateKey privateKeyFromJson(String value) {
    final json = jsonDecode(value);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid private key JSON');
    }
    return RSAPrivateKey(
      _decodeBase64UrlBigInt(json['n'].toString()),
      _decodeBase64UrlBigInt(json['d'].toString()),
      _decodeBase64UrlBigInt(json['p'].toString()),
      _decodeBase64UrlBigInt(json['q'].toString()),
    );
  }

  E2eePublicKey publicKeyFromJson(String value) {
    final json = jsonDecode(value);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid public key JSON');
    }
    return E2eePublicKey.fromJson(json);
  }

  Uint8List randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRsaKeyPair() {
    final generator = RSAKeyGenerator();
    generator.init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
        _secureRandom(),
      ),
    );
    final pair = generator.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey,
      pair.privateKey,
    );
  }

  SecureRandom _secureRandom() {
    final secureRandom = FortunaRandom();
    secureRandom.seed(KeyParameter(randomBytes(32)));
    return secureRandom;
  }

  Uint8List _deriveRecoveryKey({
    required String recoveryCode,
    required Uint8List salt,
    required int iterations,
  }) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(salt, iterations, _aesKeyBytes));
    return derivator.process(Uint8List.fromList(utf8.encode(recoveryCode)));
  }

  _AesGcmResult _aesGcmEncrypt({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List plaintext,
  }) {
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      true,
      AEADParameters(KeyParameter(key), _aesGcmTagBytes * 8, iv, Uint8List(0)),
    );
    final output = Uint8List(plaintext.length + _aesGcmTagBytes);
    final written = cipher.processBytes(
      plaintext,
      0,
      plaintext.length,
      output,
      0,
    );
    final total = written + cipher.doFinal(output, written);
    final fullOutput = output.sublist(0, total);
    return _AesGcmResult(
      ciphertext: Uint8List.fromList(
        fullOutput.sublist(0, fullOutput.length - _aesGcmTagBytes),
      ),
      authTag: Uint8List.fromList(
        fullOutput.sublist(fullOutput.length - _aesGcmTagBytes),
      ),
    );
  }

  Uint8List _aesGcmDecrypt({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List ciphertext,
    required Uint8List authTag,
  }) {
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      false,
      AEADParameters(KeyParameter(key), _aesGcmTagBytes * 8, iv, Uint8List(0)),
    );
    final input = Uint8List.fromList([...ciphertext, ...authTag]);
    final output = Uint8List(input.length);
    final written = cipher.processBytes(input, 0, input.length, output, 0);
    final total = written + cipher.doFinal(output, written);
    return Uint8List.fromList(output.sublist(0, total));
  }

  Uint8List _rsaOaepEncrypt(RSAPublicKey publicKey, Uint8List plaintext) {
    final cipher = OAEPEncoding.withSHA256(RSAEngine());
    cipher.init(
      true,
      ParametersWithRandom(
        PublicKeyParameter<RSAPublicKey>(publicKey),
        _secureRandom(),
      ),
    );
    return cipher.process(plaintext);
  }

  Uint8List _rsaOaepDecrypt(RSAPrivateKey privateKey, Uint8List ciphertext) {
    final cipher = OAEPEncoding.withSHA256(RSAEngine());
    cipher.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return cipher.process(ciphertext);
  }

  E2eePublicKey _publicKeyToJwk(RSAPublicKey publicKey) {
    return E2eePublicKey(
      kty: 'RSA',
      alg: 'RSA-OAEP-256',
      n: _encodeBase64UrlBigInt(publicKey.modulus!),
      e: _encodeBase64UrlBigInt(publicKey.publicExponent!),
      use: 'enc',
    );
  }

  String _privateKeyToJson(RSAPrivateKey privateKey) {
    return jsonEncode({
      'kty': 'RSA',
      'alg': 'RSA-OAEP-256',
      'n': _encodeBase64UrlBigInt(privateKey.modulus!),
      'e': _encodeBase64UrlBigInt(privateKey.publicExponent!),
      'd': _encodeBase64UrlBigInt(privateKey.privateExponent!),
      'p': _encodeBase64UrlBigInt(privateKey.p!),
      'q': _encodeBase64UrlBigInt(privateKey.q!),
      'use': 'enc',
    });
  }

  String _encodeBase64UrlBigInt(BigInt value) {
    return base64UrlEncode(_bigIntToBytes(value)).replaceAll('=', '');
  }

  BigInt _decodeBase64UrlBigInt(String value) {
    final bytes = base64Url.decode(base64Url.normalize(value));
    return _bytesToBigInt(bytes);
  }

  Uint8List _bigIntToBytes(BigInt value) {
    var hex = value.toRadixString(16);
    if (hex.length.isOdd) hex = '0$hex';
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    while (bytes.length > 1 && bytes.first == 0) {
      bytes.removeAt(0);
    }
    return Uint8List.fromList(bytes);
  }

  BigInt _bytesToBigInt(List<int> bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }

  void _validateRecoveryCode(String recoveryCode) {
    if (!RegExp(r'^\d{6}$').hasMatch(recoveryCode)) {
      throw const FormatException(
        'Recovery code must contain exactly 6 digits',
      );
    }
  }
}

class _AesGcmResult {
  const _AesGcmResult({required this.ciphertext, required this.authTag});

  final Uint8List ciphertext;
  final Uint8List authTag;
}
