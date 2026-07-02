import 'package:flutter_test/flutter_test.dart';
import 'package:lovesync_mobile/core/storage/auth_storage.dart';
import 'package:lovesync_mobile/providers/auth_provider.dart';

void main() {
  test('clears the active session when another device signs in', () async {
    final storage = _MemoryAuthStorage();
    final provider = AuthProvider(storage);

    await provider.login('application-jwt', 'user-id');
    await provider.invalidateSession(
      'Tài khoản đã được đăng nhập trên một thiết bị khác.',
    );

    expect(provider.accessToken, isEmpty);
    expect(provider.userId, isEmpty);
    expect(await storage.readAccessToken(), isNull);
    expect(provider.consumeAuthNotice(), contains('thiết bị khác'));
    expect(provider.consumeAuthNotice(), isNull);
  });
}

class _MemoryAuthStorage implements AuthStorage {
  String? accessToken;
  String? userId;

  @override
  Future<void> deleteAccessToken() async => accessToken = null;

  @override
  Future<void> deleteUserId() async => userId = null;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readUserId() async => userId;

  @override
  Future<void> saveAccessToken(String value) async => accessToken = value;

  @override
  Future<void> saveUserId(String value) async => userId = value;
}
