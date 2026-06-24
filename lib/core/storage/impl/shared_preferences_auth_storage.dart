import 'package:lovesync_mobile/core/storage/auth_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAuthStorage implements AuthStorage {
  static const String _accessTokenKey = "access_token";
  static const String _userIdKey = "user_id";

  @override
  Future<void> deleteAccessToken() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_accessTokenKey);
  }

  @override
  Future<void> deleteUserId() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_userIdKey);
  }

  @override
  Future<String?> readAccessToken() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(_accessTokenKey);
  }

  @override
  Future<String?> readUserId() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(_userIdKey);
  }

  @override
  Future<void> saveAccessToken(String value) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_accessTokenKey, value);
  }

  @override
  Future<void> saveUserId(String value) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_userIdKey, value);
  }
}
