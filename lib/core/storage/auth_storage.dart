abstract class AuthStorage {
  Future<void> saveAccessToken(String value);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}
