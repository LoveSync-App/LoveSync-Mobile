import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lovesync_mobile/core/storage/auth_storage.dart';

class AuthProvider extends ChangeNotifier {
  late final AuthStorage _authStorage;
  AuthProvider(this._authStorage);

  String _accessToken = '';
  String _refreshToken = '';
  String _userId = '';
  String? _authNotice;
  bool _isLoadingInit = true;

  String get accessToken => _accessToken;
  String get refreshToken => _refreshToken;
  String get userId => _userId;
  String? get authNotice => _authNotice;
  bool get isLoadingInit => _isLoadingInit;

  Future<void> load() async {
    _isLoadingInit = true;
    notifyListeners();
    _accessToken = await _authStorage.readAccessToken() ?? '';
    _refreshToken = await _authStorage.readRefreshToken() ?? '';
    _userId = await _authStorage.readUserId() ?? '';
    if (_userId.isEmpty && _accessToken.isNotEmpty) {
      _userId = _readUserIdFromToken(_accessToken);
      if (_userId.isNotEmpty) {
        await _authStorage.saveUserId(_userId);
      }
    }
    _isLoadingInit = false;
    notifyListeners();
  }

  Future<void> login(String accessToken, String userId) async {
    return loginWithTokens(
      accessToken: accessToken,
      refreshToken: '',
      userId: userId,
    );
  }

  Future<void> loginWithTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    _authNotice = null;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;
    await _authStorage.saveAccessToken(accessToken);
    if (refreshToken.isNotEmpty) {
      await _authStorage.saveRefreshToken(refreshToken);
    } else {
      await _authStorage.deleteRefreshToken();
    }
    await _authStorage.saveUserId(userId);
    notifyListeners();
  }

  Future<void> updateTokenPair({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    if (_userId.isEmpty) {
      _userId = _readUserIdFromToken(accessToken);
      if (_userId.isNotEmpty) {
        await _authStorage.saveUserId(_userId);
      }
    }
    await _authStorage.saveAccessToken(accessToken);
    await _authStorage.saveRefreshToken(refreshToken);
    notifyListeners();
  }

  Future<void> logout() async {
    _authNotice = null;
    await _clearSession();
  }

  Future<void> handleUnauthorized() {
    return invalidateSession(
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    );
  }

  Future<void> invalidateSession(String message) async {
    if (_accessToken.isEmpty && !_isLoadingInit) return;
    _authNotice = message;
    await _clearSession();
  }

  String? consumeAuthNotice() {
    final notice = _authNotice;
    _authNotice = null;
    return notice;
  }

  Future<void> _clearSession() async {
    _accessToken = '';
    _refreshToken = '';
    _userId = '';
    await _authStorage.deleteAccessToken();
    await _authStorage.deleteRefreshToken();
    await _authStorage.deleteUserId();
    notifyListeners();
  }

  String _readUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(payload);
      final sub = json is Map<String, dynamic> ? json['sub'] : null;
      return sub?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }
}
