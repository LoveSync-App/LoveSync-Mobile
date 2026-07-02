import 'package:flutter_test/flutter_test.dart';
import 'package:lovesync_mobile/features/auth/data/models/login_response_model.dart';

void main() {
  test('parses the shared password and Google login response', () {
    final response = LoginResponseModel.fromJson({
      'user': {
        'id': 'user-id',
        'email': 'user@example.com',
        'name': 'Love Sync',
        'avatar': 'https://example.com/avatar.jpg',
        'authProviders': ['password', 'google.com'],
      },
      'loginProvider': 'google.com',
      'accessToken': 'application-jwt',
    });

    expect(response.accessToken, 'application-jwt');
    expect(response.user.id, 'user-id');
    expect(response.user.email, 'user@example.com');
    expect(response.user.name, 'Love Sync');
  });
}
