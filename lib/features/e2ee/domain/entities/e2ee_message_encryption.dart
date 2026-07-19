class E2eeMessageEncryption {
  const E2eeMessageEncryption({
    required this.algorithm,
    required this.ciphertext,
    required this.iv,
    required this.authTag,
    required this.senderEncryptedKey,
    required this.recipientEncryptedKey,
    required this.senderKeyVersion,
    required this.recipientKeyVersion,
  });

  final String algorithm;
  final String ciphertext;
  final String iv;
  final String authTag;
  final String senderEncryptedKey;
  final String recipientEncryptedKey;
  final int senderKeyVersion;
  final int recipientKeyVersion;

  factory E2eeMessageEncryption.fromJson(Map<String, dynamic> json) {
    return E2eeMessageEncryption(
      algorithm: (json['algorithm'] ?? 'RSA-OAEP-256+A256GCM').toString(),
      ciphertext: (json['ciphertext'] ?? '').toString(),
      iv: (json['iv'] ?? '').toString(),
      authTag: (json['authTag'] ?? '').toString(),
      senderEncryptedKey: (json['senderEncryptedKey'] ?? '').toString(),
      recipientEncryptedKey: (json['recipientEncryptedKey'] ?? '').toString(),
      senderKeyVersion: _readInt(json['senderKeyVersion']),
      recipientKeyVersion: _readInt(json['recipientKeyVersion']),
    );
  }

  Map<String, dynamic> toJson() => {
    'algorithm': algorithm,
    'ciphertext': ciphertext,
    'iv': iv,
    'authTag': authTag,
    'senderEncryptedKey': senderEncryptedKey,
    'recipientEncryptedKey': recipientEncryptedKey,
    'senderKeyVersion': senderKeyVersion,
    'recipientKeyVersion': recipientKeyVersion,
  };

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
