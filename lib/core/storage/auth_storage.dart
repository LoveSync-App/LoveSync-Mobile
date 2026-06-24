abstract class AuthStorage {
  Future<void> saveAccessToken(String value);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
  Future<void> saveUserId(String value);
  Future<String?> readUserId();
  Future<void> deleteUserId();
}
