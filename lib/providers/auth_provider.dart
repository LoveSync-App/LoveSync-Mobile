import 'package:flutter/material.dart';
import 'package:lovesync_mobile/core/storage/auth_storage.dart';

class AuthProvider extends ChangeNotifier {
  late final AuthStorage _authStorage;
  AuthProvider(this._authStorage);

  String _accessToken = '';
  bool _isLoadingInit = true;

  String get accessToken => _accessToken;
  bool get isLoadingInit => _isLoadingInit;

  Future<void> load() async {
    _isLoadingInit = true;
    notifyListeners();
    _accessToken = await _authStorage.readAccessToken() ?? '';
    _isLoadingInit = false;
    notifyListeners();
  }

  Future<void> login(String value) async {
    _accessToken = value;
    await _authStorage.saveAccessToken(value);
    notifyListeners();
  }

  Future<void> logout() async {
    _accessToken = '';
    await _authStorage.deleteAccessToken();
    notifyListeners();
  }
}
