import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmInitializer {
  static bool _appConfigured = false;
  static int? _lastRegisteredUserId;

  static Future<void> init({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final resolvedUserId = userId ?? prefs.getInt('user_id');

    if (!_appConfigured) {
      await _configureAppLevel();
    }

    if (resolvedUserId == null) {
      return;
    }

    if (_lastRegisteredUserId == resolvedUserId) {
      return;
    }

    _lastRegisteredUserId = resolvedUserId;
  }

  static Future<void> _configureAppLevel() async {

    FirebaseMessaging.onMessage.listen((message) {
      print('FCM FOREGROUND');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    });

    _appConfigured = true;
  }

  static void clearUser() {
    _lastRegisteredUserId = null;
  }
}
