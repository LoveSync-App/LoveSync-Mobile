class E2eePublicKey {
  const E2eePublicKey({
    required this.kty,
    required this.alg,
    required this.n,
    required this.e,
    required this.use,
  });

  final String kty;
  final String alg;
  final String n;
  final String e;
  final String use;

  factory E2eePublicKey.fromJson(Map<String, dynamic> json) {
    return E2eePublicKey(
      kty: (json['kty'] ?? 'RSA').toString(),
      alg: (json['alg'] ?? 'RSA-OAEP-256').toString(),
      n: (json['n'] ?? '').toString(),
      e: (json['e'] ?? 'AQAB').toString(),
      use: (json['use'] ?? 'enc').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'kty': kty,
    'alg': alg,
    'n': n,
    'e': e,
    'use': use,
  };
}

class EncryptedPrivateKeyBackup {
  const EncryptedPrivateKeyBackup({
    required this.algorithm,
    required this.kdf,
    required this.iterations,
    required this.salt,
    required this.iv,
    required this.authTag,
    required this.ciphertext,
  });

  final String algorithm;
  final String kdf;
  final int iterations;
  final String salt;
  final String iv;
  final String authTag;
  final String ciphertext;

  factory EncryptedPrivateKeyBackup.fromJson(Map<String, dynamic> json) {
    return EncryptedPrivateKeyBackup(
      algorithm: (json['algorithm'] ?? 'AES-256-GCM').toString(),
      kdf: (json['kdf'] ?? 'PBKDF2-HMAC-SHA256').toString(),
      iterations: _readInt(json['iterations'], fallback: 600000),
      salt: (json['salt'] ?? '').toString(),
      iv: (json['iv'] ?? '').toString(),
      authTag: (json['authTag'] ?? '').toString(),
      ciphertext: (json['ciphertext'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'algorithm': algorithm,
    'kdf': kdf,
    'iterations': iterations,
    'salt': salt,
    'iv': iv,
    'authTag': authTag,
    'ciphertext': ciphertext,
  };

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class E2eeKeyBundle {
  const E2eeKeyBundle({
    required this.userId,
    required this.keyVersion,
    required this.publicKey,
    this.encryptedPrivateKey,
  });

  final String userId;
  final int keyVersion;
  final E2eePublicKey publicKey;
  final EncryptedPrivateKeyBackup? encryptedPrivateKey;

  factory E2eeKeyBundle.fromJson(dynamic data) {
    final json = _asJson(data);
    final nested = json['data'];
    final root = nested is Map ? _asJson(nested) : json;
    return E2eeKeyBundle(
      userId: (root['userId'] ?? root['id'] ?? root['_id'] ?? '').toString(),
      keyVersion: _readInt(root['keyVersion'], fallback: 1),
      publicKey: E2eePublicKey.fromJson(_asJson(root['publicKey'])),
      encryptedPrivateKey: root['encryptedPrivateKey'] == null
          ? null
          : EncryptedPrivateKeyBackup.fromJson(
              _asJson(root['encryptedPrivateKey']),
            ),
    );
  }

  static Map<String, dynamic> _asJson(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
